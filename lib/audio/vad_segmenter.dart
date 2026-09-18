import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../core/constants.dart';

class VadSegmenter {
  final _buffer = <double>[];
  final _controller = StreamController<Float32List>.broadcast();
  int _silentFrames = 0;
  bool _speaking = false;

  static final int _windowSamples =
      AppConstants.sampleRate * AppConstants.vadWindowMs ~/ 1000;
  static final int _silenceFramesNeeded =
      AppConstants.vadSilenceMs ~/ AppConstants.vadWindowMs;
  static final int _maxSamples =
      AppConstants.sampleRate * AppConstants.maxSegmentSeconds;

  Stream<Float32List> get segments => _controller.stream;

  void push(Float32List samples) {
    var offset = 0;
    while (offset < samples.length) {
      final remaining = samples.length - offset;
      final take = min(_windowSamples, remaining);
      for (var i = 0; i < take; i++) {
        _buffer.add(samples[offset + i]);
      }
      offset += take;

      while (_buffer.length >= _windowSamples) {
        final window = Float32List.fromList(
          _buffer.sublist(0, _windowSamples),
        );
        _buffer.removeRange(0, _windowSamples);
        _processWindow(window);
      }
    }
  }

  final _segment = <double>[];

  void _processWindow(Float32List window) {
    final speech = _isSpeech(window);
    if (speech) {
      _speaking = true;
      _silentFrames = 0;
      _segment.addAll(window);
    } else if (_speaking) {
      _silentFrames++;
      _segment.addAll(window);
      if (_silentFrames >= _silenceFramesNeeded) {
        _emit();
      }
    }

    if (_segment.length >= _maxSamples) {
      _emit();
    }
  }

  void _emit() {
    if (_segment.length < AppConstants.sampleRate ~/ 4) {
      _segment.clear();
      _speaking = false;
      _silentFrames = 0;
      return;
    }
    _controller.add(Float32List.fromList(_segment));
    _segment.clear();
    _speaking = false;
    _silentFrames = 0;
  }

  bool _isSpeech(Float32List window) {
    double energy = 0;
    var zeroCrossings = 0;
    for (var i = 0; i < window.length; i++) {
      energy += window[i] * window[i];
      if (i > 0 && ((window[i] >= 0) != (window[i - 1] >= 0))) {
        zeroCrossings++;
      }
    }
    final rms = sqrt(energy / window.length);
    final zcr = zeroCrossings / window.length;
    return rms > 0.012 && zcr > 0.02 && zcr < 0.45;
  }

  Future<void> flush() async {
    if (_segment.isNotEmpty) _emit();
  }

  void dispose() {
    _controller.close();
  }
}
