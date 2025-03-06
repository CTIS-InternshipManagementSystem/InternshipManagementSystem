import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/student_course.dart';

class StudentCourseService {
  final _studentCourseStore = stringMapStoreFactory.store('student_courses');

  Future<void> saveStudentCourse(StudentCourse studentCourse) async {
    final db = await DatabaseHelper().database;
    await _studentCourseStore
        .record(studentCourse.id)
        .put(db, studentCourse.toMap());
  }

  Future<StudentCourse?> getStudentCourse(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _studentCourseStore.record(id).get(db);
    if (record != null) {
      return StudentCourse.fromMap(record);
    }
    return null;
  }

  Future<int> createStudentCourse(
    String id,
    String studentId,
    String courseId,
    bool isActive,
    bool companyEvaluationUploaded,
  ) async {
    final newStudentCourse = StudentCourse(
      id: id,
      studentId: studentId,
      courseId: courseId,
      isActive: isActive,
      companyEvaluationUploaded: companyEvaluationUploaded,
    );
    await saveStudentCourse(newStudentCourse);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<List<Map<String, dynamic>>> getStudentCoursesByStudent(
    String studentId,
  ) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('studentId', studentId));
    final recordSnapshots = await _studentCourseStore.find(db, finder: finder);
    return recordSnapshots.map((snapshot) => snapshot.value).toList();
  }
}
