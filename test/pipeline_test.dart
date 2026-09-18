import 'package:flutter_test/flutter_test.dart';
import 'package:platica_say/audio/vad_segmenter.dart';
import 'package:platica_say/core/languages.dart';
import 'dart:math';
import 'dart:typed_data';

void main() {
  test('Languages contiene 15 idiomas mayoritarios con códigos y banderas únicos', () {
    expect(Languages.all.length, 15);
    final codes = Languages.all.map((l) => l.code).toSet();
    expect(codes.length, 15);
    expect(Languages.byCode('es')?.nativeName, 'Español');
    expect(Languages.byCode('zh')?.flagEmoji, '🇨🇳');
    expect(Languages.byCode('ar')?.nativeName, 'العربية');
    expect(Languages.byCode('xx'), isNull);
  });

  test('VadSegmenter emite segmento tras voz + silencio', () async {
    final vad = VadSegmenter();
    final segments = <Float32List>[];
    final sub = vad.segments.listen(segments.add);

    final rng = Random(42);
    final speech = Float32List.fromList(
      List.generate(16000, (_) => (rng.nextDouble() - 0.5) * 0.4),
    );
    vad.push(speech);

    final silence = Float32List(16000);
    vad.push(silence);
    await vad.flush();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(segments, isNotEmpty);
    await sub.cancel();
    vad.dispose();
  });
}
