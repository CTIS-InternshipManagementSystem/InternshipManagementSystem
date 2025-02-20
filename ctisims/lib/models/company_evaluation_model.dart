class CompanyEvaluation {
  final String id;
  final String internshipId;
  final String fileUrl;
  final int score;
  final String submittedAt;

  CompanyEvaluation({
    required this.id,
    required this.internshipId,
    required this.fileUrl,
    required this.score,
    required this.submittedAt,
  });

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'internship_id': internshipId,
      'file_url': fileUrl,
      'score': score,
      'submitted_at': submittedAt,
    };
  }

  // Map'ten nesneye dönüştürme
  factory CompanyEvaluation.fromMap(Map<String, dynamic> map) {
    return CompanyEvaluation(
      id: map['id'],
      internshipId: map['internship_id'],
      fileUrl: map['file_url'],
      score: map['score'],
      submittedAt: map['submitted_at'],
    );
  }
}
