import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/internship_model.dart';
import 'package:uuid/uuid.dart';

class InternshipService {
  final _uuid = Uuid();

  // Staj Ekleme
  Future<void> addInternship(Internship internship) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'internships',
      internship.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Staj Güncelleme
  Future<void> updateInternship(Internship internship) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'internships',
      internship.toMap(),
      where: 'id = ?',
      whereArgs: [internship.id],
    );
  }

  // Staj Silme
  Future<void> deleteInternship(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'internships',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tüm Stajları Getirme
  Future<List<Internship>> getInternships() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('internships');

    return List.generate(maps.length, (i) {
      return Internship.fromMap(maps[i]);
    });
  }

  // Belirli Bir Stajı Getirme
  Future<Internship?> getInternshipById(String id) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'internships',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Internship.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Kullanıcıya Ait Stajları Getirme
  Future<List<Internship>> getInternshipsByStudentId(String studentId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'internships',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );

    return List.generate(maps.length, (i) {
      return Internship.fromMap(maps[i]);
    });
  }
}
