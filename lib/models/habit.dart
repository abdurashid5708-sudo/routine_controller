class Habit {
  final String id;

  String title;

  int streak;

  bool isCompletedToday;
  Habit({
    required this.id,
    required this.title,
    this.streak = 0,
    this.isCompletedToday = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'streak': streak,
      'isCompletedToday': isCompletedToday,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      title: json['title'],
      streak: json['streak'] ?? 0,
      isCompletedToday: json['isCompletedToday'] ?? false,
    );
  }
}
