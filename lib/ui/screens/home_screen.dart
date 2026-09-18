import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ads/ad_service.dart';
import '../../state/app_state.dart';
import '../widgets/model_download_gate.dart';
import 'conversation_screen.dart';
import 'history_screen.dart';
import 'packs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(coreModelsReadyProvider);

    return ready.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error al cargar modelos: $e', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (isReady) {
        if (!isReady) return const ModelDownloadGate();

        final screens = [
          const ConversationScreen(),
          const HistoryScreen(),
          const PacksScreen(),
          const SettingsScreen(),
        ];

        return Scaffold(
          body: Column(
            children: [
              Expanded(child: screens[_index]),
              const AppAdBanner(), // Banner no invasivo en la parte inferior
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.mic_outlined),
                selectedIcon: Icon(Icons.mic),
                label: 'Traductor',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Historial',
              ),
              NavigationDestination(
                icon: Icon(Icons.language_outlined),
                selectedIcon: Icon(Icons.language),
                label: 'Idiomas',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          ),
        );
      },
    );
  }
}
