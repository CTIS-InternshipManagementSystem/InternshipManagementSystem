class Followup {
  final String id;
  final String internshipId;
  final String followupType;
  final String? fileUrl;
  final String submittedAt;
  final String createdAt;
  final String updatedAt;

  Followup({
    required this.id,
    required this.internshipId,
    required this.followupType,
    this.fileUrl,
    required this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'internship_id': internshipId,
      'followup_type': followupType,
      'file_url': fileUrl,
      'submitted_at': submittedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Map'ten nesneye dönüştürme
  factory Followup.fromMap(Map<String, dynamic> map) {
    return Followup(
      id: map['id'],
      internshipId: map['internship_id'],
      followupType: map['followup_type'],
      fileUrl: map['file_url'],
      submittedAt: map['submitted_at'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
