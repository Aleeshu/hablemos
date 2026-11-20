import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/flashcards.dart';

/// Reviews due cards: see the Spanish, recall the English, flip, grade.
class FlashcardReviewScreen extends ConsumerStatefulWidget {
  const FlashcardReviewScreen({super.key});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen> {
  late final List<Flashcard> _queue =
      ref.read(flashcardsProvider).where((c) => c.isDue).toList()..shuffle();
  int _i = 0;
  bool _flipped = false;

  void _grade(int g) {
    ref.read(flashcardsProvider.notifier).review(_queue[_i], g);
    setState(() {
      // "Again" puts the card back at the end of this session.
      if (g == 0) _queue.add(_queue[_i]);
      _i++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_i >= _queue.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✅', style: TextStyle(fontSize: 56)),
              Text('¡Todo hecho!', style: t.headlineMedium),
              const Text('No more cards due right now.'),
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
    final card = _queue[_i];
    return Scaffold(
      appBar: AppBar(title: Text('${_queue.length - _i} left')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _flipped = true),
                child: Card(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.es,
                            style: t.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (_flipped)
                            Text(
                              card.en,
                              style: t.headlineSmall,
                              textAlign: TextAlign.center,
                            )
                          else
                            Text('Tap to reveal', style: t.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_flipped)
              Row(
                children: [
                  for (final (g, label, color) in [
                    (0, 'Again', Colors.red),
                    (1, 'Hard', Colors.orange),
                    (2, 'Good', Colors.green),
                    (3, 'Easy', Colors.blue),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: color),
                          onPressed: () => _grade(g),
                          child: Text(label),
                        ),
                      ),
                    ),
                ],
              )
            else
              FilledButton(
                onPressed: () => setState(() => _flipped = true),
                child: const Text('Show answer'),
              ),
          ],
        ),
      ),
    );
  }
}
