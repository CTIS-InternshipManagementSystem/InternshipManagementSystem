import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/report_model.dart';
import 'package:uuid/uuid.dart';

class ReportService {
  final _uuid = Uuid();

  // Staj Raporu Ekleme
  Future<void> addReport(Report report) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'internship_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Staj Raporu Güncelleme
  Future<void> updateReport(Report report) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'internship_reports',
      report.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  // Staj Raporu Silme
  Future<void> deleteReport(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'internship_reports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Belirli Bir Stajın Raporlarını Getirme
  Future<List<Report>> getReportsByInternshipId(String internshipId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'internship_reports',
      where: 'internship_id = ?',
      whereArgs: [internshipId],
    );

    return List.generate(maps.length, (i) {
      return Report.fromMap(maps[i]);
    });
  }

  // Belirli Bir Öğrencinin Raporlarını Getirme
  Future<List<Report>> getReportsByStudentId(String studentId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT ir.* FROM internship_reports ir
      INNER JOIN internships i ON ir.internship_id = i.id
      WHERE i.student_id = ?
    ''', [studentId]);

    return List.generate(maps.length, (i) {
      return Report.fromMap(maps[i]);
    });
  }
}
