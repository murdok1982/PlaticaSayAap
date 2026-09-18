package com.platicasay.platica_say.overlay

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import com.platicasay.platica_say.R

class TranslationOverlayService : Service() {

    companion object {
        const val ACTION_PUSH = "com.platicasay.OVERLAY_PUSH"

        fun start(context: Context) {
            context.startService(Intent(context, TranslationOverlayService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TranslationOverlayService::class.java))
        }
    }

    private var overlayView: View? = null
    private lateinit var windowManager: WindowManager

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_PUSH) return
            val source = intent.getStringExtra("sourceText") ?: return
            val translated = intent.getStringExtra("translatedText") ?: return
            updateText(source, translated)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, IntentFilter(ACTION_PUSH), RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, IntentFilter(ACTION_PUSH))
        }
        showOverlay()
    }

    private fun showOverlay() {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP
            y = 120
        }

        val view = LayoutInflater.from(this).inflate(R.layout.overlay_translation, null)
        view.findViewById<TextView>(R.id.overlay_text).text =
            "Platica-Say — traduciendo llamada..."
        overlayView = view
        windowManager.addView(view, params)
    }

    private fun updateText(source: String, translated: String) {
        overlayView?.findViewById<TextView>(R.id.overlay_text)?.text =
            "$source\n→ $translated"
    }

    override fun onDestroy() {
        overlayView?.let { windowManager.removeView(it) }
        overlayView = null
        unregisterReceiver(receiver)
        super.onDestroy()
    }
}
