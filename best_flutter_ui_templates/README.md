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

## Mobile launch scripts

Run these commands from the repository root. The scripts locate the app
directory automatically, choose an emulator, wait for it to boot, fetch packages,
and run the app. They use the Dart SDK included with Flutter.

Windows / Android:

```powershell
.\run-android.cmd
.\run-android.cmd --check
.\run-android.cmd --list
.\run-android.cmd --emulator Pixel_API_36
.\run-android.cmd --device emulator-5554 -- --release
```

Use the AVD name or device ID listed on your machine. Install Android Studio and
the SDK tools first, and create an AVD with a system image in Device Manager.
Review SDK licenses with `flutter doctor --android-licenses`.
If the SDK is in a custom location, set `ANDROID_HOME`.

macOS / iOS:

```sh
bash run-ios.command
bash run-ios.command --check
bash run-ios.command --list
bash run-ios.command --emulator YOUR_SIMULATOR_UDID
bash run-ios.command --device YOUR_IPHONE_DEVICE_ID
```

Install Flutter 3.47.6, Xcode and an iOS simulator runtime first. Complete Xcode's
first-launch setup and license review. The script opens Device Hub on Xcode 27
or Simulator on older versions. For a physical iPhone, enable Developer Mode
and set your own Team and bundle identifier under Signing & Capabilities in
`ios/Runner.xcworkspace`; the project currently contains the upstream author's Team.

Add Flutter's `bin` directory to PATH, or set `FLUTTER_ROOT` to the SDK directory.
Use `--help` for all options and `--timeout 600` to allow a slower first boot.

## Verify

```sh
flutter analyze --no-fatal-infos
flutter test
flutter build web
```

The widget tests load the bundled fonts and check the home layout and navigation to all four demos. Existing style lint suggestions are informational.
