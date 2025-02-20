class Internship {
  final String id;
  final String studentId;
  final String courseCode;
  final String companyName;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;
  final String updatedAt;

  Internship({
    required this.id,
    required this.studentId,
    required this.courseCode,
    required this.companyName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'course_code': courseCode,
      'company_name': companyName,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Map'ten nesneye dönüştürme
  factory Internship.fromMap(Map<String, dynamic> map) {
    return Internship(
      id: map['id'],
      studentId: map['student_id'],
      courseCode: map['course_code'],
      companyName: map['company_name'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      status: map['status'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
