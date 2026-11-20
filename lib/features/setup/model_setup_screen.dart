import 'package:flutter/material.dart';

import '../../ai/engine.dart';

/// First-run screen: downloads Gemma 4 E2B (~2.5 GB) once. After that the
/// app works fully offline.
class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  int? _progress;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      await SpanishEngine.instance.install((p) {
        if (mounted) setState(() => _progress = p);
      });
      widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final downloading = _progress != null;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🇪🇸',
                style: TextStyle(fontSize: 64),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '¡Hablemos!',
                style: t.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your Spanish tutor runs entirely on this phone. '
                'It needs a one-time download of the AI model (about 2.5 GB). '
                'Use Wi-Fi. After that, everything works offline and private.',
                style: t.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (downloading) ...[
                LinearProgressIndicator(value: _progress! / 100),
                const SizedBox(height: 8),
                Text('Downloading… $_progress%', textAlign: TextAlign.center),
              ] else
                FilledButton.icon(
                  onPressed: _download,
                  icon: const Icon(Icons.download),
                  label: const Text('Download the tutor'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Download failed: $_error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Needs a phone with 6 GB+ RAM and Android 11 or newer.',
                style: t.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
