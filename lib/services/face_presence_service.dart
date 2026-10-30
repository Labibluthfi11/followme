import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:universal_io/io.dart';

enum FacePresenceResult { noFace, singleFace, multipleFaces }

class FacePresenceService {
  static Future<FacePresenceResult> detectFace(File image) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Validasi wajah hanya tersedia di Android.',
      );
    }

    final detector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );

    try {
      final faces = await detector.processImage(
        InputImage.fromFilePath(image.path),
      );
      if (faces.isEmpty) return FacePresenceResult.noFace;
      if (faces.length > 1) return FacePresenceResult.multipleFaces;
      return FacePresenceResult.singleFace;
    } finally {
      await detector.close();
    }
  }
}
