import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../ai/engine.dart';
import '../../data/lessons.dart';

String _pronunciationPrompt(String target) =>
    '''
The learner is practising Spanish pronunciation. They were asked to say: "$target"
Listen to the recording. Reply with ONLY a JSON object, no other text:
{"heard": "<exactly what you heard, in Spanish>", "tip": "<one short tip in English about the sounds they got wrong, or praise if it was right>"}''';

class PronunciationScreen extends ConsumerStatefulWidget {
  const PronunciationScreen({super.key});

  @override
  ConsumerState<PronunciationScreen> createState() =>
      _PronunciationScreenState();
}

class _PronunciationScreenState extends ConsumerState<PronunciationScreen> {
  final _recorder = AudioRecorder();
  final _rng = Random();
  late final List<String> _phrases = [
    for (final l in lessons)
      for (final i in l.items)
        if (!i.es.contains('…') && !i.es.contains('/')) i.es,
  ];
  late String _target = _phrases[_rng.nextInt(_phrases.length)];

  bool _recording = false;
  bool _busy = false;
  _Result? _result;
  String? _error;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  void _nextPhrase() => setState(() {
    _target = _phrases[_rng.nextInt(_phrases.length)];
    _result = null;
    _error = null;
  });

  Future<void> _toggle() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) await _evaluate(File(path));
      return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'Microphone permission is needed.');
      return;
    }
    final dir = await getTemporaryDirectory();
    await _recorder.start(
      // The model expects a complete 16 kHz mono WAV file.
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '${dir.path}/attempt.wav',
    );
    setState(() {
      _recording = true;
      _result = null;
      _error = null;
    });
  }

  Future<void> _evaluate(File wav) async {
    setState(() => _busy = true);
    try {
      final bytes = await wav.readAsBytes();
      final reply = await ref
          .read(engineProvider)
          .ask(_pronunciationPrompt(_target), wavAudio: bytes);
      final json = extractJson(reply);
      String heard = reply.trim();
      String tip = '';
      if (json != null) {
        try {
          final m = jsonDecode(json) as Map<String, dynamic>;
          heard = (m['heard'] as String?)?.trim() ?? heard;
          tip = (m['tip'] as String?)?.trim() ?? '';
        } catch (_) {}
      }
      setState(() => _result = _Result(heard, tip, matchScore(_target, heard)));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pronunciation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Say this out loud:',
              style: t.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _target,
                  style: t.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _recording || _busy ? null : _nextPhrase,
              icon: const Icon(Icons.shuffle),
              label: const Text('Another phrase'),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _busy ? null : _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _recording ? 110 : 96,
                  height: _recording ? 110 : 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _recording ? scheme.error : scheme.primary,
                  ),
                  child: Icon(
                    _recording ? Icons.stop : Icons.mic,
                    color: scheme.onPrimary,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _recording
                  ? 'Recording… tap to stop'
                  : _busy
                  ? 'Escuchando…'
                  : 'Tap to record',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Text(_error!, style: TextStyle(color: scheme.error)),
            if (_result != null) _ResultCard(result: _result!),
          ],
        ),
      ),
    );
  }
}

class _Result {
  _Result(this.heard, this.tip, this.score);
  final String heard;
  final String tip;
  final double score;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final _Result result;

  @override
  Widget build(BuildContext context) {
    final pct = (result.score * 100).round();
    final (emoji, label) = switch (pct) {
      >= 90 => ('🌟', '¡Perfecto!'),
      >= 70 => ('👍', '¡Muy bien!'),
      >= 40 => ('🙂', 'Casi…'),
      _ => ('🔁', 'Inténtalo otra vez'),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$emoji $label · $pct%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('I heard: "${result.heard}"'),
            if (result.tip.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('💡 ${result.tip}'),
            ],
          ],
        ),
      ),
    );
  }
}

/// Word-level similarity between the target and what was heard (0–1),
/// ignoring case, accents and punctuation.
double matchScore(String target, String heard) {
  List<String> words(String s) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  final a = words(target), b = words(heard);
  if (a.isEmpty || b.isEmpty) return 0;
  // Longest common subsequence of words.
  final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1]
          ? dp[i - 1][j - 1] + 1
          : max(dp[i - 1][j], dp[i][j - 1]);
    }
  }
  return dp[a.length][b.length] / max(a.length, b.length);
}
