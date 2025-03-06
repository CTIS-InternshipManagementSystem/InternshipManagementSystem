import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/grade.dart';

class GradeService {
  final _gradeStore = stringMapStoreFactory.store('grades');

  Future<void> saveGrade(Grade grade) async {
    final db = await DatabaseHelper().database;
    await _gradeStore.record(grade.id).put(db, grade.toMap());
  }

  Future<Grade?> getGrade(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _gradeStore.record(id).get(db);
    if (record != null) {
      return Grade.fromMap(record);
    }
    return null;
  }

  Future<int> createGrade(
    String id,
    String studentId,
    String assignmentId,
    int grade,
  ) async {
    final newGrade = Grade(
      id: id,
      studentId: studentId,
      assignmentId: assignmentId,
      grade: grade,
    );
    await saveGrade(newGrade);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<List<Map<String, dynamic>>> getGradesByStudent(
    String studentId,
  ) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('studentId', studentId));
    final recordSnapshots = await _gradeStore.find(db, finder: finder);
    return recordSnapshots.map((snapshot) => snapshot.value).toList();
  }
}
