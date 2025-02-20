class JuryEvaluation {
  final String id;
  final String internshipId;
  final String presentationFileUrl;
  final int juryScore;
  final String? comments;
  final String evaluationDate;

  JuryEvaluation({
    required this.id,
    required this.internshipId,
    required this.presentationFileUrl,
    required this.juryScore,
    this.comments,
    required this.evaluationDate,
  });

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'internship_id': internshipId,
      'presentation_file_url': presentationFileUrl,
      'jury_score': juryScore,
      'comments': comments,
      'evaluation_date': evaluationDate,
    };
  }

  // Map'ten nesneye dönüştürme
  factory JuryEvaluation.fromMap(Map<String, dynamic> map) {
    return JuryEvaluation(
      id: map['id'],
      internshipId: map['internship_id'],
      presentationFileUrl: map['presentation_file_url'],
      juryScore: map['jury_score'],
      comments: map['comments'],
      evaluationDate: map['evaluation_date'],
    );
  }
}
