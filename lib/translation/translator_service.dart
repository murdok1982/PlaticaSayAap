import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _LlamaInitNative = Pointer<Void> Function(Pointer<Utf8> modelPath, Int32 nThreads);
typedef _LlamaInit = Pointer<Void> Function(Pointer<Utf8> modelPath, int nThreads);
typedef _LlamaFreeNative = Void Function(Pointer<Void> ctx);
typedef _LlamaFree = void Function(Pointer<Void> ctx);
typedef _LlamaTokenCbNative = Void Function(Pointer<Utf8> token, Pointer<Void> userData);
typedef _LlamaGenNative = Int32 Function(
  Pointer<Void> ctx,
  Pointer<Utf8> prompt,
  Pointer<NativeFunction<_LlamaTokenCbNative>> onToken,
  Pointer<Void> userData,
);
typedef _LlamaGen = int Function(
  Pointer<Void> ctx,
  Pointer<Utf8> prompt,
  Pointer<NativeFunction<_LlamaTokenCbNative>> onToken,
  Pointer<Void> userData,
);

class TranslatorService {
  Pointer<Void>? _ctx;
  late _LlamaGen _generate;
  late _LlamaFree _free;
  int _nThreads = 4;

  bool get isLoaded => _ctx != null && _ctx != nullptr;

  Future<void> load(String modelPath, {int? threads}) async {
    final lib = _openLibrary();
    final init = lib.lookupFunction<_LlamaInitNative, _LlamaInit>(
      'platica_llama_init',
    );
    _generate = lib.lookupFunction<_LlamaGenNative, _LlamaGen>(
      'platica_llama_generate',
    );
    _free = lib.lookupFunction<_LlamaFreeNative, _LlamaFree>(
      'platica_llama_free',
    );
    _nThreads = threads ?? _nThreads;

    final pathPtr = modelPath.toNativeUtf8();
    try {
      _ctx = init(pathPtr, _nThreads);
      if (_ctx == nullptr) {
        throw TranslatorException('No se pudo cargar el modelo traductor: $modelPath');
      }
    } finally {
      malloc.free(pathPtr);
    }
  }

  Stream<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) {
    if (!isLoaded) throw TranslatorException('Modelo traductor no cargado');

    final prompt = '<2$targetLang> $text';
    final controller = StreamController<String>();

    late NativeCallable<_LlamaTokenCbNative> callable;
    callable = NativeCallable<_LlamaTokenCbNative>.listener(
      (Pointer<Utf8> token, Pointer<Void> userData) {
        if (token != nullptr) {
          final piece = token.toDartString();
          if (piece == '<eos>' || piece.contains('</s>')) {
            if (!controller.isClosed) controller.close();
          } else {
            controller.add(piece);
          }
        }
      },
    );

    final promptPtr = prompt.toNativeUtf8();
    Future(() {
      try {
        final code = _generate(
          _ctx!,
          promptPtr,
          callable.nativeFunction,
          nullptr,
        );
        if (code != 0 && !controller.isClosed) {
          controller.addError(TranslatorException('Error de generación: $code'));
        }
      } finally {
        malloc.free(promptPtr);
        if (!controller.isClosed) controller.close();
        callable.close();
      }
    });

    return controller.stream;
  }

  void dispose() {
    if (isLoaded) {
      _free(_ctx!);
      _ctx = null;
    }
  }

  DynamicLibrary _openLibrary() {
    if (Platform.isAndroid) return DynamicLibrary.open('libplatica_llama.so');
    return DynamicLibrary.process();
  }
}

class TranslatorException implements Exception {
  final String message;
  TranslatorException(this.message);
  @override
  String toString() => 'TranslatorException: $message';
}
