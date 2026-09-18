import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../core/constants.dart';
import 'audio_capture.dart';

class NativeAudioCapture implements AudioCaptureService {
  static const _method = MethodChannel('com.platicasay/audio/methods');
  static const _events = EventChannel('com.platicasay/audio/pcm');

  Stream<Float32List>? _stream;
  bool _capturing = false;

  @override
  bool get isCapturing => _capturing;

  @override
  Stream<Float32List> get audioStream {
    _stream ??= _events.receiveBroadcastStream().map((data) {
      final bytes = data as Uint8List;
      return Float32List.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes ~/ 4);
    });
    return _stream!;
  }

  @override
  Future<void> start(AudioSource source) async {
    final ok = await _method.invokeMethod<bool>('startCapture', {
      'source': source == AudioSource.callAudio ? 'call' : 'mic',
      'sampleRate': AppConstants.sampleRate,
    });
    if (ok != true) {
      throw AudioCaptureException('No se pudo iniciar la captura de audio ($source)');
    }
    _capturing = true;
  }

  @override
  Future<void> stop() async {
    await _method.invokeMethod<void>('stopCapture');
    _capturing = false;
  }
}
