import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDBHelper {
  static final LocalDBHelper instance = LocalDBHelper._init();
  static Database? _database;

  LocalDBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ctisims.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // Web-specific setup
      var factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(version: 1, onCreate: _createDB),
      );
    } else {
      // Mobile-specific setup
      sqfliteFfiInit();
      final dbPath = await getApplicationDocumentsDirectory();
      final path = join(dbPath.path, filePath);

      return await openDatabase(path, version: 1, onCreate: _createDB);
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';

    // User table
    await db.execute('''
CREATE TABLE User (
  bilkentId $idType,
  name $textType,
  email $textType,
  role $textType,
  supervisorId TEXT
)
''');

    // Supervisor table
    await db.execute('''
CREATE TABLE Supervisor (
  id $idType,
  name $textType
)
''');

    // Insert default supervisors
    await db.insert('Supervisor', {'id': '0', 'name': 'Admin'});
    await db.insert('Supervisor', {'id': '1', 'name': 'Neşe Şahin Özçelik'});
    await db.insert('Supervisor', {'id': '2', 'name': 'Serkan Genç'});
    await db.insert('Supervisor', {'id': '3', 'name': 'Erkan Uçar'});

    // Course table
    await db.execute('''
CREATE TABLE Course (
  id $idType,
  code $textType,
  year $textType,
  semester $textType,
  isActive INTEGER NOT NULL
)
''');

    // StudentCourse table
    await db.execute('''
CREATE TABLE StudentCourse (
  id $idType,
  bilkentId $textType,
  courseId $textType,
  name $textType,
  companyEvaluationUploaded INTEGER NOT NULL,
  isActive INTEGER NOT NULL
)
''');
  }

  // CRUD operations for users
  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('User', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('User');
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await instance.database;
    return await db.query('User', where: 'role = ?', whereArgs: ['Student']);
  }

  Future<Map<String, dynamic>?> getUser(String bilkentId) async {
    final db = await instance.database;
    final maps = await db.query(
      'User',
      where: 'bilkentId = ?',
      whereArgs: [bilkentId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.update(
      'User',
      user,
      where: 'bilkentId = ?',
      whereArgs: [user['bilkentId']],
    );
  }

  Future<int> deleteUser(String bilkentId) async {
    final db = await instance.database;
    return await db.delete(
      'User',
      where: 'bilkentId = ?',
      whereArgs: [bilkentId],
    );
  }

  // CRUD operations for supervisors
  Future<List<Map<String, dynamic>>> getSupervisors() async {
    final db = await instance.database;
    return await db.query('Supervisor');
  }

  // CRUD operations for courses
  Future<int> createCourse(Map<String, dynamic> course) async {
    final db = await instance.database;
    return await db.insert('Course', course);
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final db = await instance.database;
    return await db.query('Course');
  }

  Future<List<Map<String, dynamic>>> getActiveCourses() async {
    final db = await instance.database;
    return await db.query('Course', where: 'isActive = ?', whereArgs: [1]);
  }

  Future<int> deactivateCourse(String id) async {
    final db = await instance.database;
    int result = await db.update(
      'Course',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Also deactivate all student enrollments in this course
    await db.update(
      'StudentCourse',
      {'isActive': 0},
      where: 'courseId = ?',
      whereArgs: [id],
    );

    return result;
  }

  // CRUD operations for student courses
  Future<int> addStudentToCourse(Map<String, dynamic> studentCourse) async {
    final db = await instance.database;
    return await db.insert('StudentCourse', studentCourse);
  }

  Future<List<Map<String, dynamic>>> getStudentCourses() async {
    final db = await instance.database;
    return await db.query('StudentCourse');
  }

  Future<List<Map<String, dynamic>>> getStudentCoursesWithCourseInfo() async {
    final db = await instance.database;
    var studentCourses = await db.query('StudentCourse');
    List<Map<String, dynamic>> result = [];

    for (var studentCourse in studentCourses) {
      final courseId = studentCourse['courseId'] as String;

      final courses = await db.query(
        'Course',
        where: 'id = ?',
        whereArgs: [courseId],
      );

      if (courses.isNotEmpty) {
        final course = courses.first;

        result.add({
          'name': studentCourse['name'],
          'bilkentId': studentCourse['bilkentId'],
          'companyEvaluationUploaded':
              studentCourse['companyEvaluationUploaded'],
          'course': {
            'code': course['code'],
            'courseId': course['id'],
            'isActive': course['isActive'],
            'semester': course['semester'],
            'year': course['year'],
          },
        });
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getStudentCoursesForStudent(
    String bilkentId,
  ) async {
    final db = await instance.database;
    List<Map<String, dynamic>> results = [];

    // Get all active courses for this student
    final studentCourses = await db.query(
      'StudentCourse',
      where: 'bilkentId = ? AND isActive = ?',
      whereArgs: [bilkentId, 1],
    );

    // For each student course, get the course details
    for (var studentCourse in studentCourses) {
      final courseId = studentCourse['courseId'] as String;
      final courses = await db.query(
        'Course',
        where: 'id = ?',
        whereArgs: [courseId],
      );

      if (courses.isNotEmpty) {
        final course = courses.first;
        results.add({
          'id': course['id'],
          'code': course['code'],
          'year': course['year'],
          'semester': course['semester'],
          'isActive': course['isActive'],
          'courseId': course['id'],
        });
      }
    }

    return results;
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // Add example data
  Future<void> populateWithExampleData() async {
    final db = await instance.database;

    // Check if we already have data
    final users = await db.query('User');
    if (users.isNotEmpty) {
      return; // Database already has data
    }

    // Example users
    await db.insert('User', {
      'bilkentId': '22002121',
      'name': 'Hikmet Aydoğan',
      'email': 'hikmet@example.com',
      'role': 'Student',
      'supervisorId': '1',
    });

    await db.insert('User', {
      'bilkentId': '22002122',
      'name': 'Mehmet Yılmaz',
      'email': 'mehmet@example.com',
      'role': 'Student',
      'supervisorId': '2',
    });

    await db.insert('User', {
      'bilkentId': '22002123',
      'name': 'Ayşe Demir',
      'email': 'ayse@example.com',
      'role': 'Student',
      'supervisorId': '3',
    });

    await db.insert('User', {
      'bilkentId': '22002124',
      'name': 'Zeynep Kaya',
      'email': 'zeynep@example.com',
      'role': 'Admin',
      'supervisorId': '',
    });

    // Example courses
    final course1Id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('Course', {
      'id': course1Id,
      'code': '310',
      'year': '2023-2024',
      'semester': 'Spring',
      'isActive': 1,
    });

    final course2Id = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    await db.insert('Course', {
      'id': course2Id,
      'code': '290',
      'year': '2023-2024',
      'semester': 'Fall',
      'isActive': 1,
    });

    // Example student courses
    await db.insert('StudentCourse', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'bilkentId': '22002121',
      'courseId': course1Id,
      'name': 'Hikmet Aydoğan',
      'companyEvaluationUploaded': 0,
      'isActive': 1,
    });

    await db.insert('StudentCourse', {
      'id': (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      'bilkentId': '22002122',
      'courseId': course1Id,
      'name': 'Mehmet Yılmaz',
      'companyEvaluationUploaded': 0,
      'isActive': 1,
    });

    await db.insert('StudentCourse', {
      'id': (DateTime.now().millisecondsSinceEpoch + 2).toString(),
      'bilkentId': '22002123',
      'courseId': course2Id,
      'name': 'Ayşe Demir',
      'companyEvaluationUploaded': 1,
      'isActive': 1,
    });
  }
}
