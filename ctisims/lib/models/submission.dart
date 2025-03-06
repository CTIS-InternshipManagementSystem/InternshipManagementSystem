class Submission {
  final String id;
  final String studentId;
  final String assignmentId;
  final String comments;
  final DateTime submittedAt;

  Submission({
    required this.id,
    required this.studentId,
    required this.assignmentId,
    required this.comments,
    required this.submittedAt,
  });

  factory Submission.fromMap(Map<String, dynamic> map) {
    return Submission(
      id: map['id'],
      studentId: map['studentId'],
      assignmentId: map['assignmentId'],
      comments: map['comments'],
      submittedAt: DateTime.parse(map['submittedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'assignmentId': assignmentId,
      'comments': comments,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
}
