import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/jury_model.dart';
import 'package:uuid/uuid.dart';

class JuryService {
  final _uuid = Uuid();

  // Jüri Değerlendirmesi Ekleme
  Future<void> addJuryEvaluation(JuryEvaluation juryEvaluation) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'ctis310_jury',
      juryEvaluation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Jüri Değerlendirmesi Güncelleme
  Future<void> updateJuryEvaluation(JuryEvaluation juryEvaluation) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'ctis310_jury',
      juryEvaluation.toMap(),
      where: 'id = ?',
      whereArgs: [juryEvaluation.id],
    );
  }

  // Jüri Değerlendirmesi Silme
  Future<void> deleteJuryEvaluation(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'ctis310_jury',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Belirli Bir Staja Ait Jüri Değerlendirmesini Getirme
  Future<JuryEvaluation?> getJuryEvaluationByInternshipId(
      String internshipId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ctis310_jury',
      where: 'internship_id = ?',
      whereArgs: [internshipId],
    );

    if (maps.isNotEmpty) {
      return JuryEvaluation.fromMap(maps.first);
    } else {
      return null;
    }
  }
}
