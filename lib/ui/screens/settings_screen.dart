import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _threads = 3;
  bool _ttsEnabled = true;
  bool _saveHistory = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _threads = prefs.getInt('threads') ?? 3;
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      _saveHistory = prefs.getBool('save_history') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('threads', _threads);
    await prefs.setBool('tts_enabled', _ttsEnabled);
    await prefs.setBool('save_history', _saveHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Rendimiento y Hardware
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.memory, color: Color(0xFF3880FF)),
                      const SizedBox(width: 10),
                      Text(
                        'Rendimiento en Gama Baja / Media',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hilos de CPU para IA: $_threads núcleos',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'En móviles de gama media se recomienda 3-4 hilos para equilibrar velocidad y temperatura.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _threads.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    label: '$_threads',
                    onChanged: (v) {
                      setState(() => _threads = v.round());
                      _save();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Opciones Generales
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined, color: Color(0xFF00D2B4)),
                  title: const Text('Voz de salida (TTS)'),
                  subtitle: const Text('Reproduce la traducción en voz alta automáticamente'),
                  value: _ttsEnabled,
                  onChanged: (v) {
                    setState(() => _ttsEnabled = v);
                    _save();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.history_toggle_off, color: Color(0xFF3880FF)),
                  title: const Text('Guardar historial local'),
                  subtitle: const Text('Almacena las conversaciones en la base de datos de tu teléfono'),
                  value: _saveHistory,
                  onChanged: (v) {
                    setState(() => _saveHistory = v);
                    _save();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Privacidad y Seguridad
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF00D2B4)),
                      SizedBox(width: 10),
                      Text(
                        '100% Privacidad Garantizada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todo el procesamiento de voz y traducción ocurre directamente en el procesador de tu móvil. Ninguna conversación, audio ni dato se envía a la nube.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Aviso Legal de Grabación en Llamadas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel_outlined, color: Colors.amber),
                      SizedBox(width: 10),
                      Text(
                        'Aviso Legal sobre Llamadas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La traducción y captura de llamadas puede requerir el consentimiento de ambas partes según la legislación de tu país o estado. El usuario es el único responsable del uso que dé a la aplicación.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Versión y Créditos
          const Center(
            child: Column(
              children: [
                Text(
                  'Platica-Say v0.1.0+1',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Traducción de voz en tiempo real · 100% Offline & Gratuito',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
