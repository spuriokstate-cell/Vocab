# Release Guide

Run `bash tool/setup.sh` first (Windows: `tool\setup.ps1`). Before each release, raise `version:` in `pubspec.yaml` (for example `1.0.1+2`).

## Android: Google Play

1. Create an upload key (one time) and keep it safe:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (it's in `.gitignore`, never commit it):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/Users/<you>/upload-keystore.jks
   ```
3. In `android/app/build.gradle.kts`, load `key.properties` and set `signingConfig` for `release`. The steps are in Flutter's guide: https://docs.flutter.dev/deployment/android
4. Build: `flutter build appbundle`. The file is in `build/app/outputs/bundle/release/`.
5. In Play Console, choose the **Designed for Families** target audience and fill in the Data safety form (see `PRIVACY_AND_STORES.md`).

## iPhone and iPad: App Store

1. You need an Apple Developer account ($99/year). A free Apple ID only installs on your own devices, for 7 days at a time.
2. Open `ios/Runner.xcworkspace` in Xcode. Under **Signing & Capabilities**, choose your team and a unique bundle id (e.g. `com.ishtika.vocabIshtika`). Make sure both **iPhone** and **iPad** are ticked under Supported Destinations.
3. Build: `flutter build ipa`, then upload it with Xcode's Organizer or the Transporter app.
4. In App Store Connect, choose the **Kids** category (ages 6–8) and fill in App Privacy as **Data Not Collected**.

## Windows

This must be built on a Windows PC with Visual Studio 2022 ("Desktop development with C++").

1. Build: `flutter build windows`. The app is in `build\windows\x64\runner\Release\`. Zip that whole folder to share it.
2. **To make an installer:**
   - **MSIX** (Microsoft Store or direct install): add the `msix` dev dependency and run `dart run msix:create`. See https://pub.dev/packages/msix
   - **Classic installer:** use Inno Setup with the Release folder.
3. Touchscreens work automatically. Mouse and keyboard are supported: Tab moves between buttons, and Enter submits answers.

## App icon (optional)

Add a 1024×1024 PNG at `assets/icon/icon.png`, add the `flutter_launcher_icons` dev dependency, and run `dart run flutter_launcher_icons`.
