class ScanRecord {
  final String id;
  final String name;
  final String timestamp;
  final String url;
  final String? folder;
  final String? tags;
  final bool locked;

  ScanRecord({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.url,
    this.folder,
    this.tags,
    this.locked = false,
  });

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      timestamp: json['timestamp'] ?? '',
      url: json['url'] ?? '',
      folder: json['folder'],
      tags: json['tags'],
      locked: json['locked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp,
      'url': url,
      'folder': folder,
      'tags': tags,
      'locked': locked,
    };
  }
}
