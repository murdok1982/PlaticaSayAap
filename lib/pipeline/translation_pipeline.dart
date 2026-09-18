import 'dart:async';
import 'dart:typed_data';

import '../audio/audio_capture.dart';
import '../audio/vad_segmenter.dart';
import '../core/languages.dart';
import '../stt/whisper_service.dart';
import '../translation/translator_service.dart';

sealed class PipelineEvent {}

class PartialTranscript extends PipelineEvent {
  final String text;
  final String detectedLanguage;
  PartialTranscript(this.text, this.detectedLanguage);
}

class PartialTranslation extends PipelineEvent {
  final String sourceText;
  final String translatedChunk;
  final String accumulated;
  final String sourceLang;
  final String targetLang;
  PartialTranslation({
    required this.sourceText,
    required this.translatedChunk,
    required this.accumulated,
    required this.sourceLang,
    required this.targetLang,
  });
}

class FinalSegment extends PipelineEvent {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final Duration totalLatency;
  FinalSegment({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.totalLatency,
  });
}

class PipelineError extends PipelineEvent {
  final Object error;
  PipelineError(this.error);
}

class TranslationPipeline {
  final AudioCaptureService capture;
  final WhisperService whisper;
  final TranslatorService translator;

  final _vad = VadSegmenter();
  final _events = StreamController<PipelineEvent>.broadcast();
  StreamSubscription? _captureSub;
  StreamSubscription? _segmentSub;
  bool _running = false;

  Language? _lockedSource;
  Language? _lockedTarget;

  TranslationPipeline({
    required this.capture,
    required this.whisper,
    required this.translator,
  });

  Stream<PipelineEvent> get events => _events.stream;
  bool get isRunning => _running;

  Future<void> start({
    required AudioSource source,
    Language? lockedSource,
    Language? lockedTarget,
  }) async {
    if (_running) return;
    _lockedSource = lockedSource;
    _lockedTarget = lockedTarget;

    _segmentSub = _vad.segments.listen(_handleSegment);
    _captureSub = capture.audioStream.listen(_vad.push);
    await capture.start(source);
    _running = true;
  }

  Future<void> stop() async {
    _running = false;
    await _captureSub?.cancel();
    await _segmentSub?.cancel();
    await capture.stop();
    await _vad.flush();
  }

  void _handleSegment(Float32List samples) {
    if (!_running) return;
    final sw = Stopwatch()..start();
    try {
      final result = whisper.transcribe(samples);
      if (result.text.isEmpty) return;

      final detected = Languages.byCode(result.detectedLanguage);
      final sourceLang = _lockedSource ?? detected ?? Languages.spanish;
      final targetLang = _lockedTarget ??
          (sourceLang.code == Languages.spanish.code
              ? Languages.english
              : Languages.spanish);

      _events.add(PartialTranscript(result.text, sourceLang.code));

      final buffer = StringBuffer();
      final stream = translator.translate(
        text: result.text,
        sourceLang: sourceLang.code,
        targetLang: targetLang.code,
      );

      stream.listen(
        (chunk) {
          buffer.write(chunk);
          _events.add(PartialTranslation(
            sourceText: result.text,
            translatedChunk: chunk,
            accumulated: buffer.toString(),
            sourceLang: sourceLang.code,
            targetLang: targetLang.code,
          ));
        },
        onDone: () {
          sw.stop();
          final translated = buffer.toString().trim();
          if (translated.isNotEmpty) {
            _events.add(FinalSegment(
              sourceText: result.text,
              translatedText: translated,
              sourceLang: sourceLang.code,
              targetLang: targetLang.code,
              totalLatency: sw.elapsed,
            ));
          }
        },
        onError: (e) => _events.add(PipelineError(e)),
      );
    } catch (e) {
      _events.add(PipelineError(e));
    }
  }

  void dispose() {
    _vad.dispose();
    _events.close();
  }
}
