import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/engine.dart';
import 'features/lessons/lessons_screen.dart';
import 'features/photo/photo_vocab_screen.dart';
import 'features/pronunciation/pronunciation_screen.dart';
import 'features/setup/model_setup_screen.dart';
import 'features/tutor/tutor_chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterEdgeAi.initialize(inferenceEngines: const [LiteRtLmEngine()]);
  runApp(const ProviderScope(child: HablemosApp()));
}

class HablemosApp extends StatelessWidget {
  const HablemosApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFE4572E); // warm terracotta
    return MaterialApp(
      title: 'Hablemos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _Gate(),
    );
  }
}

/// Shows the download screen until the model is on the device.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool? _installed;

  @override
  void initState() {
    super.initState();
    SpanishEngine.instance.isInstalled().then((v) {
      if (mounted) setState(() => _installed = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_installed) {
      null => const Scaffold(body: Center(child: CircularProgressIndicator())),
      false => ModelSetupScreen(
        onDone: () => setState(() => _installed = true),
      ),
      true => const HomeShell(),
    };
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _pages = [
    LessonsScreen(),
    TutorChatScreen(),
    PhotoVocabScreen(),
    PronunciationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera),
            label: 'Photo',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Speak',
          ),
        ],
      ),
    );
  }
}
