#!/bin/bash
# One-time setup on a Mac (or Linux). Creates the Android, iOS and Windows
# platform folders around the app code, then fetches packages.
#
#   cd vocab && bash tool/setup.sh
set -e
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ Flutter is not installed. See README.md → 'Install Flutter'."
  exit 1
fi

echo "▶ Creating platform folders (existing files are kept)…"
flutter create --org com.ishtika --project-name vocab_ishtika \
  --platforms=android,ios,windows .

# flutter create adds a sample test that doesn't match this app.
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

echo "▶ Setting the app name to 'Vocab Ishtika'…"
python3 - <<'PY'
import pathlib, re
def patch(path, fn):
    p = pathlib.Path(path)
    if p.exists():
        s = p.read_text(encoding="utf-8")
        t = fn(s)
        if t != s:
            p.write_text(t, encoding="utf-8")
            print("  updated", path)

# Android: app label + permission to find the phone's text-to-speech voice (Android 11+).
def android(s):
    s = re.sub(r'android:label="[^"]*"', 'android:label="Vocab Ishtika"', s, count=1)
    if "TTS_SERVICE" not in s:
        intent = ('        <intent>\n'
                  '            <action android:name="android.intent.action.TTS_SERVICE" />\n'
                  '        </intent>\n')
        if "<queries>" in s:
            s = s.replace("<queries>\n", "<queries>\n" + intent, 1)
        else:
            s = s.replace("</manifest>", "    <queries>\n" + intent + "    </queries>\n</manifest>")
    return s
patch("android/app/src/main/AndroidManifest.xml", android)

# iOS: display name, and let parents see exported CSV files in the Files app.
def ios(s):
    s = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", r"\1Vocab Ishtika\2", s)
    for key in ("UIFileSharingEnabled", "LSSupportsOpeningDocumentsInPlace"):
        if key not in s:
            s = s.replace("</dict>\n</plist>", f"\t<key>{key}</key>\n\t<true/>\n</dict>\n</plist>")
    return s
patch("ios/Runner/Info.plist", ios)

# Windows: window title and product name.
patch("windows/runner/main.cpp", lambda s: s.replace('L"vocab_ishtika"', 'L"Vocab Ishtika"'))
patch("windows/runner/Runner.rc", lambda s: s.replace('"vocab_ishtika"', '"Vocab Ishtika"'))
PY

echo "▶ Getting packages…"
flutter pub get

echo "▶ Checking the vocabulary…"
python3 tool/validate_vocabulary.py || true

echo ""
echo "✅ Ready! Next:"
echo "   flutter analyze"
echo "   flutter test"
echo "   flutter run"
