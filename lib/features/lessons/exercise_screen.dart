import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/engine.dart';
import '../../data/lessons.dart';

String _exercisePrompt(Lesson lesson) =>
    '''
Create 5 fill-in-the-blank Spanish exercises for an English-speaking beginner.
Topic: ${lesson.title} (${lesson.summary}).
Use these words: ${lesson.items.map((i) => i.es).join(', ')}.
Each exercise is one short Spanish sentence with exactly one blank written as ___.
Reply with ONLY a JSON array, no other text, like:
[{"sentence": "___ días, señora.", "answer": "Buenos", "translation": "Good morning, ma'am."}]''';

class _Exercise {
  _Exercise(this.sentence, this.answer, this.translation);
  final String sentence;
  final String answer;
  final String translation;
}

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  List<_Exercise>? _items;
  String? _error;
  int _i = 0;
  int _score = 0;
  bool? _correct;
  final _answer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _items = null;
      _error = null;
      _i = 0;
      _score = 0;
      _correct = null;
    });
    try {
      final reply = await ref
          .read(engineProvider)
          .ask(_exercisePrompt(widget.lesson));
      final json = extractJson(reply);
      final list = json == null ? const [] : jsonDecode(json) as List;
      final items = [
        for (final e in list)
          if (e is Map &&
              e['sentence'] is String &&
              e['answer'] is String &&
              (e['sentence'] as String).contains('___'))
            _Exercise(
              e['sentence'] as String,
              e['answer'] as String,
              (e['translation'] as String?) ?? '',
            ),
      ];
      if (items.isEmpty) throw const FormatException('No exercises came back');
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = "Couldn't make exercises: $e");
    }
  }

  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[¿?¡!.,]'), '').trim();

  void _check() {
    final ok = _norm(_answer.text) == _norm(_items![_i].answer);
    setState(() {
      _correct = ok;
      if (ok) _score++;
    });
  }

  void _next() {
    _answer.clear();
    setState(() {
      _i++;
      _correct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final items = _items;
    Widget body;
    if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _generate, child: const Text('Try again')),
          ],
        ),
      );
    } else if (items == null) {
      body = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Preparando ejercicios…'),
          ],
        ),
      );
    } else if (_i >= items.length) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_score / ${items.length}', style: t.displaySmall),
            const SizedBox(height: 16),
            FilledButton(onPressed: _generate, child: const Text('New set')),
          ],
        ),
      );
    } else {
      final ex = items[_i];
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${_i + 1} / ${items.length}', style: t.labelLarge),
            const SizedBox(height: 16),
            Text(ex.sentence, style: t.headlineSmall),
            if (ex.translation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(ex.translation, style: t.bodyMedium),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _answer,
              enabled: _correct == null,
              autofocus: true,
              onSubmitted: (_) => _correct == null ? _check() : null,
              decoration: const InputDecoration(
                labelText: 'Fill the blank',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_correct != null)
              Text(
                _correct! ? '✅ ¡Correcto!' : '❌ Answer: ${ex.answer}',
                style: t.titleMedium,
              ),
            const Spacer(),
            FilledButton(
              onPressed: _correct == null ? _check : _next,
              child: Text(_correct == null ? 'Check' : 'Next'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lesson.emoji} Exercises')),
      body: body,
    );
  }
}
