import '../../models/user_model.dart';

abstract final class DemoPreview {
  static const enabled = bool.fromEnvironment('FOLLOWME_DEMO_PREVIEW');
  static const token = 'local-demo-preview';

  static final user = User(
    id: 0,
    name: 'Akun Demo',
    email: 'demo@followme.local',
    idKaryawan: 'DEMO-001',
    departemen: 'Preview UI',
    employmentType: 'organik',
    sisaCuti: 12,
    totalCutiDiambil: 0,
    tahunCuti: DateTime.now().year,
  );
}
