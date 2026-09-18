import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_capture.dart';
import '../audio/native_audio_capture.dart';
import '../audio/udp_audio_capture.dart';
import '../core/constants.dart';
import '../core/languages.dart';
import '../history/history_store.dart';
import '../models/model_manager.dart';
import '../overlay/overlay_service.dart';
import '../pipeline/translation_pipeline.dart';
import '../stt/whisper_service.dart';
import '../translation/translator_service.dart';
import '../tts/tts_service.dart';

final modelManagerProvider = Provider((ref) => ModelManager());
final historyStoreProvider = Provider((ref) => HistoryStore());
final overlayServiceProvider = Provider((ref) => OverlayService());
final ttsServiceProvider = Provider((ref) => TtsService());

final whisperProvider = Provider((ref) => WhisperService());
final translatorProvider = Provider((ref) => TranslatorService());
final captureProvider = Provider<AudioCaptureService>((ref) {
  if (Platform.isIOS) return UdpAudioCapture();
  return NativeAudioCapture();
});

final pipelineProvider = Provider((ref) {
  return TranslationPipeline(
    capture: ref.watch(captureProvider),
    whisper: ref.watch(whisperProvider),
    translator: ref.watch(translatorProvider),
  );
});

final coreModelsReadyProvider = FutureProvider<bool>((ref) {
  return ref.watch(modelManagerProvider).coreModelsReady();
});

final historyProvider = FutureProvider<List<ConversationEntry>>((ref) {
  return ref.watch(historyStoreProvider).recent();
});

class SessionState {
  final bool active;
  final AudioSource source;
  final Language? lockedSource;
  final Language? lockedTarget;
  final String partialTranscript;
  final String partialTranslation;
  final List<ConversationEntry> entries;

  const SessionState({
    this.active = false,
    this.source = AudioSource.microphone,
    this.lockedSource,
    this.lockedTarget,
    this.partialTranscript = '',
    this.partialTranslation = '',
    this.entries = const [],
  });

  SessionState copyWith({
    bool? active,
    AudioSource? source,
    Language? lockedSource,
    Language? lockedTarget,
    String? partialTranscript,
    String? partialTranslation,
    List<ConversationEntry>? entries,
  }) {
    return SessionState(
      active: active ?? this.active,
      source: source ?? this.source,
      lockedSource: lockedSource ?? this.lockedSource,
      lockedTarget: lockedTarget ?? this.lockedTarget,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      partialTranslation: partialTranslation ?? this.partialTranslation,
      entries: entries ?? this.entries,
    );
  }
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  Future<void> _ensureModelsLoaded() async {
    final manager = ref.read(modelManagerProvider);
    final whisper = ref.read(whisperProvider);
    final translator = ref.read(translatorProvider);

    if (!whisper.isLoaded) {
      await whisper.load(
        await manager.coreModelPath(AppConstants.whisperModelFile),
      );
    }
    if (!translator.isLoaded) {
      final prefs = await SharedPreferences.getInstance();
      await translator.load(
        await manager.coreModelPath(AppConstants.translatorModelFile),
        threads: prefs.getInt('threads') ?? 4,
      );
    }
  }

  Future<void> startSession(AudioSource source) async {
    await _ensureModelsLoaded();
    final pipeline = ref.read(pipelineProvider);
    final overlay = ref.read(overlayServiceProvider);
    final history = ref.read(historyStoreProvider);
    final prefs = await SharedPreferences.getInstance();
    final saveHistory = prefs.getBool('save_history') ?? true;
    final ttsEnabled = prefs.getBool('tts_enabled') ?? true;

    pipeline.events.listen((event) async {
      switch (event) {
        case PartialTranscript():
          state = state.copyWith(partialTranscript: event.text);
        case PartialTranslation():
          state = state.copyWith(partialTranslation: event.accumulated);
        case FinalSegment():
          final entry = ConversationEntry(
            timestamp: DateTime.now(),
            sourceLang: event.sourceLang,
            targetLang: event.targetLang,
            sourceText: event.sourceText,
            translatedText: event.translatedText,
          );
          if (saveHistory) {
            await history.insert(entry);
            ref.invalidate(historyProvider);
          }
          if (ttsEnabled) {
            final target = Languages.byCode(event.targetLang);
            if (target != null) {
              ref.read(ttsServiceProvider).speak(
                    event.translatedText,
                    locale: target.ttsLocale,
                  );
            }
          }
          state = state.copyWith(
            entries: [entry, ...state.entries],
            partialTranscript: '',
            partialTranslation: '',
          );
          if (state.source == AudioSource.callAudio) {
            overlay.pushTranslation(
              sourceText: event.sourceText,
              translatedText: event.translatedText,
              sourceLang: event.sourceLang,
              targetLang: event.targetLang,
            );
          }
        case PipelineError():
          break;
      }
    });

    await pipeline.start(
      source: source,
      lockedSource: state.lockedSource,
      lockedTarget: state.lockedTarget,
    );
    state = state.copyWith(active: true, source: source);
  }

  Future<void> stopSession() async {
    await ref.read(pipelineProvider).stop();
    state = state.copyWith(active: false);
  }

  void setLanguagePair(Language? source, Language? target) {
    state = state.copyWith(lockedSource: source, lockedTarget: target);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);
