import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ads/ad_service.dart';
import '../../audio/audio_capture.dart';
import '../../core/languages.dart';
import '../../overlay/overlay_service.dart';
import '../../state/app_state.dart';
import 'split_screen_view.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen>
    with SingleTickerProviderStateMixin {
  AudioSource _source = AudioSource.microphone;
  bool _splitScreen = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final notifier = ref.read(sessionProvider.notifier);

    if (_splitScreen) {
      return SplitScreenView(
        onExit: () => setState(() => _splitScreen = false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, color: Color(0xFF3880FF), size: 22),
            SizedBox(width: 8),
            Text('Platica-Say'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Modo Cara a Cara (Pantalla dividida)',
            onPressed: () => setState(() => _splitScreen = true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de Modo (Presencial vs Llamada)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<AudioSource>(
              segments: const [
                ButtonSegment(
                  value: AudioSource.microphone,
                  icon: Icon(Icons.mic),
                  label: Text('Presencial'),
                ),
                ButtonSegment(
                  value: AudioSource.callAudio,
                  icon: Icon(Icons.phone_in_talk),
                  label: Text('Llamada'),
                ),
              ],
              selected: {_source},
              onSelectionChanged: session.active
                  ? null
                  : (s) {
                      setState(() => _source = s.first);
                      if (s.first == AudioSource.callAudio) {
                        _showCallTipDialog();
                      }
                    },
            ),
          ),

          // Selector de Pares de Idioma con Banderas
          _LanguagePairSelector(
            enabled: !session.active,
            onChanged: (src, tgt) => notifier.setLanguagePair(src, tgt),
          ),

          const SizedBox(height: 8),

          // Lista de transcripciones y traducciones
          Expanded(
            child: _TranscriptList(session: session),
          ),

          // Tarjeta de Streaming Parcial en Vivo
          if (session.partialTranscript.isNotEmpty ||
              session.partialTranslation.isNotEmpty)
            _LivePartialCard(session: session),

          // Botón Principal de Iniciar / Detener con Pulso Reactivo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: session.active
                    ? AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.85 + (_pulseController.value * 0.15),
                              ),
                              elevation: 4 * _pulseController.value,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.stop_circle_outlined, size: 26),
                            label: const Text(
                              'Detener traducción',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _toggle(session.active),
                          );
                        },
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3880FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: const Text(
                          'Iniciar traducción',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _toggle(session.active),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallTipDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.volume_up, color: Color(0xFF3880FF)),
            SizedBox(width: 8),
            Text('Modo Llamada'),
          ],
        ),
        content: const Text(
          'Para traducir llamadas telefónicas o videollamadas con máxima nitidez:\n\n'
          '1. Pon tu llamada en ALTAVOZ / MANOS LIBRES.\n'
          '2. La app usará cancelación de eco para traducir la voz de ambos lados en tiempo real.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(bool active) async {
    final notifier = ref.read(sessionProvider.notifier);
    if (active) {
      await notifier.stopSession();
      if (_source == AudioSource.callAudio) {
        await OverlayService().stopCallTranslation();
      }
      // Mostrar anuncio intersticial con límite de descanso
      AdService.instance.showInterstitialIfReady();
      return;
    }

    if (_source == AudioSource.callAudio) {
      final overlay = OverlayService();
      if (!await overlay.hasOverlayPermission()) {
        await overlay.requestOverlayPermission();
        return;
      }
      final started = await overlay.startCallTranslation();
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la captura de llamada')),
        );
        return;
      }
    }
    await notifier.startSession(_source);
  }
}

class _LanguagePairSelector extends ConsumerWidget {
  final bool enabled;
  final void Function(Language? source, Language? target) onChanged;

  const _LanguagePairSelector({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final src = session.lockedSource ?? Languages.spanish;
    final tgt = session.lockedTarget ?? Languages.english;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E384D)),
      ),
      child: Row(
        children: [
          // Selector Idioma Origen
          Expanded(
            child: _LanguageDropdown(
              label: 'Habla',
              selected: src,
              enabled: enabled,
              onChanged: (l) {
                if (l != null) onChanged(l, tgt);
              },
            ),
          ),

          // Botón Invertir
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.swap_horiz, size: 20),
              onPressed: enabled ? () => onChanged(tgt, src) : null,
              tooltip: 'Invertir idiomas',
            ),
          ),

          // Selector Idioma Destino
          Expanded(
            child: _LanguageDropdown(
              label: 'Traduce a',
              selected: tgt,
              enabled: enabled,
              onChanged: (l) {
                if (l != null) onChanged(src, l);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String label;
  final Language selected;
  final bool enabled;
  final ValueChanged<Language?> onChanged;

  const _LanguageDropdown({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<Language>(
            value: selected,
            isDense: true,
            isExpanded: true,
            onChanged: enabled ? onChanged : null,
            items: Languages.all.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.flagEmoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lang.nativeName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TranscriptList extends StatelessWidget {
  final SessionState session;
  const _TranscriptList({required this.session});

  @override
  Widget build(BuildContext context) {
    if (session.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.record_voice_over_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Listo para traducir',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca "Iniciar traducción" para comenzar a hablar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: session.entries.length,
      itemBuilder: (context, i) {
        final e = session.entries[i];
        final srcLang = Languages.byCode(e.sourceLang);
        final tgtLang = Languages.byCode(e.targetLang);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(srcLang?.flagEmoji ?? '🌐'),
                    const SizedBox(width: 6),
                    Text(
                      srcLang?.nativeName ?? e.sourceLang.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.sourceText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Text(tgtLang?.flagEmoji ?? '🌐'),
                    const SizedBox(width: 6),
                    Text(
                      tgtLang?.nativeName ?? e.targetLang.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3880FF)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.translatedText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00D2B4),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LivePartialCard extends StatelessWidget {
  final SessionState session;
  const _LivePartialCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3880FF).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Escuchando...',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ],
          ),
          if (session.partialTranscript.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              session.partialTranscript,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
          if (session.partialTranslation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              session.partialTranslation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D2B4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
