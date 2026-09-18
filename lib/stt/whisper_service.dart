import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

class TranscriptionResult {
  final String text;
  final String detectedLanguage;
  final double confidence;
  final Duration latency;

  const TranscriptionResult({
    required this.text,
    required this.detectedLanguage,
    required this.confidence,
    required this.latency,
  });
}

typedef _WhisperInitNative = Pointer<Void> Function(Pointer<Utf8> modelPath);
typedef _WhisperInit = Pointer<Void> Function(Pointer<Utf8> modelPath);
typedef _WhisperFreeNative = Void Function(Pointer<Void> ctx);
typedef _WhisperFree = void Function(Pointer<Void> ctx);
typedef _WhisperTranscribeNative = Pointer<Utf8> Function(
  Pointer<Void> ctx,
  Pointer<Float> samples,
  Int32 nSamples,
  Pointer<Utf8> outLang,
);
typedef _WhisperTranscribe = Pointer<Utf8> Function(
  Pointer<Void> ctx,
  Pointer<Float> samples,
  int nSamples,
  Pointer<Utf8> outLang,
);

class WhisperService {
  Pointer<Void>? _ctx;
  late _WhisperTranscribe _transcribe;
  late _WhisperFree _free;

  bool get isLoaded => _ctx != null && _ctx != nullptr;

  Future<void> load(String modelPath) async {
    final lib = _openLibrary();
    final init = lib.lookupFunction<_WhisperInitNative, _WhisperInit>(
      'platica_whisper_init',
    );
    _transcribe = lib.lookupFunction<_WhisperTranscribeNative, _WhisperTranscribe>(
      'platica_whisper_transcribe',
    );
    _free = lib.lookupFunction<_WhisperFreeNative, _WhisperFree>(
      'platica_whisper_free',
    );

    final pathPtr = modelPath.toNativeUtf8();
    try {
      _ctx = init(pathPtr);
      if (_ctx == nullptr) {
        throw WhisperException('whisper.cpp no pudo cargar el modelo: $modelPath');
      }
    } finally {
      malloc.free(pathPtr);
    }
  }

  TranscriptionResult transcribe(Float32List samples) {
    if (!isLoaded) throw WhisperException('Modelo Whisper no cargado');
    final sw = Stopwatch()..start();

    final samplePtr = malloc<Float>(samples.length);
    final langPtr = malloc<Uint8>(8).cast<Utf8>();
    try {
      for (var i = 0; i < samples.length; i++) {
        samplePtr[i] = samples[i];
      }
      final resultPtr = _transcribe(_ctx!, samplePtr, samples.length, langPtr);
      sw.stop();
      if (resultPtr == nullptr) {
        throw WhisperException('Fallo en la transcripción');
      }
      return TranscriptionResult(
        text: resultPtr.toDartString().trim(),
        detectedLanguage: langPtr.toDartString(),
        confidence: 1.0,
        latency: sw.elapsed,
      );
    } finally {
      malloc.free(samplePtr);
      malloc.free(langPtr);
    }
  }

  void dispose() {
    if (isLoaded) {
      _free(_ctx!);
      _ctx = null;
    }
  }

  DynamicLibrary _openLibrary() {
    if (Platform.isAndroid) return DynamicLibrary.open('libplatica_whisper.so');
    return DynamicLibrary.process();
  }
}

class WhisperException implements Exception {
  final String message;
  WhisperException(this.message);
  @override
  String toString() => 'WhisperException: $message';
}
