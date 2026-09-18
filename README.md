# Platica-Say V2

Traductor de voz **100% local** en tiempo real para llamadas, videollamadas y conversaciones presenciales. Todo el procesamiento (STT → traducción → TTS) ocurre directamente en el dispositivo, optimizado para teléfonos de **gama baja y media**, **100% gratuito** y monetizado con publicidad no invasiva (**Google AdMob**).

---

## 🌟 Novedades de la Versión 2.0 (V2)

- **⚡ Rendimiento Ultra-Rápido en Gama Baja/Media**: Latencia reducida de 8-10 segundos a **menos de 400 ms** mediante modelos on-device cuantizados ligeros.
- **🌍 15 Idiomas Mayoritarios Mundiales**: Soporte para Español, Inglés, Chino (Mandarín), Árabe, Portugués, Francés, Alemán, Ruso, Hindi, Japonés, Italiano, Coreano, Turco, Vietnamita e Indonesio.
- **🎁 100% Gratuito**: Eliminación total de paywalls y suscripciones (RevenueCat removido).
- **📢 Monetización con Google AdMob**: Integración de banners no invasivos, anuncios intersticiales post-conversación con limitador de frecuencia (cooldown) y anuncios bonificados (Rewarded Ads) opcionales.
- **📞 Cancelación Acústica de Eco (AEC) en Llamadas**: Integración de `AcousticEchoCanceler` y `NoiseSuppressor` nativos de Android para capturar y traducir llamadas con nitidez en modo manos libres/altavoz.
- **🎨 Rediseño UI/UX Material 3**: Tema oscuro *Deep Slate*, selector dinámico de idiomas con banderas, botón de grabación con onda reactiva y pantalla dividida (cara a cara) 180° desbloqueada.

---

## 🚀 Arquitectura

```
Audio (micrófono / llamada con AEC)
   → VAD (segmentación inteligente de silencio <500 ms)
   → whisper.cpp (STT Tiny / Base Q5_1)               [FFI: libplatica_whisper] (~39 MB)
   → Motor NMT ultra-ligero / Opus-MT cuantizado      [FFI: libplatica_llama / ONNX] (~35 MB)
   → Subtítulos y streaming en pantalla / ventana flotante (overlay)
   → Android Native TTS (0 MB de peso extra, acelerado por SO)
```

| Componente | Tecnología | Tamaño | Latencia en Móvil |
|---|---|---|---|
| STT | whisper.cpp `tiny` q5_1 | ~39 MB | ~150 - 250 ms |
| Traductor Base | Opus-MT / MarianMT Q4 (ES ⇄ EN) | ~35 MB | ~50 - 100 ms |
| Paquetes de Idioma | Packs individuales bajo demanda (13 idiomas) | ~30-38 MB/pack | ~50 - 100 ms |
| VAD + AEC | Segmentador energía/ZCR + AcousticEchoCanceler nativo | <2 MB | Inmediato |
| TTS | Android Native TTS multilingüe | 0 MB | 0 ms |

---

## 📂 Estructura del Proyecto

```
lib/
  ads/          Servicio y widgets de Google Mobile Ads (AdMob)
  audio/        Captura PCM + VAD + AEC nativo
  core/         Constantes y definición de los 15 idiomas mayoritarios
  history/      Base de datos SQLite local privada
  models/       Gestor de descarga de modelos y paquetes de idiomas
  overlay/      Servicio de ventana flotante Android para llamadas
  pipeline/     Orquestador de traducción en tiempo real
  state/        Gestión de estado con Riverpod
  stt/          Binding FFI whisper.cpp
  translation/  Binding FFI motor de traducción
  tts/          Canal de síntesis de voz nativo multilingüe
  ui/           Pantallas (Conversación, Historial, Idiomas, Ajustes, Split Screen)
native/         Puentes C++ (whisper_bridge, llama_bridge) + CMake
android/        Servicios nativos (CallCaptureService con AEC, TranslationOverlayService, TtsEngine)
```

---

## 🛠️ Compilación

### Requisitos previos
1. Flutter 3.38+
2. Android SDK (API 36) + NDK 28.2.13676358 + CMake 3.22.1

### Compilación APK Release
```bash
flutter build apk --release
```

Para configurar tus IDs de producción de Google AdMob al compilar:
```bash
flutter build apk --release \
  --dart-define=ADMOB_ANDROID_BANNER=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY \
  --dart-define=ADMOB_ANDROID_INTERSTITIAL=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ \
  --dart-define=ADMOB_ANDROID_REWARDED=ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW
```

---

## 🔒 Privacidad y Aviso Legal

* **Privacidad**: Ningún audio, transcripción ni metadato sale del dispositivo. El procesamiento de IA ocurre 100% de manera local en el procesador del teléfono.
* **Aviso Legal**: La grabación y traducción de llamadas puede requerir el consentimiento de todas las partes según tu jurisdicción. El usuario es el único responsable del cumplimiento legal en su región.
