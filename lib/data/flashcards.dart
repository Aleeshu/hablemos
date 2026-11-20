import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A flashcard scheduled with a simplified SM-2 algorithm.
class Flashcard {
  Flashcard({
    required this.es,
    required this.en,
    required this.source,
    this.interval = 0,
    this.ease = 2.5,
    this.reps = 0,
    DateTime? due,
  }) : due = due ?? DateTime.now();

  final String es;
  final String en;

  /// Where the card came from: a lesson id, "photo", or "tutor".
  final String source;
  int interval; // days
  double ease;
  int reps;
  DateTime due;

  String get key => es.toLowerCase().trim();

  bool get isDue => !due.isAfter(DateTime.now());

  /// grade: 0 = again, 1 = hard, 2 = good, 3 = easy.
  void review(int grade) {
    if (grade == 0) {
      reps = 0;
      interval = 0;
      ease = (ease - 0.2).clamp(1.3, 3.0);
      due = DateTime.now().add(const Duration(minutes: 1));
      return;
    }
    reps++;
    ease = (ease + [0.0, -0.15, 0.0, 0.15][grade]).clamp(1.3, 3.0);
    if (reps == 1) {
      interval = grade == 3 ? 4 : 1;
    } else if (reps == 2) {
      interval = grade == 3 ? 7 : 3;
    } else {
      final factor = grade == 1 ? 1.2 : (grade == 3 ? ease * 1.3 : ease);
      interval = (interval * factor).round().clamp(1, 365);
    }
    due = DateTime.now().add(Duration(days: interval));
  }

  Map<String, dynamic> toJson() => {
    'es': es,
    'en': en,
    'source': source,
    'interval': interval,
    'ease': ease,
    'reps': reps,
    'due': due.toIso8601String(),
  };

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
    es: j['es'] as String,
    en: j['en'] as String,
    source: j['source'] as String? ?? 'unknown',
    interval: j['interval'] as int? ?? 0,
    ease: (j['ease'] as num?)?.toDouble() ?? 2.5,
    reps: j['reps'] as int? ?? 0,
    due: DateTime.tryParse(j['due'] as String? ?? ''),
  );
}

class FlashcardDeck extends Notifier<List<Flashcard>> {
  static const _prefsKey = 'flashcards_v1';

  @override
  List<Flashcard> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
        .toList();
    state = list;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(state.map((c) => c.toJson()).toList()),
    );
  }

  bool contains(String es) =>
      state.any((c) => c.key == es.toLowerCase().trim());

  /// Adds cards that aren't already in the deck. Returns how many were new.
  int addAll(Iterable<Flashcard> cards) {
    final existing = state.map((c) => c.key).toSet();
    final fresh = <Flashcard>[];
    for (final c in cards) {
      if (existing.add(c.key)) fresh.add(c);
    }
    if (fresh.isEmpty) return 0;
    state = [...state, ...fresh];
    _save();
    return fresh.length;
  }

  void review(Flashcard card, int grade) {
    card.review(grade);
    state = [...state];
    _save();
  }

  void remove(Flashcard card) {
    state = state.where((c) => c.key != card.key).toList();
    _save();
  }
}

final flashcardsProvider = NotifierProvider<FlashcardDeck, List<Flashcard>>(
  FlashcardDeck.new,
);
