import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../ai/engine.dart';
import '../../data/flashcards.dart';

const _photoPrompt = '''
Look at this photo and name up to 8 clearly visible objects in Spanish.
Include the definite article (el/la/los/las) with each noun.
Reply with ONLY a JSON array, no other text, like:
[{"es": "la mesa", "en": "table"}, {"es": "el vaso", "en": "glass"}]''';

class PhotoVocabScreen extends ConsumerStatefulWidget {
  const PhotoVocabScreen({super.key});

  @override
  ConsumerState<PhotoVocabScreen> createState() => _PhotoVocabScreenState();
}

class _PhotoVocabScreenState extends ConsumerState<PhotoVocabScreen> {
  Uint8List? _image;
  List<(String, String)> _words = [];
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _image = bytes;
      _words = [];
      _error = null;
      _busy = true;
    });
    try {
      final reply = await ref
          .read(engineProvider)
          .ask(_photoPrompt, image: bytes);
      final words = parseWordList(reply);
      setState(() {
        _words = words;
        if (words.isEmpty) _error = "Couldn't find objects. Try another photo.";
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _saveAll() {
    final added = ref
        .read(flashcardsProvider.notifier)
        .addAll(
          _words.map((w) => Flashcard(es: w.$1, en: w.$2, source: 'photo')),
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added $added new flashcards')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo vocabulary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_image == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Text('📸', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 12),
                  Text(
                    'Snap your kitchen, your desk, the street. '
                    'Learn the Spanish words for what you see.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(_image!, height: 260, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Mirando la foto…'),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_words.isNotEmpty) ...[
            Card(
              child: Column(
                children: [
                  for (final w in _words)
                    ListTile(
                      title: Text(
                        w.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(w.$2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveAll,
                    icon: const Icon(Icons.style),
                    label: const Text('Save as flashcards'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _words.length < 2
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _PhotoQuiz(words: _words),
                            ),
                          ),
                    icon: const Icon(Icons.quiz),
                    label: const Text('Quiz me'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Parses [{"es": ..., "en": ...}] out of a model reply.
List<(String, String)> parseWordList(String reply) {
  final json = extractJson(reply);
  if (json == null) return [];
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return [
      for (final e in decoded)
        if (e is Map && e['es'] is String && e['en'] is String)
          ((e['es'] as String).trim(), (e['en'] as String).trim()),
    ];
  } catch (_) {
    return [];
  }
}

/// Multiple choice: shown the English word, pick the Spanish.
class _PhotoQuiz extends StatefulWidget {
  const _PhotoQuiz({required this.words});
  final List<(String, String)> words;

  @override
  State<_PhotoQuiz> createState() => _PhotoQuizState();
}

class _PhotoQuizState extends State<_PhotoQuiz> {
  final _rng = Random();
  late final List<(String, String)> _order = [...widget.words]..shuffle(_rng);
  int _i = 0;
  int _score = 0;
  String? _picked;
  late List<String> _options = _optionsFor(0);

  List<String> _optionsFor(int i) {
    final answer = _order[i].$1;
    final others =
        widget.words.map((w) => w.$1).where((w) => w != answer).toList()
          ..shuffle(_rng);
    return [answer, ...others.take(3)]..shuffle(_rng);
  }

  void _choose(String option) {
    if (_picked != null) return;
    setState(() {
      _picked = option;
      if (option == _order[_i].$1) _score++;
    });
  }

  void _next() {
    setState(() {
      _i++;
      _picked = null;
      if (_i < _order.length) _options = _optionsFor(_i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_i >= _order.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _score == _order.length ? '🎉' : '👍',
                style: const TextStyle(fontSize: 56),
              ),
              Text(
                '$_score / ${_order.length}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }
    final answer = _order[_i].$1;
    return Scaffold(
      appBar: AppBar(title: Text('Quiz ${_i + 1}/${_order.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('How do you say…', textAlign: TextAlign.center),
            Text(
              _order[_i].$2,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            for (final o in _options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _picked == null
                        ? null
                        : o == answer
                        ? Colors.green.withValues(alpha: 0.2)
                        : o == _picked
                        ? scheme.errorContainer
                        : null,
                  ),
                  onPressed: () => _choose(o),
                  child: Text(o),
                ),
              ),
            const Spacer(),
            if (_picked != null)
              FilledButton(onPressed: _next, child: const Text('Next')),
          ],
        ),
      ),
    );
  }
}
