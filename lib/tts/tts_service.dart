import 'package:flutter/services.dart';

class TtsService {
  static const _channel = MethodChannel('com.platicasay/tts');

  Future<void> loadVoice(String voiceId, String modelDir) async {
    await _channel.invokeMethod<void>('loadVoice', {
      'voiceId': voiceId,
      'modelDir': modelDir,
    });
  }

  Future<void> speak(String text, {String? voiceId, String? locale}) async {
    await _channel.invokeMethod<void>('speak', {
      'text': text,
      'voiceId': voiceId,
      'locale': locale,
    });
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }
}
