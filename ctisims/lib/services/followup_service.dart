import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/followup_model.dart';
import 'package:uuid/uuid.dart';

class FollowupService {
  final _uuid = Uuid();

  // Aşama Takibi Ekleme
  Future<void> addFollowup(Followup followup) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'ctis310_followups',
      followup.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Aşama Takibi Güncelleme
  Future<void> updateFollowup(Followup followup) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'ctis310_followups',
      followup.toMap(),
      where: 'id = ?',
      whereArgs: [followup.id],
    );
  }

  // Aşama Takibi Silme
  Future<void> deleteFollowup(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'ctis310_followups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Belirli Bir Staja Ait Aşama Takiplerini Getirme
  Future<List<Followup>> getFollowupsByInternshipId(String internshipId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ctis310_followups',
      where: 'internship_id = ?',
      whereArgs: [internshipId],
    );

    return List.generate(maps.length, (i) {
      return Followup.fromMap(maps[i]);
    });
  }
}
