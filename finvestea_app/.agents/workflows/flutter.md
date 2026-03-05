---
description: Flutter Development Workflow
---

This workflow outlines common tasks for developing this Flutter application.

# Environment Setup
1. Ensure Flutter is installed and in your PATH.
2. Run `flutter doctor` to check for missing dependencies.
3. Run `flutter pub get` to install dependencies.

# Running the App
- **Run on default device:** `flutter run`
- **Run on specific device:** `flutter run -d <device_id>` (e.g., `flutter run -d windows`)
- **Run in release mode:** `flutter run --release`

# Code Quality & Testing
- **Format code:** `flutter format .`
- **Analyze code:** `flutter analyze`
- **Run tests:** `flutter test`

# Building the App
- **Build Windows:** `flutter build windows`
- **Build APK:** `flutter build apk`
- **Build Web:** `flutter build web`

# Dependency Management
- **Add a package:** `flutter pub add <package_name>`
- **Upgrade packages:** `flutter pub upgrade`
