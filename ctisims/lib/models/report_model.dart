class Report {
  final String id;
  final String internshipId;
  final String fileUrl;
  final String submittedAt;
  final int? grade;
  final String? feedback;
  final String createdAt;
  final String updatedAt;

  Report({
    required this.id,
    required this.internshipId,
    required this.fileUrl,
    required this.submittedAt,
    this.grade,
    this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'internship_id': internshipId,
      'file_url': fileUrl,
      'submitted_at': submittedAt,
      'grade': grade,
      'feedback': feedback,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Map'ten nesneye dönüştürme
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      internshipId: map['internship_id'],
      fileUrl: map['file_url'],
      submittedAt: map['submitted_at'],
      grade: map['grade'],
      feedback: map['feedback'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
