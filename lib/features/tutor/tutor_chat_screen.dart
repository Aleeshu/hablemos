import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/engine.dart';
import '../../data/flashcards.dart';

enum Level { beginner, intermediate, advanced }

String tutorInstructions(Level level, {String? topic}) =>
    '''
You are Profe, a friendly Spanish tutor chatting with an English speaker.
Learner level: ${level.name}.
${topic != null ? 'Today\'s topic: $topic.\n' : ''}Rules:
- Reply mostly in Spanish, kept short (1-3 sentences) and suited to the level. For beginners, add an English translation in parentheses.
- If the learner's last message had Spanish mistakes, start with "✏️ Corrección:" giving the corrected sentence and a one-line English explanation. If there were no mistakes, skip this.
- Keep the conversation going with one question at the end.
- On the very last line, list up to 3 useful new words from your reply in the form:
VOCAB: palabra = word; otra palabra = other word
Start the conversation now by greeting the learner.''';

class _Msg {
  _Msg(this.fromUser, this.text);
  final bool fromUser;
  String text;
  List<(String, String)> vocab = const [];
}

class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key, this.topic});

  /// Optional lesson topic to steer the conversation.
  final String? topic;

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Msg>[];
  TutorChat? _chat;
  Level _level = Level.beginner;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _chat?.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _chat?.close();
    setState(() {
      _messages.clear();
      _error = null;
    });
    try {
      _chat = await ref
          .read(engineProvider)
          .openChat(tutorInstructions(_level, topic: widget.topic));
      await _stream('¡Hola!', showUser: false);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy || _chat == null) return;
    _input.clear();
    await _stream(text);
  }

  Future<void> _stream(String text, {bool showUser = true}) async {
    final reply = _Msg(false, '');
    setState(() {
      _busy = true;
      if (showUser) _messages.add(_Msg(true, text));
      _messages.add(reply);
    });
    try {
      await for (final token in _chat!.send(text)) {
        reply.text += token;
        setState(() {});
        _scrollDown();
      }
      final (body, vocab) = splitVocab(reply.text);
      setState(() {
        reply.text = body;
        reply.vocab = vocab;
      });
    } catch (e) {
      setState(() => reply.text = '⚠️ $e');
    } finally {
      setState(() => _busy = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _save((String, String) word) {
    final added = ref.read(flashcardsProvider.notifier).addAll([
      Flashcard(es: word.$1, en: word.$2, source: 'tutor'),
    ]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? 'Added "${word.$1}" to flashcards'
              : '"${word.$1}" is already in your deck',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final started = _chat != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic == null ? 'Tutor' : 'Tutor · ${widget.topic}'),
        actions: [
          if (started)
            IconButton(
              tooltip: 'New conversation',
              onPressed: _busy ? null : _start,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: !started
          ? _StartPanel(
              level: _level,
              error: _error,
              onLevel: (l) => setState(() => _level = l),
              onStart: _start,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: m.fromUser
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.text.isEmpty ? '…' : m.text),
                              if (m.vocab.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final w in m.vocab)
                                      ActionChip(
                                        avatar: const Icon(Icons.add, size: 16),
                                        label: Text('${w.$1} · ${w.$2}'),
                                        onPressed: () => _save(w),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: 'Escribe en español…',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _busy ? null : _send,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({
    required this.level,
    required this.onLevel,
    required this.onStart,
    this.error,
  });

  final Level level;
  final ValueChanged<Level> onLevel;
  final VoidCallback onStart;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧑‍🏫', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Chat with Profe',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Write in Spanish. Profe answers, corrects your mistakes, '
              'and suggests new words for your flashcards.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SegmentedButton<Level>(
              segments: const [
                ButtonSegment(value: Level.beginner, label: Text('Beginner')),
                ButtonSegment(
                  value: Level.intermediate,
                  label: Text('Intermediate'),
                ),
                ButtonSegment(value: Level.advanced, label: Text('Advanced')),
              ],
              selected: {level},
              onSelectionChanged: (s) => onLevel(s.first),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onStart, child: const Text('¡Empezar!')),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Splits the trailing "VOCAB: a = b; c = d" line off a tutor reply.
(String, List<(String, String)>) splitVocab(String reply) {
  final idx = reply.lastIndexOf(RegExp(r'VOCAB:', caseSensitive: false));
  if (idx < 0) return (reply.trim(), const []);
  final body = reply.substring(0, idx).trim();
  final words = <(String, String)>[];
  for (final part in reply.substring(idx + 6).split(RegExp(r'[;\n]'))) {
    final kv = part.split('=');
    if (kv.length != 2) continue;
    final es = kv[0].replaceAll('*', '').trim();
    final en = kv[1].replaceAll('*', '').trim();
    if (es.isNotEmpty && en.isNotEmpty) words.add((es, en));
  }
  return (body, words);
}
