class AppConstants {
  static const appName = 'Platica-Say';

  // Modelo STT Whisper ultraligero optimizado para gama baja y media (~39 MB vs 180 MB anteriores)
  static const whisperModelFile = 'ggml-tiny-q5_1.bin';
  static const translatorModelFile = 'model-es-en.bin';

  static const whisperModelUrl = String.fromEnvironment(
    'WHISPER_MODEL_URL',
    defaultValue:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny-q5_1.bin',
  );

  static const translatorModelUrl = String.fromEnvironment(
    'TRANSLATOR_MODEL_URL',
    defaultValue:
        'https://huggingface.co/Helsinki-NLP/opus-mt-es-en/resolve/main/model.npz',
  );

  static const translationPacksBaseUrl = String.fromEnvironment(
    'TRANSLATION_PACKS_BASE_URL',
    defaultValue:
        'https://huggingface.co/Helsinki-NLP',
  );

  static const sampleRate = 16000;
  static const vadWindowMs = 30;
  static const vadSilenceMs = 500; // Reducido para mayor agilidad en respuestas
  static const maxSegmentSeconds = 10;

  static const targetPartialLatencyMs = 350; // Objetivo en tiempo real para gama media

  static const dbName = 'platica_say.db';
  static const dbVersion = 1;
}
