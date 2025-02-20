import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/company_evaluation_model.dart';
import 'package:uuid/uuid.dart';

class CompanyEvaluationService {
  final _uuid = Uuid();

  // Şirket Değerlendirmesi Ekleme
  Future<void> addCompanyEvaluation(CompanyEvaluation evaluation) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'company_evaluations',
      evaluation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Şirket Değerlendirmesi Güncelleme
  Future<void> updateCompanyEvaluation(CompanyEvaluation evaluation) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'company_evaluations',
      evaluation.toMap(),
      where: 'id = ?',
      whereArgs: [evaluation.id],
    );
  }

  // Şirket Değerlendirmesi Silme
  Future<void> deleteCompanyEvaluation(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'company_evaluations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Belirli Bir Stajın Şirket Değerlendirmesini Getirme
  Future<CompanyEvaluation?> getEvaluationByInternshipId(
      String internshipId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'company_evaluations',
      where: 'internship_id = ?',
      whereArgs: [internshipId],
    );

    if (maps.isNotEmpty) {
      return CompanyEvaluation.fromMap(maps.first);
    } else {
      return null;
    }
  }
}
