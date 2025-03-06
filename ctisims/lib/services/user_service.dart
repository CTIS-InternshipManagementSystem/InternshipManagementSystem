import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/user.dart' as AppUser; // User modeline takma ad ekliyoruz
import 'student_course_service.dart';

class UserService {
  final _userStore = stringMapStoreFactory.store('users');
  final StudentCourseService _studentCourseService = StudentCourseService();

  Future<void> saveUser(AppUser.User user) async {
    final db = await DatabaseHelper().database;
    await _userStore.record(user.id).put(db, user.toMap());
  }

  Future<AppUser.User?> getUser(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _userStore.record(id).get(db);
    if (record != null) {
      return AppUser.User.fromMap(record);
    }
    return null;
  }

  Future<int> addUser(
    String id,
    String name,
    String email,
    String bilkentId,
    String role,
    String? supervisorId,
  ) async {
    final user = AppUser.User(
      id: id,
      name: name,
      email: email,
      bilkentId: bilkentId,
      role: role,
      supervisorId: supervisorId,
    );
    await saveUser(user);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<AppUser.User?> getUserDetailsByEmail(String email) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('email', email));
    final recordSnapshot = await _userStore.findFirst(db, finder: finder);
    if (recordSnapshot != null) {
      return AppUser.User.fromMap(recordSnapshot.value);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getTeachers(String courseId) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('role', 'teacher'),
        Filter.equals('courseId', courseId),
      ]),
    );
    final recordSnapshots = await _userStore.find(db, finder: finder);
    return recordSnapshots.map((snapshot) => snapshot.value).toList();
  }

  Future<Map<String, dynamic>?> getStudentInfo(String bilkentId) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('bilkentId', bilkentId));
    final recordSnapshot = await _userStore.findFirst(db, finder: finder);
    if (recordSnapshot != null) {
      final user = AppUser.User.fromMap(recordSnapshot.value);
      final activeCourses = await _studentCourseService
          .getStudentCoursesByStudent(user.id);
      return {
        'name': user.name,
        'bilkentId': user.bilkentId,
        'email': user.email,
        'activeCourses': activeCourses,
      };
    }
    return null;
  }
}
