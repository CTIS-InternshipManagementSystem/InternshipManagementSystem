class Deadline {
  final String id;
  final String courseId;
  final String assignmentName;
  final DateTime deadline;

  Deadline({
    required this.id,
    required this.courseId,
    required this.assignmentName,
    required this.deadline,
  });

  factory Deadline.fromMap(Map<String, dynamic> map) {
    return Deadline(
      id: map['id'],
      courseId: map['courseId'],
      assignmentName: map['assignmentName'],
      deadline: DateTime.parse(map['deadline']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'assignmentName': assignmentName,
      'deadline': deadline.toIso8601String(),
    };
  }
}
