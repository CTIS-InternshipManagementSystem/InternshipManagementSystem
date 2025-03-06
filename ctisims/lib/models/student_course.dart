class StudentCourse {
  final String id;
  final String studentId;
  final String courseId;
  final bool isActive;
  final bool companyEvaluationUploaded;

  StudentCourse({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.isActive,
    required this.companyEvaluationUploaded,
  });

  factory StudentCourse.fromMap(Map<String, dynamic> map) {
    return StudentCourse(
      id: map['id'],
      studentId: map['studentId'],
      courseId: map['courseId'],
      isActive: map['isActive'],
      companyEvaluationUploaded: map['companyEvaluationUploaded'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'isActive': isActive,
      'companyEvaluationUploaded': companyEvaluationUploaded,
    };
  }
}
