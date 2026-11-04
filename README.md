# absensi_app

A new Flutter project.

## Android release

Release builds require a dedicated upload keystore. Do not use the debug keystore
for Play Store releases.

1. Create an upload keystore and store it outside version control.
2. Create `android/key.properties` with these entries:

   ```properties
   storePassword=<keystore-password>
   keyPassword=<key-password>
   keyAlias=<key-alias>
   storeFile=<path-to-keystore>
   ```

   `storeFile` can be an absolute path or a path relative to the `android/`
   directory. `android/key.properties`, `*.jks`, and `*.keystore` are ignored by
   Git.
3. Build the signed bundle with `flutter build appbundle --release`.

Back up the keystore and passwords securely. Losing them can prevent updates to
an app already published with that signing key.

The app's default API endpoint is the production HTTPS service. Release builds
require a valid TLS certificate; do not enable certificate bypasses or use a
local `localhost` API URL for employee devices.

On Windows, `build_apk.bat` builds a signed, obfuscated APK for direct
distribution. It requires Flutter to be available on `PATH`. For Play Store
uploads, use the app bundle command above. Ensure `storeFile` in
`android/key.properties` points to a keystore path valid on the machine doing
the build.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
