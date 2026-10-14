import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'dream.dart';
import 'dream_repository.dart';
import 'recording_controller.dart';
import 'storage.dart' as storage;
import 'transcriber.dart' as transcriber;
import 'transcription_manager.dart';
import 'transcription_card.dart';
import 'background_platform.dart' as background;
import 'archive_platform.dart' as archive;
import 'archive_manager.dart';
import 'archive_card.dart';

const ink = Color(0xFF282238);
const plum = Color(0xFF695287);
const paper = Color(0xFFFAF8F5);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DreamApp());
}

class DreamApp extends StatelessWidget {
  const DreamApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Diario dei sogni',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: plum, surface: paper),
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    home: const DreamHome(),
  );
}

class DreamHome extends StatefulWidget {
  const DreamHome({
    super.key,
    this.repository,
    this.recorder,
    this.recordingController,
  });
  final DreamRepository? repository;
  final RecorderPort? recorder;
  final RecordingController? recordingController;
  @override
  State<DreamHome> createState() => _DreamHomeState();
}

class _DreamHomeState extends State<DreamHome> with WidgetsBindingObserver {
  DreamRepository? _repository;
  RecordingController? _recording;
  TranscriptionManager? _transcription;
  ArchiveManager? _sharedArchive;
  final _appliedResults = <String, Dream>{};
  List<Dream> _dreams = [];
  bool _loading = true;
  String? _loadError;
  String _query = '';
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      _repository ??=
          widget.repository ??
          DreamRepository(await storage.openDreamDatabase());
      final dreams = await _repository!.load();
      if (!mounted) return;
      if (_transcription == null) {
        _transcription = TranscriptionManager(
          engine: transcriber.createTranscriber(),
          repository: _repository!,
          background: background.createBackgroundGuard(),
        );
        await _transcription!.initialize();
        if (!mounted) return;
        _transcription!.addListener(_onTranscriptionChanged);
      }
      _recording ??=
          (widget.recordingController ??
                RecordingController(
                  recorder: widget.recorder ?? DeviceRecorder(),
                  createPath: storage.recordingPath,
                  persistAudio: storage.persistAudio,
                  saveDream: _repository!.save,
                ))
            ..addListener(_onRecordingChanged);
      if (_sharedArchive == null) {
        _sharedArchive = ArchiveManager(
          port: archive.createArchivePort(),
          repository: _repository!,
          readAudio: storage.readAudio,
          importAudio: storage.importAudio,
          deleteAudio: storage.deleteAudio,
          audioExtension: storage.audioExtension,
          beforeDelete: _transcription!.forget,
        );
        await _sharedArchive!.initialize();
      }
      if (!mounted) return;
      setState(() {
        _dreams = dreams;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Non riesco ad aprire l’archivio locale. Riprova.';
        });
      }
    }
  }

  void _onRecordingChanged() {
    if (mounted) setState(() {});
  }

  void _onTranscriptionChanged() {
    if (!mounted) return;
    setState(() {
      for (final entry in _transcription!.results.entries) {
        if (!identical(_appliedResults[entry.key], entry.value)) {
          _dreams = _dreams
              .map((dream) => dream.id == entry.key ? entry.value : dream)
              .toList();
          _appliedResults[entry.key] = entry.value;
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        _recording?.stage == RecordingStage.recording) {
      unawaited(_recording!.togglePause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recording?.removeListener(_onRecordingChanged);
    _recording?.dispose();
    _transcription?.removeListener(_onTranscriptionChanged);
    _transcription?.dispose();
    _sharedArchive?.dispose();
    if (widget.repository == null) {
      unawaited(_repository?.database.close() ?? Future<void>.value());
    }
    super.dispose();
  }

  Future<void> _finish() async {
    final dream = await _recording!.finish();
    if (dream == null || !mounted) return;
    setState(() {
      _dreams = [dream, ..._dreams.where((d) => d.id != dream.id)];
      _tab = 0;
      _query = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sogno salvato sul dispositivo.')),
    );
    if (_transcription!.ready) unawaited(_transcription!.run(dream));
    await _openDream(dream);
  }

  Future<void> _openDream(Dream dream) async {
    if (_recording?.active == true) return;
    await Navigator.of(context).push<Dream>(
      MaterialPageRoute(
        builder: (_) => DreamDetail(
          dream: dream,
          repository: _repository!,
          transcription: _transcription,
          sharedArchive: _sharedArchive,
          onSaved: () {
            if (mounted) {
              setState(() {
                _tab = 0;
                _query = '';
              });
            }
          },
        ),
      ),
    );
    if (mounted) await _reloadArchive();
  }

  Future<void> _reloadArchive() async {
    final dreams = await _repository!.load();
    if (mounted) {
      setState(() {
        _dreams = dreams;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _recording?.active != true,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salva prima la registrazione in corso.'),
          ),
        );
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: plum),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Diario dei sogni',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Guida',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Il tuo primo diario'),
                content: const Text(
                  'Tocca “Racconta un sogno”, parla e poi termina la registrazione. Nel riepilogo puoi ascoltare l’audio, cambiare titolo e salvare per tornare alla home.\n\nSu Android scarica il modello locale dal riepilogo o dalle impostazioni: i nuovi sogni saranno trascritti automaticamente, anche senza Internet. La lingua viene riconosciuta automaticamente. Il testo è modificabile e ricercabile.\n\nSe cambi app o blocchi lo schermo durante la registrazione, questa va in pausa. Dopo averla terminata, la trascrizione può continuare in background con una notifica silenziosa temporanea. Arrestare forzatamente l’app interrompe l’elaborazione: riapri il sogno per riprovare. Audio e testi restano sul dispositivo. Dal dettaglio premi il cestino per eliminare un sogno e i suoi dati. Nelle impostazioni puoi collegare una cartella condivisa e premere Sincronizza per inviare o ricevere audio e testi sul telefono e sul PC.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ho capito'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!),
                  TextButton(
                    onPressed: _initialize,
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: _tab == 2
                    ? SettingsPage(
                        transcription: _transcription!,
                        sharedArchive: _sharedArchive!,
                        onSynced: _reloadArchive,
                      )
                    : _archive(),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          if (_recording?.active == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Salva il sogno prima di cambiare schermata.'),
              ),
            );
          } else {
            setState(() {
              _tab = index;
              _query = '';
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Sogni',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Cerca'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Impostazioni'),
        ],
      ),
    ),
  );

  Widget _archive() {
    final dreams = _dreams.where((d) => d.matches(_query)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      children: [
        if (_tab == 0) ...[
          const Text(
            'Conserva ciò che ricordi.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Una voce, un ricordo, un sogno alla volta.',
            style: TextStyle(color: plum, fontSize: 15),
          ),
          const SizedBox(height: 22),
          _recordCard(),
          const SizedBox(height: 28),
        ] else ...[
          const Text(
            'Ritrova un sogno',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Cerca un titolo o una parola…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() {
              _query = value;
            }),
          ),
          const SizedBox(height: 10),
          const Text(
            'La ricerca include i titoli e i testi che hai aggiunto.',
            style: TextStyle(color: plum),
          ),
          const SizedBox(height: 22),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                _tab == 0 ? 'I tuoi sogni' : 'Risultati',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
            Text('${dreams.length}', style: const TextStyle(color: plum)),
          ],
        ),
        const SizedBox(height: 12),
        if (dreams.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.nights_stay_outlined, color: plum, size: 42),
                const SizedBox(height: 14),
                Text(
                  _dreams.isEmpty
                      ? 'Qui inizierà il tuo diario'
                      : 'Nessun sogno trovato',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _dreams.isEmpty
                      ? 'Registra il primo ricordo, anche se è solo un piccolo frammento.'
                      : 'Prova con un’altra parola o un titolo.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        for (final dream in dreams)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFE8F5),
                  child: Icon(Icons.graphic_eq, color: plum),
                ),
                title: Text(
                  dream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${dreamDate(dream.createdAt)}\n${audioDuration(Duration(milliseconds: dream.durationMs))} · Salvato qui',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _recording?.active == true
                    ? null
                    : () => _openDream(dream),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recordCard() {
    final recorder = _recording!;
    final active = recorder.active;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF342B48), Color(0xFF655078)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: Color(0xFFF1D7AB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active ? 'IL TUO RACCONTO' : 'UN POSTO PER I TUOI SOGNI',
                  style: const TextStyle(
                    color: Color(0xFFE7DDF0),
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            active ? audioDuration(recorder.elapsed) : 'Che cosa hai sognato?',
            style: TextStyle(
              color: Colors.white,
              fontSize: active ? 42 : 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(switch (recorder.stage) {
            RecordingStage.idle => 'Raccontalo a voce. Lo ritroverai qui.',
            RecordingStage.recording => 'Ti sto ascoltando…',
            RecordingStage.paused => 'In pausa. Riprendi quando vuoi.',
            RecordingStage.saving => 'Sto salvando il tuo sogno…',
            RecordingStage.retrySave =>
              'L’audio è fermo. Riprova il salvataggio.',
          }, style: const TextStyle(color: Color(0xFFE7DDF0))),
          const SizedBox(height: 22),
          if (!active)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF1D7AB),
                  foregroundColor: ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: recorder.busy ? null : recorder.start,
                icon: const Icon(Icons.mic),
                label: Text(
                  recorder.busy ? 'Apertura microfono…' : 'Racconta un sogno',
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (recorder.stage == RecordingStage.recording ||
                    recorder.stage == RecordingStage.paused)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white60),
                    ),
                    onPressed: recorder.busy ? null : recorder.togglePause,
                    icon: Icon(
                      recorder.stage == RecordingStage.paused
                          ? Icons.mic
                          : Icons.pause,
                    ),
                    label: Text(
                      recorder.stage == RecordingStage.paused
                          ? 'Riprendi'
                          : 'Pausa',
                    ),
                  ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF1D7AB),
                    foregroundColor: ink,
                  ),
                  onPressed: recorder.busy ? null : _finish,
                  icon: recorder.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    recorder.stage == RecordingStage.retrySave
                        ? 'Riprova a salvare'
                        : 'Termina e salva',
                  ),
                ),
              ],
            ),
          if (recorder.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                recorder.error!,
                style: const TextStyle(color: Color(0xFFFFD4D4)),
              ),
            ),
        ],
      ),
    );
  }
}

class DreamDetail extends StatefulWidget {
  const DreamDetail({
    super.key,
    required this.dream,
    required this.repository,
    this.transcription,
    this.onSaved,
    this.sharedArchive,
  });
  final Dream dream;
  final DreamRepository repository;
  final VoidCallback? onSaved;
  final TranscriptionManager? transcription;
  final ArchiveManager? sharedArchive;
  @override
  State<DreamDetail> createState() => _DreamDetailState();
}

class _DreamDetailState extends State<DreamDetail> {
  AudioPlayer? _player;
  late final TextEditingController _title, _text;
  late Dream _saved;
  bool _saving = false,
      _playingBusy = false,
      _leaving = false,
      _deleting = false;
  String? _audioError;
  Dream? _appliedTranscript;
  bool get _dirty =>
      _title.text.trim() != _saved.title ||
      _text.text.trim() != _saved.transcript;
  @override
  void initState() {
    super.initState();
    _saved = widget.dream;
    _title = TextEditingController(text: _saved.title)..addListener(_changed);
    _text = TextEditingController(text: _saved.transcript)
      ..addListener(_changed);
    widget.transcription?.addListener(_transcriptionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.transcription != null) {
        _transcriptionChanged();
        unawaited(widget.transcription!.run(_saved));
      }
    });
  }

  void _transcriptionChanged() {
    if (!mounted) return;
    final incoming = widget.transcription?.results[_saved.id];
    if (incoming != null && !identical(incoming, _appliedTranscript)) {
      final hasLocalTextChanges = _text.text.trim() != _saved.transcript;
      _appliedTranscript = incoming;
      _saved = _saved.withAutomaticTranscript(
        incoming.automaticTranscript ?? incoming.transcript,
      );
      if (!hasLocalTextChanges) _text.text = _saved.transcript;
    }
    setState(() {});
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _play() async {
    if (_playingBusy) return;
    final player = _player ??= AudioPlayer();
    if (player.playing) {
      await player.pause();
      return;
    }
    setState(() {
      _playingBusy = true;
      _audioError = null;
    });
    try {
      if (player.audioSource == null) {
        await player.setUrl(storage.playbackUrl(_saved.audio));
      }
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      unawaited(
        player.play().catchError((Object error) {
          if (mounted) {
            setState(() {
              _audioError = 'Non riesco a riprodurre questo audio.';
            });
          }
        }),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _audioError = 'Non riesco ad aprire questo audio.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _playingBusy = false;
        });
      }
    }
  }

  Future<bool> _save() async {
    if (_saving || _deleting) return false;
    setState(() {
      _saving = true;
    });
    try {
      final edited = _saved.edited(
        title: _title.text.trim().isEmpty
            ? defaultTitle(_saved.createdAt)
            : _title.text,
        transcript: _text.text,
      );
      await widget.repository.save(edited);
      if (!mounted) return false;
      setState(() {
        _saved = edited;
      });
      _title.text = edited.title;
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Modifiche non salvate. Mantieni aperta la schermata e riprova.',
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _leave() async {
    if (_leaving || _saving || _deleting) return;
    _leaving = true;
    if (_dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Salvare le modifiche?'),
          content: const Text('Hai modificato il titolo o il testo del sogno.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'stay'),
              child: const Text('Resta qui'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Non salvare'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Salva'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == null ||
          choice == 'stay' ||
          (choice == 'save' && !await _save())) {
        _leaving = false;
        return;
      }
    }
    if (mounted) Navigator.pop(context, _saved);
  }

  Future<void> _delete() async {
    if (_saving || _deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare questo sogno?'),
        content: const Text(
          'Audio, titolo e trascrizioni saranno cancellati. '
          'Se usi una cartella condivisa, la cancellazione verrà trasferita alla prossima sincronizzazione. Non puoi annullare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deleting = true;
    });
    try {
      if (_player?.audioSource != null) await _player!.stop();
      if (widget.sharedArchive != null) {
        await widget.sharedArchive!.removeDream(_saved.id);
      } else {
        await widget.repository.markDeleted(_saved.id);
        await widget.transcription?.forget(_saved.id);
        await storage.deleteAudio(_saved.audio);
        await widget.repository.finishDeletion(_saved.id);
      }
      if (!mounted) return;
      widget.onSaved?.call();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sogno eliminato.')));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cancellazione non completata. Attendi eventuali elaborazioni e riprova.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    widget.transcription?.removeListener(_transcriptionChanged);
    unawaited(_player?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_leave());
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Il tuo sogno'),
        actions: [
          IconButton(
            tooltip: 'Elimina sogno',
            onPressed: _saving || _deleting ? null : _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: _leave,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                dreamDate(_saved.createdAt),
                style: const TextStyle(color: plum),
              ),
              if (_deleting) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const Text(
                  'Eliminazione in corso. Attendo eventuali trascrizioni attive.',
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Titolo del sogno',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE8F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        StreamBuilder<PlayerState>(
                          stream: _player?.playerStateStream,
                          builder: (context, snapshot) => IconButton.filled(
                            tooltip: _player?.playing == true
                                ? 'Pausa audio'
                                : 'Ascolta audio',
                            onPressed: _playingBusy || _deleting ? null : _play,
                            icon: _playingBusy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _player?.playing == true
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Il racconto originale',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          audioDuration(
                            Duration(milliseconds: _saved.durationMs),
                          ),
                        ),
                      ],
                    ),
                    StreamBuilder<Duration>(
                      stream: _player?.positionStream,
                      builder: (context, snapshot) {
                        final total =
                            _player?.duration?.inMilliseconds ??
                            _saved.durationMs;
                        final value = (snapshot.data?.inMilliseconds ?? 0)
                            .clamp(0, total > 0 ? total : 1);
                        return Slider(
                          min: 0,
                          max: (total > 0 ? total : 1).toDouble(),
                          value: value.toDouble(),
                          label: audioDuration(Duration(milliseconds: value)),
                          onChanged: _player?.audioSource == null
                              ? null
                              : (value) => _player!.seek(
                                  Duration(milliseconds: value.round()),
                                ),
                        );
                      },
                    ),
                    if (_audioError != null)
                      Text(
                        _audioError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Il sogno, in parole',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.transcription != null)
                TranscriptionCard(
                  manager: widget.transcription!,
                  dreamId: _saved.id,
                  onReady: () => unawaited(widget.transcription!.run(_saved)),
                  onRetry: () =>
                      unawaited(widget.transcription!.run(_saved, retry: true)),
                ),
              const Text(
                'Il testo è modificabile ed è incluso nella ricerca.',
                style: TextStyle(color: plum),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _text,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText:
                      'Personaggi, luoghi, frammenti… scrivi ciò che ricordi.',
                ),
              ),
              if (_saved.automaticTranscript != null)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Testo automatico originale'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        _saved.automaticTranscript!.isEmpty
                            ? 'Non sono state rilevate parole nell’audio.'
                            : _saved.automaticTranscript!,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _saving || _deleting
                    ? null
                    : () async {
                        if (await _save() && context.mounted) {
                          widget.onSaved?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sogno salvato.')),
                          );
                          Navigator.pop(context, _saved);
                        }
                      },
                icon: const Icon(Icons.check),
                label: Text(_saving ? 'Salvataggio…' : 'Salva sogno'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: plum),
                  const SizedBox(width: 6),
                  Text(
                    widget.sharedArchive?.folderLabel == null
                        ? 'Sul tuo dispositivo'
                        : 'Copia locale e cartella collegata',
                    style: const TextStyle(color: plum),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.transcription,
    required this.sharedArchive,
    required this.onSynced,
  });
  final TranscriptionManager transcription;
  final ArchiveManager sharedArchive;
  final Future<void> Function() onSynced;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Text(
        'Il tuo spazio personale',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: ink),
      ),
      const SizedBox(height: 20),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: plum),
              SizedBox(height: 12),
              Text(
                'Salvataggio locale',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Audio e testi restano disponibili su questo dispositivo. Puoi collegare una cartella condivisa. Non vengono inviati a servizi di IA.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        kIsWeb
            ? 'Nel browser, cancellare i dati del sito elimina anche l’archivio. La modalità privata non è adatta a conservare i sogni.'
            : 'Disinstallare l’app o cancellarne i dati elimina l’archivio locale. Sincronizza prima con la cartella condivisa per conservarne una copia.',
      ),
      const SizedBox(height: 20),
      ArchiveCard(manager: sharedArchive, onSynced: onSynced),
      const SizedBox(height: 26),
      TranscriptionCard(manager: transcription),
      const SizedBox(height: 20),
      const Text(
        'Nelle prossime fasi',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.cloud_outlined),
        title: Text('Accesso diretto al cloud'),
        subtitle: Text(
          'Collegamento con account Google Drive o Dropbox, anche quando il servizio non espone una cartella.',
        ),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.psychology_outlined),
        title: Text('IA esterna facoltativa'),
        subtitle: Text('Collegamento a un servizio scelto da te.'),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.auto_awesome_outlined),
        title: Text('Riepiloghi dei sogni'),
        subtitle: Text('Su richiesta, per settimana, mese o periodo scelto.'),
      ),
      const SizedBox(height: 16),
      const Text(
        'Versione di prova 0.4.2 · Nessun promemoria',
        style: TextStyle(color: plum),
      ),
    ],
  );
}
