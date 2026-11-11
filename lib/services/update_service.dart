import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseManifest {
  const ReleaseManifest({
    required this.version,
    required this.downloadUrl,
    required this.minimumVersion,
    required this.buildNumber,
  });

  final String version;
  final String downloadUrl;
  final String? minimumVersion;
  final int? buildNumber;

  factory ReleaseManifest.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final downloadUrl = json['download_url'];
    if (version is! String ||
        UpdateService._parseVersion(version) == null ||
        downloadUrl is! String) {
      throw const FormatException('Invalid app update manifest.');
    }
    final parsedDownloadUrl = Uri.tryParse(downloadUrl);
    if (parsedDownloadUrl == null ||
        parsedDownloadUrl.scheme != 'https' ||
        parsedDownloadUrl.host.isEmpty) {
      throw const FormatException('Invalid app download URL.');
    }

    final minimumVersion = json['minimum_version'];
    if (minimumVersion != null &&
        (minimumVersion is! String ||
            UpdateService._parseVersion(minimumVersion) == null)) {
      throw const FormatException('Invalid minimum app version.');
    }

    final rawBuildNumber = json['build_number'];
    final buildNumber = rawBuildNumber is int
        ? rawBuildNumber
        : rawBuildNumber is String
        ? int.tryParse(rawBuildNumber)
        : null;
    if (rawBuildNumber != null && (buildNumber == null || buildNumber < 1)) {
      throw const FormatException('Invalid app build number.');
    }

    return ReleaseManifest(
      version: version,
      downloadUrl: downloadUrl,
      minimumVersion: minimumVersion is String ? minimumVersion : null,
      buildNumber: buildNumber,
    );
  }

  bool requiresUpdate(String currentVersion) =>
      minimumVersion != null &&
      UpdateService.isNewerVersion(minimumVersion!, currentVersion);

  bool hasUpdate(String currentVersion, String currentBuildNumber) {
    if (requiresUpdate(currentVersion) ||
        UpdateService.isNewerVersion(version, currentVersion)) {
      return true;
    }

    final installedBuild = int.tryParse(currentBuildNumber);
    return buildNumber != null &&
        installedBuild != null &&
        buildNumber! > installedBuild;
  }
}

class UpdateService {
  // URL JSON versi
  static const String _updateUrl = 'https://app.followme.id/update.json';
  static Stream<OtaEvent> Function(String url)? downloadStreamOverride;
  static Future<void> Function()? cancelDownloadOverride;

  static Stream<OtaEvent> _downloadApk(String url) =>
      OtaUpdate().execute(url, usePackageInstaller: false);

  static Future<void> _cancelApkDownload() => OtaUpdate().cancel();

  static Future<ReleaseManifest?> fetchReleaseManifest() async {
    try {
      final response = await http
          .get(
            Uri.parse(_updateUrl).replace(
              queryParameters: {
                't': DateTime.now().millisecondsSinceEpoch.toString(),
              },
            ),
            headers: const {'Cache-Control': 'no-cache'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint(
          'Gagal memeriksa status aplikasi: HTTP ${response.statusCode}',
        );
        return null;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid app update manifest.');
      }
      return ReleaseManifest.fromJson(decoded);
    } catch (error) {
      debugPrint('Gagal memeriksa status aplikasi: $error');
      return null;
    }
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final manifest = await fetchReleaseManifest();
    if (manifest == null || !context.mounted) return;

    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    final currentVersion = packageInfo.version;
    final updateRequired = manifest.requiresUpdate(currentVersion);

    if (manifest.hasUpdate(currentVersion, packageInfo.buildNumber)) {
      showUpdatePrompt(
        context,
        manifest.version,
        manifest.downloadUrl,
        isRequired: updateRequired,
      );
    }
  }

  static bool isNewerVersion(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);
    if (latestParts == null || currentParts == null) {
      return false;
    }

    for (var index = 0; index < latestParts.length; index++) {
      final latestPart = latestParts[index];
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      if (latestPart != currentPart) return latestPart > currentPart;
    }
    return false;
  }

  static List<int>? _parseVersion(String version) {
    final normalized = version.trim().split('+').first;
    if (normalized.isEmpty ||
        !RegExp(r'^\d+(?:\.\d+)*$').hasMatch(normalized)) {
      return null;
    }
    return normalized.split('.').map(int.parse).toList(growable: false);
  }

  static void showUpdatePrompt(
    BuildContext context,
    String version,
    String url, {
    bool isRequired = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isRequired,
      builder: (dialogContext) => PopScope(
        canPop: !isRequired,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: const Icon(
            Icons.system_update_rounded,
            size: 50,
            color: Colors.indigo,
          ),
          title: Text(
            isRequired ? 'Pembaruan Wajib' : 'Pembaruan Tersedia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Versi v$version sudah rilis!',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRequired
                    ? 'Perbarui aplikasi untuk melanjutkan penggunaan.'
                    : 'Update sekarang untuk mendapatkan fitur terbaru dan performa yang lebih stabil.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            if (!isRequired)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Nanti Saja',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _startUpdate(context, url);
              },
              child: const Text(
                'Update Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _startUpdate(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialogContent(url: url),
    );
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final String url;
  const _UpdateDialogContent({required this.url});

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  double _progress = 0;
  String _status = 'Menyiapkan unduhan...';
  bool _isError = false;
  bool _showManualButton = false;
  bool _isInstalling = false;
  bool _installerWasOpened = false;
  bool _isComplete = false;
  bool _isTerminal = false;
  StreamSubscription<OtaEvent>? _subscription;
  Timer? _downloadIdleTimer;
  Timer? _downloadTotalTimer;
  Timer? _installationTimeoutTimer;

  static const _downloadIdleTimeout = Duration(seconds: 45);
  static const _downloadTotalTimeout = Duration(minutes: 15);
  static const _installationTimeout = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    _initDownload();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _downloadIdleTimer?.cancel();
    _downloadTotalTimer?.cancel();
    _installationTimeoutTimer?.cancel();
    super.dispose();
  }

  void _initDownload({bool refresh = false}) {
    _subscription?.cancel();
    _cancelTimers();
    _isTerminal = false;
    _isInstalling = false;
    _installerWasOpened = false;
    _isComplete = false;
    _progress = 0;
    _status = 'Menghubungkan ke server pembaruan...';
    _isError = false;
    _showManualButton = false;
    if (refresh && mounted) setState(() {});
    _armDownloadTimeouts();

    try {
      final downloadStream =
          UpdateService.downloadStreamOverride?.call(widget.url) ??
          UpdateService._downloadApk(widget.url);
      _subscription = downloadStream.listen(
        _handleOtaEvent,
        onError: (Object error) {
          debugPrint('[OTA] Download stream error: $error');
          _showFailure(
            'Unduhan gagal dimulai. Periksa koneksi, lalu coba lagi.',
          );
        },
        onDone: _handleStreamDone,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[OTA] Could not start update: $e');
      _showFailure('Gagal memulai pembaruan. Silakan coba lagi.');
    }
  }

  void _handleOtaEvent(OtaEvent event) {
    if (!mounted || _isTerminal) return;

    final progress = double.tryParse(event.value ?? '');
    if (event.status == OtaStatus.DOWNLOADING) {
      _downloadIdleTimer?.cancel();
      _downloadIdleTimer = null;
      if (progress != null && progress.isFinite) {
        _progress = progress.clamp(0, 100);
      }
      setState(() {
        _isInstalling = false;
        _status = 'Mengunduh aplikasi... ${_progress.toInt()}%';
        _isError = false;
        _showManualButton = false;
      });
      _armDownloadIdleTimeout();
      return;
    }

    if (event.status == OtaStatus.INSTALLING) {
      _downloadIdleTimer?.cancel();
      _downloadTotalTimer?.cancel();
      _isInstalling = true;
      _status = 'Installer Android dibuka. Selesaikan pemasangan di layar.';
      _installationTimeoutTimer = Timer(_installationTimeout, () {
        _showFailure(
          'Installer belum selesai. Kembali ke aplikasi, lalu coba update manual.',
        );
      });
      setState(() {
        _isError = false;
        _showManualButton = true;
      });
      return;
    }

    switch (event.status) {
      case OtaStatus.INSTALLATION_DONE:
        _finish(
          'Pembaruan berhasil dipasang.',
          showManualButton: false,
          isComplete: true,
        );
        break;
      case OtaStatus.DOWNLOAD_ERROR:
        _showFailure(
          'Unduhan gagal. Periksa koneksi internet, lalu coba lagi.',
        );
        break;
      case OtaStatus.INSTALLATION_ERROR:
        _showFailure(
          'Pemasangan gagal atau dibatalkan. Coba lagi atau unduh APK manual.',
        );
        break;
      case OtaStatus.CANCELED:
        _showFailure('Unduhan pembaruan dibatalkan.');
        break;
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        _showFailure(
          'Izin instalasi belum aktif. Izinkan FollowMe memasang aplikasi dari sumber ini, lalu coba lagi.',
        );
        break;
      case OtaStatus.INTERNAL_ERROR:
      case OtaStatus.ALREADY_RUNNING_ERROR:
        _showFailure(
          'Proses update tidak dapat dimulai. Tutup proses update lain lalu coba lagi.',
        );
        break;
      case OtaStatus.CHECKSUM_ERROR:
        _showFailure(
          'File APK gagal diverifikasi. Unduh ulang atau gunakan tautan manual.',
        );
        break;
      case OtaStatus.DOWNLOADING:
      case OtaStatus.INSTALLING:
        break;
    }
  }

  void _handleStreamDone() {
    if (!mounted || _isTerminal) return;
    if (_isInstalling) {
      _installerWasOpened = true;
      _finish(
        'Installer Android sudah dibuka. Selesaikan pemasangan, lalu kembali ke aplikasi.',
        showManualButton: true,
      );
    } else {
      _showFailure(
        'Proses unduhan berhenti sebelum selesai. Silakan coba lagi.',
      );
    }
  }

  void _armDownloadTimeouts() {
    _downloadTotalTimer?.cancel();
    _downloadTotalTimer = Timer(_downloadTotalTimeout, () {
      _showFailure(
        'Unduhan terlalu lama. Periksa koneksi atau unduh APK manual.',
      );
    });
    _armDownloadIdleTimeout();
  }

  void _armDownloadIdleTimeout() {
    _downloadIdleTimer?.cancel();
    _downloadIdleTimer = Timer(_downloadIdleTimeout, () {
      _showFailure(
        'Tidak ada progres unduhan selama 45 detik. Periksa koneksi atau unduh manual.',
      );
    });
  }

  void _finish(
    String message, {
    required bool showManualButton,
    bool isComplete = false,
  }) {
    _isTerminal = true;
    _cancelTimers();
    if (!mounted) return;
    setState(() {
      _status = message;
      _isError = false;
      _showManualButton = showManualButton;
      _isInstalling = false;
      _isComplete = isComplete;
      if (!showManualButton) _progress = 100;
    });
  }

  void _showFailure(String message) {
    if (_isTerminal) return;
    _isTerminal = true;
    _cancelTimers();
    _subscription?.cancel();
    final cancel =
        UpdateService.cancelDownloadOverride ??
        UpdateService._cancelApkDownload;
    cancel().catchError((Object error) {
      debugPrint('[OTA] Could not cancel stalled download: $error');
    });
    if (!mounted) return;
    setState(() {
      _status = message;
      _isError = true;
      _showManualButton = true;
      _isInstalling = false;
    });
  }

  void _cancelTimers() {
    _downloadIdleTimer?.cancel();
    _downloadTotalTimer?.cancel();
    _installationTimeoutTimer?.cancel();
    _downloadIdleTimer = null;
    _downloadTotalTimer = null;
    _installationTimeoutTimer = null;
  }

  Future<void> _launchManualDownload() async {
    if ((_isInstalling || _installerWasOpened || _isComplete) && !_isError) {
      Navigator.of(context).pop();
      return;
    }

    final url = Uri.tryParse(widget.url);
    if (url == null || url.scheme != 'https' || url.host.isEmpty) {
      _showFailure('Tautan unduhan tidak valid. Hubungi admin.');
      return;
    }
    final cancel =
        UpdateService.cancelDownloadOverride ??
        UpdateService._cancelApkDownload;
    try {
      await cancel();
    } catch (error) {
      debugPrint('[OTA] Could not stop automatic download: $error');
    }
    await _subscription?.cancel();
    if (!mounted) return;
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showFailure('Browser tidak dapat membuka tautan unduhan.');
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isComplete
                  ? Icons.check_circle_outline_rounded
                  : _isError || _showManualButton || _installerWasOpened
                  ? Icons.info_outline_rounded
                  : Icons.downloading_rounded,
              size: 60,
              color: _isComplete
                  ? Colors.green
                  : _isError || _showManualButton || _installerWasOpened
                  ? Colors.orange
                  : Colors.indigo,
            ),

            const SizedBox(height: 30),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              _isError
                  ? 'Gunakan tombol di bawah untuk download manual.'
                  : 'Jangan tutup aplikasi sampai proses selesai',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 25),

            if (!_isError && !_isInstalling && !_installerWasOpened)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 12,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                  color: Colors.indigo,
                ),
              ),

            if (_showManualButton || _isError)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isError && !_isInstalling
                          ? () => _initDownload(refresh: true)
                          : _launchManualDownload,
                      icon: Icon(
                        _isError && !_isInstalling
                            ? Icons.refresh_rounded
                            : _isInstalling ||
                                  _installerWasOpened ||
                                  _isComplete
                            ? Icons.check_rounded
                            : Icons.open_in_browser,
                      ),
                      label: Text(
                        _isError && !_isInstalling
                            ? 'Coba Lagi'
                            : _isInstalling ||
                                  _installerWasOpened ||
                                  _isComplete
                            ? 'Saya Sudah Selesai'
                            : 'Download APK Manual',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_isError)
                      TextButton.icon(
                        onPressed: _launchManualDownload,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Unduh lewat browser'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (!_isTerminal) {
              final cancel =
                  UpdateService.cancelDownloadOverride ??
                  UpdateService._cancelApkDownload;
              try {
                await cancel();
              } catch (error) {
                debugPrint('[OTA] Could not cancel update: $error');
              }
              await _subscription?.cancel();
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(
            _isError || _isInstalling || _installerWasOpened || _isComplete
                ? 'Tutup'
                : 'Batalkan',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
