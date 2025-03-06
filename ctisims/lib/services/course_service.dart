import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/course.dart';

class CourseService {
  final _courseStore = stringMapStoreFactory.store('courses');

  Future<void> saveCourse(Course course) async {
    final db = await DatabaseHelper().database;
    await _courseStore.record(course.id).put(db, course.toMap());
  }

  Future<Course?> getCourse(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _courseStore.record(id).get(db);
    if (record != null) {
      return Course.fromMap(record);
    }
    return null;
  }

  Future<int> createCourse(
    String id,
    String code,
    String semesterId,
    String teacherId,
  ) async {
    final newCourse = Course(
      id: id,
      code: code,
      semesterId: semesterId,
      teacherId: teacherId,
    );
    await saveCourse(newCourse);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<List<Map<String, dynamic>>> getCoursesBySemester(
    String semesterId,
  ) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('semesterId', semesterId));
    final recordSnapshots = await _courseStore.find(db, finder: finder);
    return recordSnapshots.map((snapshot) => snapshot.value).toList();
  }
}
