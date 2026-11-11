// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? idKaryawan;
  final String? departemen;
  final String employmentType;
  final String? workLocation;
  final String? role;
  final bool? isAdmin;
  final String? profilePhotoUrl;
  final String? profilePhotoPath;
  // ✅ Data cuti (hanya untuk organik, null untuk freelance)
  final int? sisaCuti;
  final int? totalCutiDiambil;
  final int? tahunCuti;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.idKaryawan,
    required this.departemen,
    required this.employmentType,
    this.workLocation,
    this.role,
    this.isAdmin,
    this.profilePhotoUrl,
    this.profilePhotoPath,
    this.sisaCuti,
    this.totalCutiDiambil,
    this.tahunCuti,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) =>
        value == null ? null : int.tryParse(value.toString());

    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'N/A',
      email: json['email'] as String? ?? 'user@example.com',
      idKaryawan: json['id_karyawan']?.toString(),
      departemen: json['departemen']?.toString(),
      employmentType: json['employment_type'] as String? ?? 'Unknown',
      workLocation: json['work_location']?.toString(),
      role: json['role']?.toString(),
      isAdmin: json['is_admin'] is bool
          ? json['is_admin'] as bool
          : parseInt(json['is_admin']) == null
          ? null
          : parseInt(json['is_admin']) == 1,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      profilePhotoPath: json['profile_photo_path'] as String?,
      sisaCuti: parseInt(json['sisa_cuti']),
      totalCutiDiambil: parseInt(json['total_cuti_diambil']),
      tahunCuti: parseInt(json['tahun_cuti']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'id_karyawan': idKaryawan,
      'departemen': departemen,
      'employment_type': employmentType,
      'work_location': workLocation,
      'role': role,
      'is_admin': isAdmin,
      'profile_photo_url': profilePhotoUrl,
      'profile_photo_path': profilePhotoPath,
      'sisa_cuti': sisaCuti,
      'total_cuti_diambil': totalCutiDiambil,
      'tahun_cuti': tahunCuti,
    };
  }
}
