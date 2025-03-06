class Course {
  final String id;
  final String code;
  final String semesterId;
  final String teacherId;

  Course({
    required this.id,
    required this.code,
    required this.semesterId,
    required this.teacherId,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      code: map['code'],
      semesterId: map['semesterId'],
      teacherId: map['teacherId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'semesterId': semesterId,
      'teacherId': teacherId,
    };
  }
}
