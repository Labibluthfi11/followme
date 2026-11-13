import 'package:absensi_app/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignores legacy maintenance settings in the release manifest', () {
    final manifest = ReleaseManifest.fromJson({
      'version': '1.0.7',
      'download_url': 'https://app.example.test/releases/app.apk',
      'maintenance_enabled': true,
      'maintenance_message': 'Sedang maintenance',
    });

    expect(manifest.version, '1.0.7');
    expect(manifest.minimumVersion, isNull);
  });

  test('accepts a cache-busted HTTPS APK download URL', () {
    const downloadUrl =
        'https://app.example.test/releases/app.apk?release=1.0.19-22';
    final manifest = ReleaseManifest.fromJson({
      'version': '1.0.19',
      'build_number': 22,
      'download_url': downloadUrl,
    });

    expect(manifest.downloadUrl, downloadUrl);
  });

  test('requires an update only when below the configured minimum version', () {
    final manifest = ReleaseManifest.fromJson({
      'version': '1.0.8',
      'download_url': 'https://app.example.test/releases/app.apk',
      'minimum_version': '1.0.8',
    });

    expect(manifest.requiresUpdate('1.0.7'), isTrue);
    expect(manifest.requiresUpdate('1.0.8'), isFalse);
    expect(manifest.requiresUpdate('1.0.9'), isFalse);
  });

  test(
    'offers a newer Android build while keeping the app version unchanged',
    () {
      final manifest = ReleaseManifest.fromJson({
        'version': '1.0.16',
        'build_number': 19,
        'download_url': 'https://app.example.test/releases/app.apk',
      });

      expect(manifest.hasUpdate('1.0.16', '18'), isTrue);
      expect(manifest.hasUpdate('1.0.16', '19'), isFalse);
      expect(manifest.hasUpdate('1.0.16', '20'), isFalse);
    },
  );

  test('keeps supporting version-based updates without a build number', () {
    final manifest = ReleaseManifest.fromJson({
      'version': '1.0.17',
      'download_url': 'https://app.example.test/releases/app.apk',
    });

    expect(manifest.hasUpdate('1.0.16', '19'), isTrue);
    expect(manifest.hasUpdate('1.0.17', '19'), isFalse);
  });

  test('rejects manifests missing existing release fields', () {
    expect(
      () => ReleaseManifest.fromJson({'maintenance_enabled': true}),
      throwsFormatException,
    );
  });

  test('rejects non-HTTPS APK download URLs', () {
    expect(
      () => ReleaseManifest.fromJson({
        'version': '1.0.7',
        'download_url': 'http://app.example.test/app.apk',
      }),
      throwsFormatException,
    );
  });

  test(
    'compares numeric versions without treating malformed text as newer',
    () {
      expect(UpdateService.isNewerVersion('1.0.10', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.9', '1.0.10'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.9+21', '1.0.9'), isFalse);
      expect(UpdateService.isNewerVersion('unknown', '1.0.9'), isFalse);
    },
  );

  test('rejects malformed release versions and minimum versions', () {
    expect(
      () => ReleaseManifest.fromJson({
        'version': 'latest',
        'download_url': 'https://app.example.test/releases/app.apk',
      }),
      throwsFormatException,
    );
    expect(
      () => ReleaseManifest.fromJson({
        'version': '1.0.9',
        'download_url': 'https://app.example.test/releases/app.apk',
        'minimum_version': 'required',
      }),
      throwsFormatException,
    );
  });

  test('rejects invalid Android build numbers', () {
    expect(
      () => ReleaseManifest.fromJson({
        'version': '1.0.16',
        'build_number': 0,
        'download_url': 'https://app.example.test/releases/app.apk',
      }),
      throwsFormatException,
    );
    expect(
      () => ReleaseManifest.fromJson({
        'version': '1.0.16',
        'build_number': 'latest',
        'download_url': 'https://app.example.test/releases/app.apk',
      }),
      throwsFormatException,
    );
  });
}
