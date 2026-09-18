import 'dart:async';
import 'dart:typed_data';

enum AudioSource { microphone, callAudio }

abstract class AudioCaptureService {
  Stream<Float32List> get audioStream;

  Future<void> start(AudioSource source);
  Future<void> stop();
  bool get isCapturing;
}

class AudioCaptureException implements Exception {
  final String message;
  AudioCaptureException(this.message);
  @override
  String toString() => 'AudioCaptureException: $message';
}
