<div align="center">

# 🗣️ Platica-Say

### Traductor de voz en tiempo real — 100% local, 100% privado

Habla en tu idioma. La otra persona escucha en el suyo.
Sin internet. Sin servidores. Sin que tu voz salga del teléfono.

[![Descargar APK](https://img.shields.io/badge/📦_Descargar-APK_v0.1.0-4F8CFF?style=for-the-badge)](https://github.com/murdok1982/PlaticaSayAap/releases/latest/download/Platica-Say-v0.1.0.apk)
[![Release](https://img.shields.io/github/v/release/murdok1982/PlaticaSayAap?style=for-the-badge)](https://github.com/murdok1982/PlaticaSayAap/releases)
![Offline](https://img.shields.io/badge/Offline-100%25-22c55e?style=for-the-badge)

</div>

---

## ✨ ¿Qué hace?

| Modo | Descripción |
|---|---|
| 📞 **Llamadas** | Traduce llamadas y videollamadas en vivo con una ventana flotante sobre WhatsApp, Meet, etc. |
| 🎙️ **Presencial** | Pon el móvil en medio de la mesa: cada persona habla en su idioma y escucha la traducción |
| 📱 **Pantalla dividida** | El texto se invierte para que la persona de enfrente lo lea en su idioma |

Todo el procesamiento ocurre **en tu dispositivo**: reconocimiento de voz → traducción con IA → voz sintetizada. Después de la descarga inicial, **no necesita internet nunca más**.

## 🌍 12 idiomas

🇪🇸 Español · 🇬🇧 English · 🇧🇷 Português · 🇫🇷 Français · 🇩🇪 Deutsch · 🇮🇹 Italiano · 🇨🇳 中文 · 🇯🇵 日本語 · 🇰🇷 한국어 · 🇸🇦 العربية · 🇷🇺 Русский · 🇮🇳 हिन्दी

La app **detecta automáticamente** qué idioma está hablando cada persona.

---

## 📥 Descarga e instalación

### 1. Descarga el APK

👉 **[Descargar Platica-Say v0.1.0 (55 MB)](https://github.com/murdok1982/PlaticaSayAap/releases/latest/download/Platica-Say-v0.1.0.apk)**

### 2. Permite la instalación

Android bloquea apps fuera de Play Store por defecto:

1. Abre el archivo `.apk` descargado (desde el navegador o el gestor de archivos)
2. Android te avisará → toca **Ajustes** → activa **"Permitir desde esta fuente"**
3. Vuelve atrás y toca **Instalar**

> 💡 Es seguro: la app no usa internet para funcionar (solo descarga los modelos de IA la primera vez).

### 3. Primera ejecución (importante ⚡)

Al abrirla por primera vez, la app descarga los modelos de IA:

- 📦 **~2.1 GB** (reconocedor de voz + modelo traductor)
- 📶 Hazlo **con WiFi** y batería suficiente (10-30 min)
- ✅ Solo ocurre **una vez** — después funciona totalmente offline

### 📋 Requisitos

- Android **8.0** o superior
- Procesador **64 bits** (cualquier gama media actual)
- **~3 GB** de espacio libre
- 4+ GB de RAM recomendados

---

## 🚀 Cómo usarla

### 🎙️ Conversación presencial

1. Abre la app y selecciona **Presencial**
2. (Opcional) elige los idiomas, o déjalo en automático
3. Pulsa **"Iniciar traducción"** y habla con naturalidad
4. La traducción aparece en pantalla al instante (< 1 s) y suena en voz alta

### 📞 Traducir una llamada

1. Selecciona el modo **Llamada** *(función Premium)*
2. La primera vez te pedirá dos permisos:
   - **Mostrar sobre otras apps** (para la ventana flotante)
   - **Captura de audio** (para escuchar la llamada)
3. Inicia tu llamada en WhatsApp, Meet, etc. — la ventana flotante mostrará la traducción en vivo

> ⚠️ Algunas apps pueden bloquear la captura de audio. En ese caso usa el altavoz: la app escuchará por el micrófono.
> ⚖️ **Aviso legal**: grabar/traducir llamadas puede requerir el consentimiento de todas las partes según tu país.

### 📱 Pantalla dividida (cara a cara)

Toca el icono 🔄 arriba a la derecha: la mitad superior de la pantalla se invierte para que la persona de enfrente lea su traducción cómodamente.

### 🌍 Packs de idiomas

Ve a la pestaña **Idiomas** para descargar las voces de cada idioma (~60 MB cada una). Español e inglés son gratuitos; el resto son Premium.

---

## 💎 Free vs Premium

| | Gratis | Premium |
|---|:---:|:---:|
| Conversación presencial | ✅ | ✅ |
| Español ↔ Inglés | ✅ | ✅ |
| Traducción de llamadas | — | ✅ |
| 10 idiomas adicionales | — | ✅ |
| Pantalla dividida | — | ✅ |

---

## 🔒 Privacidad

- ✅ Ningún audio ni texto sale del teléfono
- ✅ Sin cuentas, sin registro, sin anuncios, sin rastreadores
- ✅ El historial se guarda solo en tu dispositivo (puedes borrarlo o desactivarlo)
- 🌐 Única conexión: descarga inicial de modelos de IA

## ❓ Problemas frecuentes

| Problema | Solución |
|---|---|
| "App no instalada" | Comprueba que tu CPU es de 64 bits y Android 8.0+ |
| La descarga de modelos falla | Verifica el WiFi y reintenta — reanuda donde quedó |
| Va lenta la traducción | Ajustes → sube los hilos de CPU (según tu móvil) |
| No se oye en llamadas | Pon el altavoz o usa auriculares con la app abierta |

---

<div align="center">

Hecho con Flutter + whisper.cpp + llama.cpp · Los modelos de IA se descargan de [Hugging Face](https://huggingface.co)

⭐ **Si te gusta, dale una estrella al repo**

</div>
