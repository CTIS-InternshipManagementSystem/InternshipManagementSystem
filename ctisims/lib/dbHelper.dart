import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  // Uygulama başlatılırken veritabanı initialize edilir.
  static Future<void> init() async {
    if (_database != null) return;
    if (kIsWeb) {
      // Web ortamı için
      databaseFactory = databaseFactoryFfiWeb;
    }

    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'app_database.db');

    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Foreign key kontrollerini aktif ediyoruz.
        await db.execute("PRAGMA foreign_keys = ON");
      },
      onCreate: (db, version) async {
        // Semester tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Semester (
            id TEXT PRIMARY KEY,
            year TEXT NOT NULL,
            semester TEXT NOT NULL,
            isActive INTEGER NOT NULL
          )
        ''');

        // User tablosu (öğrenci, öğretmen, sekretarya gibi roller içeriyor)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS User (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            bilkentId TEXT NOT NULL,
            role TEXT NOT NULL,
            supervisorId TEXT,
            FOREIGN KEY (supervisorId) REFERENCES User(id)
          )
        ''');

        // Insert default user
        await db.insert('User', {
          'id': '1',
          'name': 'Bilgehan',
          'email': 'bilgehan@example.com',
          'bilkentId': '22002357',
          'role': 'Admin'
        });

        // Course tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Course (
            id TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            semesterId TEXT NOT NULL,
            teacherId TEXT NOT NULL,
            FOREIGN KEY (semesterId) REFERENCES Semester(id),
            FOREIGN KEY (teacherId) REFERENCES User(id)
          )
        ''');

        // Assignment tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Assignment (
            id TEXT PRIMARY KEY,
            courseId TEXT NOT NULL,
            name TEXT NOT NULL,
            deadline TEXT NOT NULL,
            FOREIGN KEY (courseId) REFERENCES Course(id)
          )
        ''');

        // Deadline tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Deadline (
            id TEXT PRIMARY KEY,
            courseId TEXT NOT NULL,
            assignmentName TEXT NOT NULL,
            deadline TEXT NOT NULL,
            FOREIGN KEY (courseId) REFERENCES Course(id)
          )
        ''');

        // Grade tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Grade (
            id TEXT PRIMARY KEY,
            studentId TEXT NOT NULL,
            courseId TEXT NOT NULL,
            assignmentId TEXT NOT NULL,
            grade INTEGER NOT NULL,
            FOREIGN KEY (studentId) REFERENCES User(id),
            FOREIGN KEY (assignmentId) REFERENCES Assignment(id)
          )
        ''');

        // StudentCourse tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS StudentCourse (
            id TEXT PRIMARY KEY,
            studentId TEXT NOT NULL,
            courseId TEXT NOT NULL,
            isActive INTEGER NOT NULL,
            companyEvaluationUploaded INTEGER NOT NULL,
            FOREIGN KEY (studentId) REFERENCES User(id),
            FOREIGN KEY (courseId) REFERENCES Course(id)
          )
        ''');

        // Submission tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Submission (
            id TEXT PRIMARY KEY,
            courseId TEXT NOT NULL,
            studentId TEXT NOT NULL,
            assignmentId TEXT NOT NULL,
            comments TEXT NOT NULL,
            submittedAt TEXT NOT NULL,
            FOREIGN KEY (studentId) REFERENCES User(id),
            FOREIGN KEY (assignmentId) REFERENCES Assignment(id)
          )
        ''');
      },
    );
  }

  /// ********** Veritabanı CRUD İşlemleri (opsiyonel) **********
  static Future<int> insert(String table, Map<String, dynamic> data) async {
    await init();
    return await _database!.insert(table, data);
  }

  static Future<List<Map<String, dynamic>>> query(String table) async {
    await init();
    return await _database!.query(table);
  }

  static Future<int> update(String table, Map<String, dynamic> data, String where, List<Object?> whereArgs) async {
    await init();
    return await _database!.update(table, data, where: where, whereArgs: whereArgs);
  }

  static Future<int> delete(String table, String where, List<Object?> whereArgs) async {
    await init();
    return await _database!.delete(table, where: where, whereArgs: whereArgs);
  }

  // POST login: email gönderilir, dönen response içinde role, bilkentId ve username beklenir.
  static Future<Map<String, dynamic>> login(String email) async {
    final List<Map<String, dynamic>> users = await query('User');
    for (var user in users) {
      if (user['email'] == email) {
        return {
          'role': user['role'],
          'bilkentId': user['bilkentId'],
          'username': user['name']
        };
      }
    }
    throw Exception('Login failed');
  }

  // POST AddUser: Yeni kullanıcı ekler.
  static Future<void> addUser(String name, String email, String bilkentId, String role, String semester, String supervisor) async {
    await insert('User', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': email,
      'bilkentId': bilkentId,
      'role': role,
      'supervisorId': supervisor,
    });
  }

  // GET activeSemester: Aktif dönemi döner (örneğin "2024-2023 Fall")
  static Future<String> getActiveSemester() async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query(
      'Semester',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    if (result.isNotEmpty) {
      final activeSemester = result.first;
      return '${activeSemester['year']} ${activeSemester['semester']}';
    }
    throw Exception('Failed to fetch active semester');
  }

  // GET Admins: Admin listesini döner
  static Future<List<Map<String, dynamic>>> getAdmins() async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query(
      'User',
      where: 'role = ?',
      whereArgs: ['admin'],
    );
    if (result.isNotEmpty) {
      return result;
    }
    throw Exception('Failed to fetch admin info');
  }

  // POST createSemester: Yeni dönem ve kurs ekler.
  static Future<void> createSemester(String year, String semester, int isActive) async {
    await insert('Semester', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'year': year,
      'semester': semester,
      'isActive': isActive,
    });
  }

  // POST CheangeDeadlineSettings: Belirli bir kurs ve assignment için deadline değişikliği yapar.
  static Future<void> changeDeadlineSettings(String courseId, String assignmentName, DateTime deadline) async {
    await update(
      'Deadline',
      {'deadline': deadline.toIso8601String()},
      'courseId = ? AND assignmentName = ?',
      [courseId, assignmentName],
    );
  }

  // GET CurrentDeadline310: CTIS310 için deadline bilgilerini döner.
  static Future<List<Map<String, dynamic>>> getCurrentDeadline310() async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query(
      'Deadline',
      where: 'courseId = ?',
      whereArgs: ['310'],
    );
    if (result.isNotEmpty) {
      return result;
    }
    throw Exception('Failed to fetch CTIS310 deadline info');
  }

  // GET CurrentDeadline290: CTIS290 için deadline bilgilerini döner.
  static Future<List<Map<String, dynamic>>> getCurrentDeadline290() async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query(
      'Deadline',
      where: 'courseId = ?',
      whereArgs: ['290'],
    );
    if (result.isNotEmpty) {
      return result;
    }
    throw Exception('Failed to fetch CTIS290 deadline info');
  }

  // GET allCourses: Tüm kurs bilgilerini döner.
  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query('Course');
    if (result.isNotEmpty) {
      return result;
    }
    throw Exception('Failed to fetch course info');
  }

  // GET getActiveCourses: Aktif kursları döner.
  static Future<List<Map<String, dynamic>>> getActiveCourses() async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query(
      'Course',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    if (result.isNotEmpty) {
      return result;
    }
    throw Exception('Failed to fetch active course info');
  }
  

  // POST submit310: CTIS310 için öğrenci gönderimi.
  static Future<void> submit310(String bilkentId, String comments, String assignment) async {
    await insert('Submission', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'courseId': '310',
      'studentId': bilkentId,
      'assignmentId': assignment,
      'comments': comments,
      'submittedAt': DateTime.now().toIso8601String(),
    });
  }

  // POST submit290: CTIS290 için öğrenci gönderimi.
  static Future<void> submit290(String bilkentId, String comments, String assignment) async {
    await insert('Submission', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'courseId': '290',
      'studentId': bilkentId,
      'assignmentId': assignment,
      'comments': comments,
      'submittedAt': DateTime.now().toIso8601String(),
    });
  }

  // GET StudentsfomCourses: Belirli kurs tarih, dönem ve koduna göre öğrencileri döner.
  static Future<List<Map<String, dynamic>>> getStudentsFromCourses(String courseId) async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query(
      'StudentCourse',
      where: 'courseId = ?',
      whereArgs: [courseId],
    );
    if (result.isNotEmpty) {
      List<Map<String, dynamic>> students = [];
      for (var studentCourse in result) {
        final List<Map<String, dynamic>> user = await _database!.query(
          'User',
          where: 'id = ?',
          whereArgs: [studentCourse['studentId']],
        );
        if (user.isNotEmpty) {
          students.add(user.first);
        }
      }
      return students;
    }
    throw Exception('Failed to fetch course students');
  }

  // GET StudentsInfo: Belirli bir bilkentId için öğrenci bilgilerini döner.
  static Future<Map<String, dynamic>> getStudentInfo(String bilkentId) async {
    await init();
    final List<Map<String, dynamic>> result = await _database!.query(
      'User',
      where: 'bilkentId = ?',
      whereArgs: [bilkentId],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    throw Exception('Failed to fetch student info');
  }

  // POST enterGrade: Belirtilen parametrelerle not girilmesini sağlar.
  static Future<void> enterGrade(
      String bilkentId,
      String courseId,
      String assignmentId,
      int grade) async {
    await insert('Grade', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': bilkentId,
      'courseId': courseId,
      'assignmentId': assignmentId,
      'grade': grade,
    });
  }

  // GET getAllGrades: Belirtilen kurs parametrelerine göre tüm notları döner.
  // CTIS310 ve CTIS290 için tüm öğrencilerin notlarını döner.
  static Future<Map<String, dynamic>> getAllGrades(String courseId) async {
    await init();
    List<Map<String, dynamic>> result;
    if (courseId == 'CTIS310') {
      result = await _database!.query(
        'Grade',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
    } else if (courseId == 'CTIS290') {
      result = await _database!.query(
        'Grade',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
    } else {
      throw Exception('Invalid courseId');
    }

    if (result.isNotEmpty) {
      Map<String, Map<String, dynamic>> grades = {};
      for (var grade in result) {
        final student = await getStudentInfo(grade['studentId']);
        final assignment = await _database!.query(
          'Assignment',
          where: 'id = ?',
          whereArgs: [grade['assignmentId']],
        );
        if (assignment.isNotEmpty) {
          String assignmentName = assignment.first['name'] as String;
          if (!grades.containsKey(student['id'])) {
            grades[student['id']] = {
              'name': student['name'],
              'surname': student['surname'],
              'grades': {}
            };
          }
          grades[student['id']]!['grades'][assignmentName] = grade['grade'];
        }
      }
      return {'grades': grades};
    }
    throw Exception('Failed to fetch grade info');
  }

  // POST DeactiveCourse: Belirtilen kursu devre dışı bırakır.
  static Future<void> deactiveCourse(String courseId) async {
    await update(
      'Course',
      {'isActive': 0},
      'id = ?',
      [courseId],
    );
  }

  // GET AllStudents: Tüm öğrencileri ve ilgili kurs bilgilerini döner.
  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    await init();
    final List<Map<String, dynamic>> students = await _database!.query('User', where: 'role = ?', whereArgs: ['student']);
    List<Map<String, dynamic>> studentCourses = [];

    for (var student in students) {
      final List<Map<String, dynamic>> courses = await _database!.query(
        'StudentCourse',
        where: 'studentId = ?',
        whereArgs: [student['id']],
      );

      List<Map<String, dynamic>> courseDetails = [];
      for (var course in courses) {
        final List<Map<String, dynamic>> courseInfo = await _database!.query(
          'Course',
          where: 'id = ?',
          whereArgs: [course['courseId']],
        );
        if (courseInfo.isNotEmpty) {
          courseDetails.add(courseInfo.first);
        }
      }

      studentCourses.add({
        'student': student,
        'courses': courseDetails,
      });
    }

    return studentCourses;
  }
}
