# Ludo Supreme (Project3)

A full-featured, beautiful, and authentic Ludo board game built with **Flutter**.

## 🎲 Features

- **Standard 15x15 Ludo Board**: Classic Red, Green, Yellow, and Blue bases, 52-cell outer track, colored home stretches, and multi-triangle center finish goal.
- **8 Safe Zones (Stars)**: Tokens on starting positions and designated star tiles cannot be captured.
- **Authentic Game Rules**:
  - Requires rolling a **6** to bring pawns out of base.
  - Extra rolls on rolling 6, capturing an opponent's pawn, or reaching the home goal.
  - 3-Sixes penalty rule.
  - Step-by-step pawn movement animations with smart stacking when multiple tokens share a tile.
- **Multiple Game Modes**:
  - 🤖 **Play vs Computer**: Single player mode against an intelligent heuristic AI bot.
  - 👥 **2 Players Match**: 1v1 local Pass & Play.
  - 👨‍👩‍👧‍👦 **4 Players Classic**: Full 4-player multiplayer arena.
- **3D Animated Dice & Pawns**:
  - Realistic rolling dice with bounce physics and pip dots.
  - 3D glossy pawns with pulsating glow animations when movable.
- **Splash Screen & Authentication**:
  - Animated splash screen with 3D logo.
  - Login & SignUp screens with input validation.
  - Persistent login session using `SharedPreferences`.
  - 1-tap "Auto Fill" demo credentials (`admin@ludo.com` / `password123`) and "Play as Guest".
  - In-app Logout support.

## 🚀 How to Run

Navigate to the project folder:
```bash
cd C:\Dart\Variables\Flutter\ludo
```

Run on Chrome (Web):
```bash
flutter run -d chrome
```

Run on Windows Desktop:
```bash
flutter run -d windows
```

Run on Android emulator/device:
```bash
flutter run
```

## 🧪 Running Tests

Run the full automated test suite:
```bash
flutter test
```

Analyze code:
```bash
dart analyze lib
```
