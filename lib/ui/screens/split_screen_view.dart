import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/languages.dart';
import '../../state/app_state.dart';

class SplitScreenView extends ConsumerWidget {
  final VoidCallback onExit;
  const SplitScreenView({super.key, required this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final latest = session.entries.isNotEmpty ? session.entries.first : null;

    final srcLang = Languages.byCode(latest?.sourceLang ?? session.lockedSource?.code ?? 'es');
    final tgtLang = Languages.byCode(latest?.targetLang ?? session.lockedTarget?.code ?? 'en');

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        child: Column(
          children: [
            // Panel Superior (Orientado hacia la persona de enfrente)
            Expanded(
              child: RotatedBox(
                quarterTurns: 2,
                child: _Pane(
                  text: latest?.translatedText ?? session.partialTranslation,
                  langName: tgtLang?.nativeName ?? 'Traducción',
                  flag: tgtLang?.flagEmoji ?? '🌐',
                  color: const Color(0xFF16253B),
                  textColor: const Color(0xFF00D2B4),
                ),
              ),
            ),

            // Barra Central con botón de Salir
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF131824),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Modo Cara a Cara',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close_fullscreen, size: 20),
                    onPressed: onExit,
                    tooltip: 'Volver a vista normal',
                  ),
                ],
              ),
            ),

            // Panel Inferior (Orientado hacia ti)
            Expanded(
              child: _Pane(
                text: latest?.sourceText ?? session.partialTranscript,
                langName: srcLang?.nativeName ?? 'Tu voz',
                flag: srcLang?.flagEmoji ?? '🌐',
                color: const Color(0xFF1C2333),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final String text;
  final String langName;
  final String flag;
  final Color color;
  final Color textColor;

  const _Pane({
    required this.text,
    required this.langName,
    required this.flag,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                langName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  text.isEmpty ? 'Habla para ver la traducción...' : text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: text.isEmpty ? Colors.white38 : textColor,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
