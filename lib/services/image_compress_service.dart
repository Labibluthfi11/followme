import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:universal_io/io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressService {
  static const int profilePhotoMaxBytes = 1800 * 1024;

  static Future<File> compressProfilePhoto(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('File foto profil tidak ditemukan.', file.path);
    }

    if (await file.length() <= profilePhotoMaxBytes) {
      return file;
    }

    final tempDir = await getTemporaryDirectory();
    final baseName = p.basenameWithoutExtension(file.path);
    const attempts = [(1024, 80), (800, 70), (640, 60), (512, 50)];

    for (final (width, quality) in attempts) {
      final outputPath = p.join(tempDir.path, 'profile_${baseName}_$width.jpg');
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outputPath,
        quality: quality,
        minWidth: width,
        minHeight: width,
        autoCorrectionAngle: true,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) continue;

      final compressedFile = File(compressed.path);
      if (await compressedFile.length() <= profilePhotoMaxBytes) {
        return compressedFile;
      }
    }

    throw StateError(
      'Foto profil tidak dapat dikompres di bawah 1,8 MB. Pilih foto lain.',
    );
  }

  /// Kompres gambar ke ukuran yang lebih ramah API (Target ~100-300KB)
  /// Spek: Max 1024px, Quality 70%
  static Future<File> compressImage(File file) async {
    try {
      final filePath = file.absolute.path;

      // Hitung ukuran awal
      final int originalSize = await file.length();
      debugPrint(
        '📸 [ImageCompress] Ukuran Awal: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Jika ukuran sudah kecil (misal < 200KB), tidak perlu kompres berat
      if (originalSize < 200 * 1024) {
        debugPrint(
          '✅ [ImageCompress] Gambar sudah cukup kecil, skip compression.',
        );
        return file;
      }

      // Tentukan path output
      final tempDir = await getTemporaryDirectory();
      final String outPath = p.join(
        tempDir.path,
        "compressed_${p.basename(filePath)}",
      );

      // Proses Kompresi
      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
            filePath,
            outPath,
            quality:
                80, // Dinaikkan sedikit untuk kualitas, tapi resolusi dibatasi
            minWidth: 1024,
            minHeight: 1024,
            rotate: 0,
            autoCorrectionAngle: true,
            format: CompressFormat.jpeg,
          );

      if (compressedXFile == null) {
        debugPrint('⚠️ [ImageCompress] Gagal kompres, menggunakan file asli.');
        return file;
      }

      final File compressedFile = File(compressedXFile.path);
      final int compressedSize = await compressedFile.length();

      debugPrint(
        '🚀 [ImageCompress] Ukuran Akhir: ${(compressedSize / 1024).toStringAsFixed(2)} KB',
      );
      debugPrint(
        '📉 [ImageCompress] Hemat: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('❌ [ImageCompress] Error saat kompresi: $e');
      return file;
    }
  }

  /// Kompres list of files (untuk bukti kerja lembur dll)
  static Future<List<File>> compressMultipleImages(List<File> files) async {
    List<File> compressedFiles = [];
    for (var file in files) {
      compressedFiles.add(await compressImage(file));
    }
    return compressedFiles;
  }
}
