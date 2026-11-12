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

Every Android release must use the same upload keystore. The release Gradle task
checks the certificate fingerprint and fails if a different key is configured.
Keep at least two secure backups of the keystore and its passwords; never replace
it with a debug keystore. Existing installations signed with a different
certificate require a one-time uninstall/reinstall migration after their local
data has synced. Android cannot install an APK update signed by a different key.

The app's default API endpoint is `https://sistemabsensi.followme.id/api/v1/`,
and its update manifest is `https://sistemabsensi.followme.id/update.json`.
For Android emulator development against a local Laravel server, override the
endpoint explicitly with `--dart-define=BASE_URL=http://10.0.2.2:8000/api/v1/`;
never use this development endpoint for a release build. Release builds require
a valid TLS certificate; do not enable certificate bypasses or use a local
`localhost` API URL for employee devices. Keep the public update manifest's
version and download URL in sync with each release.

Point `sistemabsensi.followme.id` to the production server, configure the
reverse proxy to route this hostname to the Laravel app, and provision HTTPS
before switching clients to this domain. Set the production `APP_URL` to
`https://sistemabsensi.followme.id`. Keep `app.followme.id` serving or proxying
the API, update manifest, and APK for existing app installations; those
installations keep using their old hard-coded host until they install a new APK.

On Windows, `build_apk.bat` builds a signed, obfuscated APK for direct
distribution. It requires Flutter to be available on `PATH`. For Play Store
uploads, use the app bundle command above. Ensure `storeFile` in
`android/key.properties` points to a keystore path valid on the machine doing
the build.

### Internal APK updates

The Android app checks `https://sistemabsensi.followme.id/update.json`. Keep
`download_url` set to the stable URL
`https://sistemabsensi.followme.id/releases/followme-latest.apk`. For each
release, replace the APK file at that URL and update `build_number` in the
manifest to match the APK's Android version code. Increase the build number for
every APK, even when the user-facing `version` stays the same. Android rejects
reinstalling an APK with the same version code, so increment the build suffix
in `pubspec.yaml` (for example, `1.0.16+18` to `1.0.16+19`) without changing
the version name. The updater compares both the version name and build number,
so the replacement is offered once and no longer appears after that build is
installed. Publish the APK before publishing the manifest that points to it.
The download link does not change between releases. Users install an update
over the existing app; they do not need to uninstall it. Android still
requires the user to approve APK installation when prompted.

To require a minimum app version, set `minimum_version` to the required release.
Older versions will show a required-update prompt and cannot dismiss it.
The admin maintenance switch and mobile maintenance gate are not part of the app.
The updater shows download progress, stops waiting if progress stalls, and offers
retry or browser download instead of leaving an endless loading indicator. After
the system installer opens, finish the installation there and return to Followme.

```json
{
  "version": "1.0.17",
  "build_number": 20,
  "download_url": "https://sistemabsensi.followme.id/releases/followme-latest.apk",
  "minimum_version": "1.0.9"
}
```

Server/API-only changes do not require a new APK. Changes to mobile code require
a new signed APK; users update over the existing app and do not need to
uninstall it.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
