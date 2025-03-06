class Semester {
  final String id;
  final String year;
  final String semester;

  Semester({required this.id, required this.year, required this.semester});

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'],
      year: map['year'],
      semester: map['semester'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'year': year, 'semester': semester};
  }
}
