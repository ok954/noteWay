# noteWay (记途)

> A fully offline personal memo app supporting Android phones and Windows PCs.

[![Release](https://img.shields.io/github/v/release/ok954/noteWay-private)](https://github.com/ok954/noteWay-private/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.32.1-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**English** | **[中文](README.md)**

---

## Overview

**noteWay** is a lightweight cross-platform memo app focused on three core principles: **lightweight & practical, privacy & security, multi-device synergy**. All data is stored locally on your device — no account required to use all features.

### Key Features

- **Fully Offline** — Data stored in local SQLite, zero network dependency
- **Dual Platform** — Android phone + Windows PC
- **No Login Required** — Open and use immediately
- **Privacy & Security** — Data never leaves your device
- **Rich Text Editing** — Bold, italic, underline, lists, alignment, inline images

---

## Feature Modules

| Module | Description |
|--------|-------------|
| **Notes** | Rich text editor, inline images, waterfall list, keyword search, cover image |
| **Todos** | Priority (High/Medium/Low), due date, type classification, pin to top, grouped display |
| **Habits** | Forward timer, countdown (with milliseconds), pause/resume/complete, exit & resume, quick add time |
| **Stats** | Home page overview cards (Todos/Habits/Notes), real-time data refresh |
| **Settings** | Dark theme, data import/export (JSON), cloud sync (placeholder), clear all data |

---

## Download & Install

| Platform | Download | Notes |
|----------|----------|-------|
| Windows | [noteWay-windows.zip](https://github.com/ok954/noteWay-private/releases/latest) | Unzip and double-click `memo_app.exe` |
| Android | [noteWay-android.apk](https://github.com/ok954/noteWay-private/releases/latest) | Download and install on your phone |

> All releases are available on the [Releases](https://github.com/ok954/noteWay-private/releases) page.

---

## Quick Start

### Development Environment

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | >= 3.32.1 | Cross-platform framework |
| Dart SDK | >= 3.8.1 | Programming language |
| Android Studio | Latest | Android emulator + SDK |

### Run the Project

```bash
# 1. Clone
git clone git@github.com:ok954/noteWay-private.git
cd noteWay-private

# 2. Install dependencies
flutter pub get

# 3. Run
flutter run -d windows      # Windows desktop
flutter run -d android      # Android device
```

### Build Release

```bash
# Windows
flutter build windows --release

# Android APK
flutter build apk --release
```

---

## Tech Stack

| Category | Choice |
|----------|--------|
| **Framework** | Flutter 3.32.1 |
| **State Management** | flutter_riverpod 3.3.1 |
| **Local Database** | sqflite / sqflite_common_ffi |
| **Rich Text Editor** | flutter_quill 11.5.0 |
| **Theme** | Material Design 3 + Light/Dark themes |
| **Font** | Noto Sans SC → PingFang SC → Microsoft YaHei |
| **Local Storage** | shared_preferences |
| **File Picker** | file_picker |
| **Image Picker** | image_picker |
| **CSV Parser** | csv |
| **Icons** | Material Icons |
| **CI/CD** | GitHub Actions (auto-build Windows + Android) |

---

## Project Structure

```
lib/
├── main.dart                          # App entry + daily reset
├── app.dart                           # MaterialApp + responsive + localization
├── router.dart                        # Route configuration
├── core/
│   ├── constants/app_colors.dart      # Color constants
│   ├── theme/app_theme.dart           # Light/Dark theme
│   └── database/database_helper.dart  # SQLite initialization
├── models/                            # Data models
│   ├── note.dart / todo.dart / habit.dart
│   ├── checkin_record.dart
│   ├── user.dart / cloud_backup.dart
├── providers/                         # State management
│   ├── note_provider.dart / todo_provider.dart / habit_provider.dart
│   ├── settings_provider.dart / auth_provider.dart
│   ├── cloud_sync_provider.dart / stats_provider.dart
├── repositories/                      # Database/API operations
│   ├── note_repository.dart / todo_repository.dart
│   ├── habit_repository.dart / cloud_repository.dart
├── modules/                           # Business pages
│   ├── home/       # Home page
│   ├── notes/      # Note list + rich text editor
│   ├── todos/      # Todo list
│   ├── habits/     # Habit list
│   ├── timer/      # Timer page
│   ├── login/      # Login/Register
│   └── settings/   # Settings + Cloud sync + Cloud data management
```

---

## Version History

### v1.1.0 (2026-06-04)
- ✅ Integrated flutter_quill rich text editor with inline image embedding
- ✅ Enhanced todos (priority/due date/type/pin/group/filter)
- ✅ Habit timer engine (forward timer/countdown/pause/resume/exit resumption/milliseconds display)
- ✅ Timer button state machine (Start → Pause → Resume → Completed)
- ✅ Data export/import (JSON format, all data included)
- ✅ Dark mode toggle (Light/Dark/System)
- ✅ Global Material Design Chinese localization
- ✅ Windows window title + app icon
- ✅ Android permissions + app icon
- ✅ Responsive layout (wide screen max-width 720px centered)
- ✅ Font optimization (Noto Sans SC)
- ✅ Login/Register page (username + password)
- ✅ Cloud sync framework (API placeholder, pending server setup)
- ✅ Daily data reset logic

### v1.0.0 (2026-05-21)
- Project initialization
- Basic framework (Flutter + Riverpod + SQLite)
- Plain text note CRUD
- Basic todo check/uncheck
- Habit counting + forward timer
- Home page stats cards
- GitHub Actions auto-build

---

## License

MIT License
