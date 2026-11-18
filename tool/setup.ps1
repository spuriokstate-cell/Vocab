# One-time setup on a Windows PC. Creates the Windows and Android platform
# folders around the app code, then fetches packages.
#
#   cd vocab
#   powershell -ExecutionPolicy Bypass -File tool\setup.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter is not installed. See README.md -> 'Install Flutter'." -ForegroundColor Red
  exit 1
}

Write-Host "Creating platform folders (existing files are kept)..."
flutter create --org com.ishtika --project-name vocab_ishtika --platforms=windows,android .

if ((Test-Path test\widget_test.dart) -and (Select-String -Path test\widget_test.dart -Pattern "MyApp" -Quiet)) {
  Remove-Item test\widget_test.dart
}

function Update-File($path, [scriptblock]$change) {
  if (Test-Path $path) {
    $text = Get-Content $path -Raw
    $new = & $change $text
    if ($new -ne $text) {
      Set-Content -Path $path -Value $new -NoNewline -Encoding UTF8
      Write-Host "  updated $path"
    }
  }
}

Write-Host "Setting the app name to 'Vocab Ishtika'..."
Update-File "windows\runner\main.cpp" { param($t) $t.Replace('L"vocab_ishtika"', 'L"Vocab Ishtika"') }
Update-File "windows\runner\Runner.rc" { param($t) $t.Replace('"vocab_ishtika"', '"Vocab Ishtika"') }
Update-File "android\app\src\main\AndroidManifest.xml" {
  param($t)
  $t = $t -replace 'android:label="[^"]*"', 'android:label="Vocab Ishtika"'
  if ($t -notmatch "TTS_SERVICE") {
    $intent = "        <intent>`n            <action android:name=`"android.intent.action.TTS_SERVICE`" />`n        </intent>`n"
    if ($t -match "<queries>") {
      $t = $t -replace "<queries>\r?\n", ("<queries>`n" + $intent)
    } else {
      $t = $t.Replace("</manifest>", "    <queries>`n" + $intent + "    </queries>`n</manifest>")
    }
  }
  $t
}

Write-Host "Getting packages..."
flutter pub get

Write-Host ""
Write-Host "Ready! Next:" -ForegroundColor Green
Write-Host "   flutter analyze"
Write-Host "   flutter test"
Write-Host "   flutter run -d windows"
