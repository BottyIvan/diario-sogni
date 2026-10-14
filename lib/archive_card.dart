import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'archive_manager.dart';

class ArchiveCard extends StatelessWidget {
  const ArchiveCard({super.key, required this.manager, required this.onSynced});
  final ArchiveManager manager;
  final Future<void> Function() onSynced;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: manager,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.folder_open_outlined),
            const SizedBox(height: 12),
            const Text(
              'Cartella condivisa',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Scegli sul PC una cartella sincronizzata da Google Drive, Dropbox o dal servizio che preferisci. Usa lo stesso archivio del telefono. Il browser chiederà il permesso di leggere e scrivere.'
                  : 'Scegli una cartella locale o una cartella resa disponibile dal tuo servizio cloud. Se il servizio non compare o non permette la scelta di cartelle, il collegamento diretto con quell’account non è ancora disponibile.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Puoi scegliere la cartella “Diario dei sogni” oppure quella che la contiene. Se l’archivio non esiste, l’app lo crea. Il servizio scelto deve trasferirlo tra telefono e PC. '
              'Premi Sincronizza per inviare e ricevere audio e testi. Le cancellazioni si trasferiscono con la sincronizzazione.',
            ),
            if (!manager.port.supported) ...[
              const SizedBox(height: 12),
              const Text(
                'Per collegare una cartella dal PC apri l’app in Chrome o Edge, su HTTPS oppure localhost.',
              ),
            ] else ...[
              if (manager.folderLabel != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Cartella: ${manager.folderLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: manager.busy ? null : manager.choose,
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      manager.folderLabel == null
                          ? 'Collega cartella'
                          : 'Cambia cartella',
                    ),
                  ),
                  if (manager.folderLabel != null)
                    FilledButton.icon(
                      onPressed: manager.busy
                          ? null
                          : () async {
                              await manager.synchronize();
                              await onSynced();
                            },
                      icon: const Icon(Icons.sync),
                      label: Text(
                        manager.busy ? 'Sincronizzazione…' : 'Sincronizza',
                      ),
                    ),
                  if (manager.folderLabel != null)
                    TextButton(
                      onPressed: manager.busy ? null : manager.disconnect,
                      child: const Text('Scollega'),
                    ),
                ],
              ),
            ],
            if (manager.busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (manager.lastResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(manager.lastResult!),
              ),
            if (manager.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  manager.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
