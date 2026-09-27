#!/usr/bin/env bash
# One-time setup: generates the Android/iOS project files around the app
# code, sets the app name/ID/permissions and creates the launcher icons.
# Run from this folder:   bash setup.sh
set -e
cd "$(dirname "$0")"

echo "▶ Creating Android & iOS project files..."
flutter create --org com.bakeone --project-name bakeone_customer --platforms android,ios . >/dev/null
rm -f test/widget_test.dart

echo "▶ App ID → com.bakeone.customer, name → Bake One"
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] && perl -pi -e 's/applicationId\s*=?\s*"com\.bakeone\.bakeone_customer"/applicationId = "com.bakeone.customer"/' "$f"
done

M=android/app/src/main/AndroidManifest.xml
perl -pi -e 's/android:label="bakeone_customer"/android:label="Bake One"/' "$M"
grep -q 'android.permission.INTERNET' "$M" || perl -0pi -e 's/(<manifest[^>]*>)/$1\n    <uses-permission android:name="android.permission.INTERNET" \/>/' "$M"
grep -q 'usesCleartextTraffic' "$M" || perl -pi -e 's/<application/<application\n        android:usesCleartextTraffic="true"/' "$M"
grep -q 'android.intent.action.DIAL' "$M" || perl -0pi -e 's/<queries>/<queries>\n        <intent><action android:name="android.intent.action.VIEW" \/><data android:scheme="https" \/><\/intent>\n        <intent><action android:name="android.intent.action.DIAL" \/><data android:scheme="tel" \/><\/intent>\n        <intent><action android:name="android.intent.action.SENDTO" \/><data android:scheme="mailto" \/><\/intent>/' "$M"

P=ios/Runner/Info.plist
if [ -f "$P" ] && command -v /usr/libexec/PlistBuddy >/dev/null; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Bake One" "$P" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Bake One" "$P"
  /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity dict" "$P" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSAllowsArbitraryLoads bool true" "$P" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes array" "$P" 2>/dev/null || true
  for s in tel mailto https whatsapp; do /usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes: string $s" "$P" 2>/dev/null || true; done
  perl -pi -e 's/PRODUCT_BUNDLE_IDENTIFIER = com\.bakeone\.bakeoneCustomer;/PRODUCT_BUNDLE_IDENTIFIER = com.bakeone.customer;/' ios/Runner.xcodeproj/project.pbxproj
fi

echo "▶ Getting packages..."
flutter pub get

echo "▶ Creating app icons..."
dart run flutter_launcher_icons

echo "✅ Done. Run the app with:  flutter run"
echo "   (for your local server: flutter run --dart-define=API_BASE_URL=http://<your-mac-ip>:8100)"
