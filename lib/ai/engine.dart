import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the on-device model. Gemma 4 E2B handles text, images and audio, so
/// one model powers the tutor, photo vocabulary and pronunciation features.
///
/// Everything runs on the phone; nothing is sent to a server after the
/// one-time model download.
class SpanishEngine {
  SpanishEngine._();
  static final instance = SpanishEngine._();

  static final modelSpec = LiteRtLmModels.gemma4E2bIt.generic;

  InferenceModel? _model;
  Future<InferenceModel>? _loading;

  Future<bool> isInstalled() =>
      FlutterEdgeAi.isModelInstalled(modelSpec.file.installFilename);

  /// Downloads the model, reporting progress 0–100.
  Future<void> install(void Function(int percent) onProgress) {
    return FlutterEdgeAi.installModelFromCatalog(modelSpec)
        .withProgress(onProgress)
        .install();
  }

  Future<InferenceModel> _ensureModel() {
    if (_model != null) return Future.value(_model);
    return _loading ??= () async {
      final m = await FlutterEdgeAi.getActiveModel(
        defaults: modelSpec.runtimeDefaults,
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
        supportImage: true,
        supportAudio: true,
      );
      _model = m;
      return m;
    }();
  }

  /// Opens a chat primed with [instructions]. Each feature gets its own chat
  /// so their histories don't mix.
  Future<TutorChat> openChat(String instructions) async {
    final model = await _ensureModel();
    final chat = await model.openChat(supportImage: true, supportAudio: true);
    return TutorChat._(chat, instructions);
  }

  /// One-shot request with a fresh context; used for structured tasks
  /// (photo labelling, pronunciation scoring, exercise generation).
  Future<String> ask(
    String prompt, {
    Uint8List? image,
    Uint8List? wavAudio,
  }) async {
    final chat = await openChat('');
    try {
      return await chat.send(prompt, image: image, wavAudio: wavAudio).join();
    } finally {
      await chat.close();
    }
  }
}

class TutorChat {
  TutorChat._(this._chat, this._instructions);

  final InferenceChat _chat;
  final String _instructions;
  bool _primed = false;

  /// Streams the reply token by token.
  Stream<String> send(
    String text, {
    Uint8List? image,
    Uint8List? wavAudio,
  }) async* {
    // Gemma has no separate system role, so the instructions ride along with
    // the first user turn.
    final prompt = !_primed && _instructions.isNotEmpty
        ? '$_instructions\n\n$text'
        : text;
    _primed = true;

    final Message message;
    if (image != null) {
      message = Message.withImages(
        text: prompt,
        imageBytes: [image],
        isUser: true,
      );
    } else if (wavAudio != null) {
      message = Message.withAudio(
        text: prompt,
        audioBytes: wavAudio,
        isUser: true,
      );
    } else {
      message = Message.text(text: prompt, isUser: true);
    }

    await _chat.addQueryChunk(message);
    await for (final r in _chat.generateChatResponseAsync()) {
      if (r is TextResponse) yield r.token;
    }
  }

  Future<void> close() async {
    try {
      await _chat.close();
    } catch (_) {}
  }
}

final engineProvider = Provider((_) => SpanishEngine.instance);

/// Pulls the first JSON object or array out of a model reply, which may wrap
/// it in prose or a ```json fence.
String? extractJson(String reply) {
  final starts = [
    reply.indexOf('{'),
    reply.indexOf('['),
  ].where((i) => i >= 0).toList()..sort();
  if (starts.isEmpty) return null;
  final start = starts.first;
  final close = reply[start] == '{' ? '}' : ']';
  final end = reply.lastIndexOf(close);
  if (end <= start) return null;
  return reply.substring(start, end + 1);
}
