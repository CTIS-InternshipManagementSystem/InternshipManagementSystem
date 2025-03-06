class Assignment {
  final String id;
  final String courseId;
  final String name;
  final DateTime deadline;

  Assignment({
    required this.id,
    required this.courseId,
    required this.name,
    required this.deadline,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'],
      courseId: map['courseId'],
      name: map['name'],
      deadline: DateTime.parse(map['deadline']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'deadline': deadline.toIso8601String(),
    };
  }
}
