import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/semester_model.dart';
import 'package:uuid/uuid.dart';

class SemesterService {
  final _uuid = Uuid();

  // Dönem Ekleme
  Future<void> addSemester(Semester semester) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'semesters',
      semester.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Dönem Güncelleme
  Future<void> updateSemester(Semester semester) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'semesters',
      semester.toMap(),
      where: 'id = ?',
      whereArgs: [semester.id],
    );
  }

  // Dönem Silme
  Future<void> deleteSemester(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'semesters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tüm Dönemleri Getirme
  Future<List<Semester>> getAllSemesters() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('semesters');

    return List.generate(maps.length, (i) {
      return Semester.fromMap(maps[i]);
    });
  }

  // Belirli Bir Ders Koduna Ait Dönemleri Getirme
  Future<List<Semester>> getSemestersByCourse(String courseCode) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'semesters',
      where: 'course_code = ?',
      whereArgs: [courseCode],
    );

    return List.generate(maps.length, (i) {
      return Semester.fromMap(maps[i]);
    });
  }
}
