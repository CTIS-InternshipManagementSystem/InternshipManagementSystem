class Grade {
  final String id;
  final String studentId;
  final String assignmentId;
  final int grade;

  Grade({
    required this.id,
    required this.studentId,
    required this.assignmentId,
    required this.grade,
  });

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      studentId: map['studentId'],
      assignmentId: map['assignmentId'],
      grade: map['grade'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'assignmentId': assignmentId,
      'grade': grade,
    };
  }
}
