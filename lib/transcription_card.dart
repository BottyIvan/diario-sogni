import 'package:flutter/material.dart';

import 'transcription_manager.dart';

class TranscriptionCard extends StatelessWidget {
  const TranscriptionCard({
    super.key,
    required this.manager,
    this.dreamId,
    this.onReady,
    this.onRetry,
  });
  final TranscriptionManager manager;
  final String? dreamId;
  final VoidCallback? onReady, onRetry;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: manager,
    builder: (context, _) {
      final stage = manager.stages[dreamId];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notes_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trascrizione sul dispositivo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!manager.engine.supported)
                const Text(
                  'La trascrizione locale è disponibile per ora su Android. Nel browser puoi scrivere e cercare il testo del sogno.',
                )
              else if (manager.downloading) ...[
                Text(
                  'Download del modello: ${(manager.downloadProgress * 100).round()}%',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: manager.downloadProgress),
                const SizedBox(height: 8),
                const Text('Il download può continuare mentre salvi il sogno.'),
              ] else if (!manager.ready) ...[
                const Text(
                  'Scarica il modello una volta (circa 191 MB). Poi la trascrizione funziona anche senza Internet e riconosce automaticamente la lingua. Gli audio non vengono caricati: il download proviene da Hugging Face.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    if (await manager.download()) onReady?.call();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Scarica modello locale'),
                ),
              ] else if (stage == TranscriptionStage.waiting)
                const Text(
                  'Trascrizione in attesa. Puoi salvare e tornare alla home.',
                )
              else if (stage == TranscriptionStage.running) ...[
                Text(
                  'Trascrizione in corso: ${((manager.progress[dreamId] ?? 0) * 100).round()}%',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (manager.progress[dreamId] ?? 0) > 0
                      ? manager.progress[dreamId]
                      : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Puoi salvare, usare un’altra app o spegnere lo schermo. La trascrizione continua sul dispositivo.',
                ),
              ] else if (stage == TranscriptionStage.failed) ...[
                const Text(
                  'Trascrizione non riuscita. L’audio è conservato e puoi riprovare.',
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Riprova trascrizione'),
                  ),
              ] else ...[
                Text(
                  dreamId == null
                      ? 'Modello pronto. I nuovi sogni vengono trascritti automaticamente; apri un sogno precedente per trascriverlo.'
                      : 'Il modello locale è pronto. Puoi correggere il testo senza perdere l’audio.',
                ),
              ],
              if (manager.modelError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    manager.modelError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
