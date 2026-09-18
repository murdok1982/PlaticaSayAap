# Platica-Say — Tweak iOS (jailbreak)

> **Requisito**: dispositivo iOS con jailbreak (palera1n / Dopamine).
> Este tweak NO funciona en iOS estándar ni se distribuye por App Store.
> Distribución: repositorio propio en Sileo/Zebra (formato `.deb`).

## Qué hace

- Hook en `CoreAudio`/`AudioUnit` para capturar el audio de salida de apps de llamadas (WhatsApp, Telegram, FaceTime).
- Hook en `AVCaptureSession` para el micrófono local.
- Envía PCM a la app Platica-Say vía socket local (`127.0.0.1:48123`).
- Ventana flotante (UIWindow sobre `UIWindowLevelAlert`) que muestra la traducción sobre cualquier app.

## Compilación

Requiere [Theos](https://theos.dev):

```bash
cd ios_jailbreak
make package   # genera com.platicasay.tweak_x.y.z_iphoneos-arm64.deb
```

## Estructura

- `Tweak.x` — hooks de captura de audio
- `OverlayWindow.x` — ventana flotante con la traducción
- `control` — metadatos del paquete Debian
- `PlaticaSayTweak.plist` — apps objetivo (filter)
- `Makefile` — build con Theos

## Flujo

```
App de llamada → AudioUnit (hook) → PCM 16 kHz mono
                                    ↓
                        socket local → app Platica-Say
                                    ↓
              Whisper (STT) → LLM traductor → TTS + OverlayWindow
```

## Aviso legal

El uso de jailbreak y la grabación de llamadas están sujetos a la legislación
local. El usuario es responsable de obtener el consentimiento de los
participantes de la conversación según su jurisdicción.
