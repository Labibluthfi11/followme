class NotificationModel {
  final int id;
  final String title;
  final String message; // Isi notifikasi
  final String type;

  // Perubahan 1: targetPage dijadikan nullable (String?)
  // karena di DB Laravel menggunakan nullable()
  final String? targetPage;

  // Perubahan 2: targetId (ID pengajuan yang ditolak) ditambahkan, nullable (int?)
  final int? targetId;

  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetPage, // Tidak perlu 'required' karena nullable
    this.targetId, // Tidak perlu 'required' karena nullable
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final dynamic readValue = json['is_read'];
    final isRead =
        readValue == true || readValue == 1 || readValue?.toString() == '1';

    return NotificationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      targetPage: json['target_page']?.toString(),
      targetId: json['target_id'] == null
          ? null
          : int.tryParse(json['target_id'].toString()),
      isRead: isRead,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}
