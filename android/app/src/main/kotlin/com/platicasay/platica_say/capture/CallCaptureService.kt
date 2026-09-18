package com.platicasay.platica_say.capture

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.NoiseSuppressor
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

class CallCaptureService : Service() {

    companion object {
        private const val CHANNEL_ID = "platica_capture"
        private const val NOTIFICATION_ID = 42
        private const val SAMPLE_RATE = 16000

        private var instance: CallCaptureService? = null

        fun startMic(context: Context) {
            val intent = Intent(context, CallCaptureService::class.java)
                .putExtra("mode", "mic")
            context.startForegroundService(intent)
        }

        fun startCallAudio(context: Context, resultCode: Int, data: Intent) {
            val intent = Intent(context, CallCaptureService::class.java)
                .putExtra("mode", "call")
                .putExtra("resultCode", resultCode)
                .putExtra("data", data)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CallCaptureService::class.java))
        }
    }

    @Volatile
    private var capturing = false
    private var projection: MediaProjection? = null
    private var aec: AcousticEchoCanceler? = null
    private var noiseSuppressor: NoiseSuppressor? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        startForegroundWithNotification()

        when (intent?.getStringExtra("mode")) {
            "mic" -> startMicCapture()
            "call" -> {
                val resultCode = intent.getIntExtra("resultCode", 0)
                @Suppress("DEPRECATION")
                val data: Intent? = intent.getParcelableExtra("data")
                if (data != null) startCallCapture(resultCode, data)
            }
        }
        return START_STICKY
    }

    private fun startForegroundWithNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Captura de audio", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val openIntent = PendingIntent.getActivity(
            this, 0, packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )
        val notification: Notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION") Notification.Builder(this)
        }
            .setContentTitle("Platica-Say activo")
            .setContentText("Traduciendo en tiempo real")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(openIntent)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun startMicCapture() {
        capturing = true
        thread {
            val record = buildMicRecord() ?: return@thread
            enableAudioEffects(record)
            record.startRecording()
            pumpPcm(record)
        }
    }

    private fun startCallCapture(resultCode: Int, data: Intent) {
        val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        projection = mpm.getMediaProjection(resultCode, data)
        capturing = true
        thread {
            val record = buildPlaybackRecord() ?: buildMicRecord() ?: return@thread
            enableAudioEffects(record)
            record.startRecording()
            pumpPcm(record)
        }
    }

    private fun enableAudioEffects(record: AudioRecord) {
        try {
            if (AcousticEchoCanceler.isAvailable()) {
                aec = AcousticEchoCanceler.create(record.audioSessionId)?.apply {
                    enabled = true
                }
            }
            if (NoiseSuppressor.isAvailable()) {
                noiseSuppressor = NoiseSuppressor.create(record.audioSessionId)?.apply {
                    enabled = true
                }
            }
        } catch (_: Exception) {}
    }

    @SuppressLint("MissingPermission")
    private fun buildMicRecord(): AudioRecord? {
        val minBuf = AudioRecord.getMinBufferSize(
            SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
        )
        return try {
            AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minBuf * 2
            )
        } catch (e: Exception) {
            null
        }
    }

    @SuppressLint("MissingPermission")
    private fun buildPlaybackRecord(): AudioRecord? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val proj = projection ?: return null
        val config = AudioPlaybackCaptureConfiguration.Builder(proj)
            .addMatchingUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .build()
        val format = AudioFormat.Builder()
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .build()
        val minBuf = AudioRecord.getMinBufferSize(
            SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
        )
        return try {
            AudioRecord.Builder()
                .setAudioPlaybackCaptureConfig(config)
                .setAudioFormat(format)
                .setBufferSizeInBytes(minBuf * 2)
                .build()
        } catch (e: Exception) {
            null
        }
    }

    private fun pumpPcm(record: AudioRecord) {
        val shortBuf = ShortArray(1024)
        val out = ByteArrayOutputStream(1024 * 4)
        try {
            while (capturing) {
                val read = record.read(shortBuf, 0, shortBuf.size)
                if (read <= 0) continue
                out.reset()
                for (i in 0 until read) {
                    val f = (shortBuf[i] / 32768f).coerceIn(-1f, 1f)
                    val bits = java.lang.Float.floatToIntBits(f)
                    out.write(bits and 0xFF)
                    out.write((bits shr 8) and 0xFF)
                    out.write((bits shr 16) and 0xFF)
                    out.write((bits shr 24) and 0xFF)
                }
                MainActivityPcmBridge.emit(out.toByteArray())
            }
        } finally {
            try {
                record.stop()
                record.release()
            } catch (_: Exception) {}
            try {
                aec?.release()
                noiseSuppressor?.release()
            } catch (_: Exception) {}
        }
    }

    override fun onDestroy() {
        capturing = false
        projection?.stop()
        projection = null
        try {
            aec?.release()
            noiseSuppressor?.release()
        } catch (_: Exception) {}
        instance = null
        super.onDestroy()
    }
}

object MainActivityPcmBridge {
    fun emit(bytes: ByteArray) {
        com.platicasay.platica_say.MainActivity.pcmEventSink?.success(bytes)
    }
}
