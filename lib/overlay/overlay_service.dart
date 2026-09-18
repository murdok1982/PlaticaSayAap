import 'package:flutter/services.dart';

class OverlayService {
  static const _channel = MethodChannel('com.platicasay/overlay');

  Future<bool> hasOverlayPermission() async {
    final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return result ?? false;
  }

  Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod<void>('requestOverlayPermission');
  }

  Future<bool> startCallTranslation() async {
    final result = await _channel.invokeMethod<bool>('startCallOverlay');
    return result ?? false;
  }

  Future<void> stopCallTranslation() async {
    await _channel.invokeMethod<void>('stopCallOverlay');
  }

  Future<void> pushTranslation({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
  }) async {
    await _channel.invokeMethod<void>('pushTranslation', {
      'sourceText': sourceText,
      'translatedText': translatedText,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
    });
  }
}
