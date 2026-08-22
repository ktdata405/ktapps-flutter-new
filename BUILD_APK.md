# Android APK build

This project is configured for a conservative Flutter Android toolchain:
- Flutter 3.29.3
- Java 17
- Android Gradle Plugin 8.7.3
- Gradle 8.9
- Kotlin 1.9.24
- compileSdk 35
- targetSdk 35

GitHub Actions builds `app-release.apk` from the `dev-github` branch.

For a local debug build:
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

For the GitHub Actions release build, use the **Build Android APK** workflow. The APK is uploaded as the `ktapps-release-apk` artifact.
