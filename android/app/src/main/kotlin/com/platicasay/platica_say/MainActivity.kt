package com.platicasay.platica_say

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import com.platicasay.platica_say.capture.CallCaptureService
import com.platicasay.platica_say.overlay.TranslationOverlayService
import com.platicasay.platica_say.tts.TtsEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingProjectionResult: MethodChannel.Result? = null
    private var ttsEngine: TtsEngine? = null

    companion object {
        const val REQUEST_MEDIA_PROJECTION = 1001
        var pcmEventSink: EventChannel.EventSink? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.platicasay/audio/pcm"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                pcmEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                pcmEventSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.platicasay/audio/methods"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCapture" -> {
                    val source = call.argument<String>("source") ?: "mic"
                    if (source == "call") {
                        pendingProjectionResult = result
                        val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE)
                            as MediaProjectionManager
                        startActivityForResult(
                            mpm.createScreenCaptureIntent(),
                            REQUEST_MEDIA_PROJECTION
                        )
                    } else {
                        CallCaptureService.startMic(this)
                        result.success(true)
                    }
                }
                "stopCapture" -> {
                    CallCaptureService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.platicasay/overlay"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" ->
                    result.success(Settings.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    startActivity(Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    ))
                    result.success(null)
                }
                "startCallOverlay" -> {
                    if (Settings.canDrawOverlays(this)) {
                        TranslationOverlayService.start(this)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopCallOverlay" -> {
                    TranslationOverlayService.stop(this)
                    result.success(null)
                }
                "pushTranslation" -> {
                    val intent = Intent(TranslationOverlayService.ACTION_PUSH).apply {
                        setPackage(packageName)
                        putExtra("sourceText", call.argument<String>("sourceText"))
                        putExtra("translatedText", call.argument<String>("translatedText"))
                        putExtra("sourceLang", call.argument<String>("sourceLang"))
                        putExtra("targetLang", call.argument<String>("targetLang"))
                    }
                    sendBroadcast(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.platicasay/tts"
        ).setMethodCallHandler { call, result ->
            if (ttsEngine == null) ttsEngine = TtsEngine(this)
            when (call.method) {
                "loadVoice" -> result.success(null)
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    val locale = call.argument<String>("locale") ?: call.argument<String>("voiceId")
                    ttsEngine?.speak(text, locale)
                    result.success(null)
                }
                "stop" -> {
                    ttsEngine?.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                CallCaptureService.startCallAudio(this, resultCode, data)
                pendingProjectionResult?.success(true)
            } else {
                pendingProjectionResult?.success(false)
            }
            pendingProjectionResult = null
        }
    }
}
