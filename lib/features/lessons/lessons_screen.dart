import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/flashcards.dart';
import '../../data/lessons.dart';
import '../tutor/tutor_chat_screen.dart';
import 'exercise_screen.dart';
import 'flashcard_review_screen.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(flashcardsProvider);
    final due = cards.where((c) => c.isDue).length;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('¡Hablemos!')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.style, size: 36),
              title: const Text('Flashcards'),
              subtitle: Text(
                cards.isEmpty
                    ? 'Add words from a lesson, the tutor or a photo'
                    : '$due due now · ${cards.length} in your deck',
              ),
              trailing: FilledButton(
                onPressed: due == 0
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FlashcardReviewScreen(),
                        ),
                      ),
                child: const Text('Review'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Lessons', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final l in lessons)
            Card(
              child: ListTile(
                leading: Text(l.emoji, style: const TextStyle(fontSize: 32)),
                title: Text(l.title),
                subtitle: Text(l.summary),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonDetailScreen(lesson: l),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(flashcardsProvider);
    final deck = ref.read(flashcardsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text('${lesson.emoji} ${lesson.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(lesson.summary, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('AI exercises'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExerciseScreen(lesson: lesson),
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.chat_bubble),
                label: const Text('Practise with tutor'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TutorChatScreen(
                      topic: '${lesson.title} (${lesson.summary})',
                    ),
                  ),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.style),
                label: const Text('Add all to flashcards'),
                onPressed: () {
                  final n = deck.addAll(
                    lesson.items.map(
                      (i) => Flashcard(es: i.es, en: i.en, source: lesson.id),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $n new flashcards')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in lesson.items)
            Card(
              child: ListTile(
                title: Text(
                  item.es,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  item.note == null ? item.en : '${item.en}\n${item.note}',
                ),
                isThreeLine: item.note != null,
                trailing: deck.contains(item.es)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => deck.addAll([
                          Flashcard(
                            es: item.es,
                            en: item.en,
                            source: lesson.id,
                          ),
                        ]),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
