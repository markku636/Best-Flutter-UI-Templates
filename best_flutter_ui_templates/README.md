# Best Flutter UI Templates

A gallery of introduction, hotel booking, fitness, and design course demos.

## SDK

Use Flutter **3.47.6 stable**, which includes Dart **3.13.5**. The same Flutter version is pinned in the GitHub Actions workflow.

## Run in a browser

From this directory:

```sh
flutter pub get
flutter run -d chrome
```

To use another browser with a local web server:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Open http://127.0.0.1:8080. Web development does not require an Android emulator or Android SDK.

## Android

Install the Android SDK and use either a connected Android phone with USB debugging enabled or an Android emulator. Check the environment and available devices with:

```sh
flutter doctor
flutter devices
flutter run -d <device-id>
```

## Verify

```sh
flutter analyze --no-fatal-infos
flutter test
flutter build web
```

The widget tests load the bundled fonts and check the home layout and navigation to all four demos. Existing style lint suggestions are informational.
