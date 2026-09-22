class InvitesRecord {
  final String sNo;
  final String name;
  final String phone;
  final String status;
  final String place;
  final bool isActive;
  final String remarks;
  final String date;

  InvitesRecord({
    required this.sNo,
    required this.name,
    required this.phone,
    required this.status,
    required this.place,
    required this.isActive,
    required this.remarks,
    required this.date,
  });

  factory InvitesRecord.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val == null) return true;
      final s = val.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes' || s == 'active';
    }

    return InvitesRecord(
      sNo: json['sNo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Invited',
      place: json['place']?.toString() ?? '',
      isActive: parseBool(json['isActive']),
      remarks: json['remarks']?.toString() ?? '',
      date: json['date']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'name': name,
      'phone': phone,
      'status': status,
      'place': place,
      'isActive': isActive,
      'remarks': remarks,
      'date': date,
    };
  }

  InvitesRecord copyWith({
    String? sNo,
    String? name,
    String? phone,
    String? status,
    String? place,
    bool? isActive,
    String? remarks,
    String? date,
  }) {
    return InvitesRecord(
      sNo: sNo ?? this.sNo,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      place: place ?? this.place,
      isActive: isActive ?? this.isActive,
      remarks: remarks ?? this.remarks,
      date: date ?? this.date,
    );
  }

  /// Helper to generate S.No as last 3 digits of current millisecond
  static String generateSNo() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000;
    return ms.toString().padLeft(3, '0');
  }
}
