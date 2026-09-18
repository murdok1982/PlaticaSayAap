import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/app_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final store = ref.watch(historyStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await store.clear();
              ref.invalidate(historyProvider);
            },
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Sin conversaciones guardadas'));
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              return Dismissible(
                key: ValueKey(e.id),
                onDismissed: (_) async {
                  await store.delete(e.id!);
                  ref.invalidate(historyProvider);
                },
                background: Container(color: Colors.redAccent),
                child: ListTile(
                  title: Text(e.sourceText),
                  subtitle: Text(e.translatedText),
                  trailing: Text(
                    DateFormat.Hm().format(e.timestamp),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
