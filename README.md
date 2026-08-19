# ktppsflutter

Restored Flutter app shell for the rent reports UI.

## Quick start

```zsh
cd "/Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new"
flutter pub get
flutter run -d chrome
```

## Run tests

```zsh
cd "/Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new"
flutter test
```

## Deploy to GitHub Pages

This repository includes a workflow at `.github/workflows/deploy-pages.yml` that builds and deploys Flutter web to GitHub Pages.

1. Push your code to the `main` branch.
2. In GitHub, open **Settings -> Pages**.
3. Set **Source** to **GitHub Actions**.
4. Wait for the **Deploy Flutter web to GitHub Pages** workflow to finish.

### Notes

- For a project site (`https://<user>.github.io/<repo>/`), the workflow automatically builds with `--base-href "/<repo>/"`.
- For a user/organization site (`https://<user>.github.io/`), the workflow automatically builds with `--base-href "/"`.
- A `404.html` fallback is generated from `index.html` so deep links work better on GitHub Pages.
