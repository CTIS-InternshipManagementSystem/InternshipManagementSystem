import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
            semester TEXT NOT NULL
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

  /// ********** Ortak HTTP Fonksiyonları **********
// Update your static request methods like this:
static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
  final url = Uri.parse('https://7ab8-139-179-233-241.ngrok-free.app/$endpoint');
  return await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'ngrok-skip-browser-warning': 'true' // Bypass ngrok browser warning
    },
    body: jsonEncode(body),
  );
}

static Future<http.Response> get(String endpoint) async {
  final url = Uri.parse('https://7ab8-139-179-233-241.ngrok-free.app/$endpoint');
  return await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'ngrok-skip-browser-warning': 'true'
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

  /// ********** Backend Endpoint Metotları **********

  // POST login: email gönderilir, dönen response içinde role, bilkentId ve username beklenir.
  static Future<Map<String, dynamic>> login(String email) async {
    final response = await post('login', {
      'email': email
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Login başarısız');
  }

  // POST AddUser: Yeni kullanıcı ekler.
  static Future<void> addUser(String name, String email, String bilkentId, String role, String semester, String supervisor) async {
    final response = await post('AddUser', {
      'name': name,
      'email': email,
      'bilkentId': bilkentId,
      'role': role,
      'semester': semester,
      'supervisor': supervisor,
    });
    if (response.statusCode != 200) {
      throw Exception('Kullanıcı eklenemedi');
    }
  }

  // GET activeSemester: Aktif dönemi döner (örneğin "2024-2023 Fall")
  static Future<String> getActiveSemester() async {
    final response = await get('activeSemester');
    if (response.statusCode == 200) {
      // Dönen JSON örn: { "activeSemester": "2024-2023 Fall" }
      return jsonDecode(response.body)['activeSemester'];
    }
    throw Exception('Aktif dönem alınamadı');
  }

  // GET Teacher: Öğretmen listesini döner
  static Future<List<dynamic>> getTeachers() async {
    final response = await get('Teacher');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Öğretmen bilgileri alınamadı');
  }

  // POST createSemester: Yeni dönem ve kurs ekler.
  static Future<void> createSemester(String year, String semester, String course) async {
    final response = await post('createSemester', {
      'year': year,
      'semester': semester,
      'course': course,
    });
    if (response.statusCode != 200) {
      throw Exception('Dönem oluşturulamadı');
    }
  }

  // POST CheangeDeadlineSettings: Belirli bir kurs ve assignment için deadline değişikliği yapar.
  static Future<void> changeDeadlineSettings(String course, String assignment, DateTime deadline) async {
    final response = await post('CheangeDeadlineSettings', {
      'course': course,
      'assignment': assignment,
      'deadline': deadline.toIso8601String(),
    });
    if (response.statusCode != 200) {
      throw Exception('Deadline değiştirilemedi');
    }
  }

  // GET CurrentDeadline310: CTIS310 için deadline bilgilerini döner.
  static Future<Map<String, dynamic>> getCurrentDeadline310() async {
    final response = await get('CurrentDeadline310');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('CTIS310 deadline bilgileri alınamadı');
  }

  // GET CurrentDeadline290: CTIS290 için deadline bilgisini döner.
  static Future<Map<String, dynamic>> getCurrentDeadline290() async {
    final response = await get('CurrentDeadline290');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('CTIS290 deadline bilgisi alınamadı');
  }

  // GET allCoursesforAdmin: Admin için tüm kurs bilgilerini döner.
  static Future<List<dynamic>> getAllCoursesForAdmin() async {
    final response = await get('allCoursesforAdmin');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Admin kurs bilgileri alınamadı');
  }

  // GET getActiveCourseforStudent: Öğrenci için aktif kursu döner.
  static Future<Map<String, dynamic>> getActiveCourseForStudent() async {
    final response = await get('getActiveCourseforStudent');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Öğrenci için aktif kurs bilgisi alınamadı');
  }

  // POST submit310: CTIS310 için öğrenci gönderimi.
  static Future<void> submit310(String bilkentId, String comments, String assignment) async {
    final response = await post('submit310', {
      'bilkentId': bilkentId,
      'comments': comments,
      'assignment': assignment,
    });
    if (response.statusCode != 200) {
      throw Exception('CTIS310 gönderimi yapılamadı');
    }
  }

  // POST submit290: CTIS290 için öğrenci gönderimi.
  static Future<void> submit290(String bilkentId, String comments) async {
    final response = await post('submit290', {
      'bilkentId': bilkentId,
      'comments': comments,
    });
    if (response.statusCode != 200) {
      throw Exception('CTIS290 gönderimi yapılamadı');
    }
  }

  // GET StudentsfomCourses: Belirli kurs tarih, dönem ve koduna göre öğrencileri döner.
  static Future<List<dynamic>> getStudentsFromCourses(String courseDate, String courseSemester, String courseCode) async {
    final response = await get('StudentsfomCourses?courseDate=$courseDate&courseSemester=$courseSemester&courseCode=$courseCode');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Kurs öğrencileri alınamadı');
  }

  // GET StudentsInfo: Belirli bir bilkentId için öğrenci bilgilerini döner.
  static Future<Map<String, dynamic>> getStudentInfo(String bilkentId) async {
    final response = await get('StudentsInfo?bilkentId=$bilkentId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Öğrenci bilgileri alınamadı');
  }

  // POST enterGrade: Belirtilen parametrelerle not girilmesini sağlar.
  static Future<void> enterGrade(
      String bilkentId,
      String courseDate,
      String courseSemester,
      String courseCode,
      String assignmentName,
      int grade) async {
    final response = await post('enterGrade', {
      'bilkentId': bilkentId,
      'courseDate': courseDate,
      'courseSemester': courseSemester,
      'courseCode': courseCode,
      'assignmentName': assignmentName,
      'grade': grade,
    });
    if (response.statusCode != 200) {
      throw Exception('Not girilemedi');
    }
  }

  // GET getAllGrades: Belirtilen kurs parametrelerine göre tüm notları döner.
  // CTIS310 için followup1-5 ve report, CTIS290 için sadece report notu döner.
  static Future<Map<String, dynamic>> getAllGrades(String courseDate, String courseSemester, String courseCode) async {
    final response = await get('getAllGrades?courseDate=$courseDate&courseSemester=$courseSemester&courseCode=$courseCode');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Not bilgileri alınamadı');
  }

  // POST DeactiveCourse: Belirtilen kursu devre dışı bırakır.
  static Future<void> deactiveCourse(String courseDate, String courseSemester, String courseCode) async {
    final response = await post('DeactiveCourse', {
      'courseDate': courseDate,
      'courseSemester': courseSemester,
      'courseCode': courseCode,
    });
    if (response.statusCode != 200) {
      throw Exception('Kurs devre dışı bırakılamadı');
    }
  }

  // GET AllStudents: Tüm öğrencileri ve ilgili kurs bilgilerini döner.
  static Future<List<dynamic>> getAllStudents() async {
    final response = await get('AllStudents');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Öğrenci listesi alınamadı');
  }
}
