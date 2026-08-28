import 'dart:convert';

class PrintJob {
  final String id;
  final String fileName;
  final String printerIp;
  final DateTime timestamp;
  final String status;

  PrintJob({
    required this.id,
    required this.fileName,
    required this.printerIp,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'printerIp': printerIp,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory PrintJob.fromMap(Map<String, dynamic> map) {
    return PrintJob(
      id: map['id'] ?? '',
      fileName: map['fileName'] ?? '',
      printerIp: map['printerIp'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'unknown',
    );
  }

  String toJson() => json.encode(toMap());

  factory PrintJob.fromJson(String source) => PrintJob.fromMap(json.decode(source));
}
