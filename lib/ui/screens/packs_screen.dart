import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ads/ad_service.dart';
import '../../core/languages.dart';
import '../../models/model_manager.dart';
import '../../state/app_state.dart';

class PacksScreen extends ConsumerStatefulWidget {
  const PacksScreen({super.key});

  @override
  ConsumerState<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends ConsumerState<PacksScreen> {
  final _progress = <String, double>{};
  final _downloaded = <String, bool>{};
  final _downloading = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final manager = ref.read(modelManagerProvider);
    for (final lang in Languages.all) {
      _downloaded[lang.code] = await manager.isLanguagePackDownloaded(lang);
    }
    if (mounted) setState(() {});
  }

  Future<void> _download(Language lang) async {
    final manager = ref.read(modelManagerProvider);
    setState(() => _downloading[lang.code] = true);
    await for (final p in manager.downloadLanguagePack(lang)) {
      if (!mounted) return;
      setState(() {
        _progress[lang.code] = p.progress;
        if (p.status == PackStatus.downloaded) _downloaded[lang.code] = true;
      });
    }
    setState(() => _downloading[lang.code] = false);
  }

  Future<void> _delete(Language lang) async {
    await ref.read(modelManagerProvider).deleteLanguagePack(lang);
    setState(() => _downloaded[lang.code] = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paquetes de Idioma'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Tarjeta Informativa
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt, color: Color(0xFF00D2B4), size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Offline tras descarga',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Descarga los idiomas que necesites para traducir sin conexión a internet ni gastar datos.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Tarjeta Opcional: Apoya la app con un vídeo bonificado
          Card(
            color: const Color(0xFF16253B),
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism, color: Color(0xFF3880FF)),
              title: const Text('¿Te gusta Platica-Say?', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Apóyanos viendo un vídeo corto de 15s para mantener el proyecto gratuito.'),
              trailing: FilledButton.tonal(
                onPressed: () {
                  AdService.instance.showRewardedAd(
                    onUserEarnedReward: () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Muchas gracias por apoyar el proyecto! ❤️'),
                            backgroundColor: Color(0xFF00D2B4),
                          ),
                        );
                      }
                    },
                  );
                },
                child: const Text('Apoyar'),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              '15 Idiomas Disponibles',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          // Lista de los 15 Idiomas
          ...Languages.all.map((lang) {
            final downloaded = _downloaded[lang.code] ?? false;
            final downloading = _downloading[lang.code] ?? false;

            if (lang.isBaseLanguage) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 28)),
                  title: Text(lang.nativeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${lang.englishName} · Incluido de serie (offline)'),
                  trailing: const Chip(
                    label: Text('Listo', style: TextStyle(fontSize: 11, color: Color(0xFF00D2B4))),
                    backgroundColor: Color(0xFF132B27),
                    padding: EdgeInsets.zero,
                  ),
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 28)),
                title: Text(lang.nativeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: downloading
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(value: _progress[lang.code]),
                      )
                    : Text('${lang.englishName} · ~${lang.packSizeMb} MB · Gratis'),
                trailing: downloaded
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Eliminar paquete para liberar espacio',
                        onPressed: () => _delete(lang),
                      )
                    : IconButton(
                        icon: const Icon(Icons.download_for_offline, color: Color(0xFF3880FF), size: 28),
                        tooltip: 'Descargar paquete',
                        onPressed: downloading ? null : () => _download(lang),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
