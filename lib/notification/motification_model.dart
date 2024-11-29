class NotificationModel {

  
  final int? id; // Auto-increment ID
  final String title;
  final String body;
  final String data;
  final DateTime timestamp;

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
  });

  // Convert NotificationModel to Map for database storage
  Map<String, dynamic> toMap() {
    final adjustedTimestamp = timestamp.add(Duration(days: 1));
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': adjustedTimestamp.toIso8601String(),
    };
  }

  // Convert Map to NotificationModel
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      data: map['data'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
