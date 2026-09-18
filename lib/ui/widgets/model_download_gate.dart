import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/model_manager.dart';
import '../../state/app_state.dart';

class ModelDownloadGate extends ConsumerStatefulWidget {
  const ModelDownloadGate({super.key});

  @override
  ConsumerState<ModelDownloadGate> createState() => _ModelDownloadGateState();
}

class _ModelDownloadGateState extends ConsumerState<ModelDownloadGate> {
  double _progress = 0;
  PackStatus _status = PackStatus.notDownloaded;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final manager = ref.read(modelManagerProvider);
    await for (final p in manager.downloadCoreModels()) {
      if (!mounted) return;
      setState(() {
        _progress = p.progress;
        _status = p.status;
        _error = p.error;
      });
    }
    if (mounted && _status == PackStatus.downloaded) {
      ref.invalidate(coreModelsReadyProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.model_training, size: 72),
              const SizedBox(height: 24),
              Text(
                'Descargando modelos de traducción',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Primera ejecución: se descargan el reconocedor de voz y el modelo base (~75 MB). Funcionará sin internet después.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_status == PackStatus.error) ...[
                Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _startDownload,
                  child: const Text('Reintentar'),
                ),
              ] else ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text('${(_progress * 100).toStringAsFixed(1)}%'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
