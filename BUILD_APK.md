# KT Apps - Android APK build

## Local build

Use Flutter 3.29.x with Java 17.

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```

The APK will be at:

`build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions

The repository contains `.github/workflows/build-apk.yml`.

Push it to the `dev-github` branch or run the workflow manually from GitHub Actions. The workflow installs Flutter 3.29.3 and Java 17, runs dependency resolution and analysis, builds the release APK, and uploads the APK as a workflow artifact.

## Release signing

The current release build intentionally uses the Android debug signing key so that a clean installable APK can be produced without requiring private signing credentials.

For Play Store distribution, replace the debug signing configuration with a private release keystore stored in GitHub Secrets or a secure local keystore. Never commit the keystore or passwords to the repository.
