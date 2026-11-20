# Hablemos — on-device Spanish tutor

A Spanish-learning app modelled on Google's
[AI Edge Gallery](https://github.com/google-ai-edge/gallery): an AI model
(Gemma 4 E2B) runs entirely on the phone, so after a one-time ~2.5 GB download
it works offline and nothing you say or photograph leaves the device.

Flutter + [`flutter_edge_ai`](https://pub.dev/packages/flutter_edge_ai)
(the successor to `flutter_gemma`) with the LiteRT-LM engine.

## Features

| Tab | What it does | Gallery equivalent |
|---|---|---|
| **Learn** | 6 built-in lessons (greetings, food, numbers, travel, verbs, family), AI-generated fill-in-the-blank exercises, spaced-repetition flashcards | — |
| **Tutor** | Chat in Spanish with "Profe" at your level; corrects mistakes, suggests words to save as flashcards | AI Chat |
| **Photo** | Snap a photo, get the Spanish words for what's in it, save them or take a quiz | Ask Image |
| **Speak** | Say a phrase, the model transcribes what it heard and scores it, with a tip | Audio Scribe |

## Layout

```
lib/
  ai/engine.dart                 model download/load, chat + one-shot prompts
  data/lessons.dart              lesson content
  data/flashcards.dart           SM-2 flashcard deck (shared_preferences)
  features/setup/                first-run model download
  features/tutor/                conversation tutor
  features/photo/                photo vocabulary + quiz
  features/pronunciation/        record 16 kHz WAV, transcribe, score
  features/lessons/              lessons, exercises, flashcard review
```

## Building

The Windows username contains a space, which breaks Flutter's native-assets
hook, so build through the mirror script (copies to `C:\hablemos-build`):

```powershell
.\scripts\build-apk.ps1            # debug APK -> builds\
.\scripts\build-apk.ps1 -Install   # and install on a connected phone
```

## Requirements

- Android 11+ (minSdk 30), arm64 phone, **6 GB+ RAM** for Gemma 4 E2B.
- The emulator won't run the model usefully; test on a real phone.
