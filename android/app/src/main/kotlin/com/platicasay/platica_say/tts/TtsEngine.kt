package com.platicasay.platica_say.tts

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

class TtsEngine(context: Context) : TextToSpeech.OnInitListener {

    private var tts: TextToSpeech? = TextToSpeech(context, this)
    private var ready = false

    override fun onInit(status: Int) {
        ready = status == TextToSpeech.SUCCESS
    }

    fun speak(text: String, lang: String? = null) {
        if (!ready || text.isBlank()) return
        
        if (!lang.isNullOrBlank()) {
            val loc = if (lang.contains("-")) {
                val parts = lang.split("-")
                Locale(parts[0], parts[1])
            } else {
                Locale(lang)
            }
            try {
                if (tts?.isLanguageAvailable(loc) ?: -1 >= TextToSpeech.LANG_AVAILABLE) {
                    tts?.language = loc
                }
            } catch (_: Exception) {}
        }
        
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "platica_tts")
    }

    fun stop() {
        tts?.stop()
    }

    fun shutdown() {
        tts?.shutdown()
        tts = null
    }
}
