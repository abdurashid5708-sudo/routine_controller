class Mission {
  final String id;
  String title;
  String category;
  DateTime? dueDate;
  String priority;
  bool isCompleted;

  DateTime? startTime;
  DateTime? endTime;

  Mission({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      category: json['category'] ?? 'General',
      priority: json['priority'] ?? 'Medium',
      isCompleted: json['isCompleted'] ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    );
  }
}
