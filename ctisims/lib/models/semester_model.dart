class Semester {
  final String id;
  final int year;
  final String semester;
  final String courseCode;
  final String deadline;
  final String createdAt;
  final String updatedAt;

  Semester({
    required this.id,
    required this.year,
    required this.semester,
    required this.courseCode,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'semester': semester,
      'course_code': courseCode,
      'deadline': deadline,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Map'ten nesneye dönüştürme
  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'],
      year: map['year'],
      semester: map['semester'],
      courseCode: map['course_code'],
      deadline: map['deadline'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
