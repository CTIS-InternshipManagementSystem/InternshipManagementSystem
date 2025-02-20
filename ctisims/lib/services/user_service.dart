import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class UserService {
  final _uuid = Uuid();

  // Kullanıcı Ekleme
  Future<void> addUser(User user) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> createTestUser() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> existingUsers = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['test@example.com'],
    );

    if (existingUsers.isEmpty) {
      await db.insert('users', {
        'id': '1',
        'bilkent_id': '21900000',
        'name': 'Arman',
        'surname': 'Yılmazkurt',
        'email': 'test@example.com',
        'password': '123456', // Normalde hashlenmeli ama test için düz metin
        'role': 'student',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      print("✅ Test kullanıcısı eklendi!");
    } else {
      print("⚠️ Test kullanıcısı zaten mevcut!");
    }
  }

  // Kullanıcı Güncelleme
  Future<void> updateUser(User user) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Kullanıcı Silme
  Future<void> deleteUser(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Kullanıcıları Getirme
  Future<List<User>> getUsers() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('users');

    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Belirli Bir Kullanıcıyı Getirme
  Future<User?> getUserById(String id) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Kullanıcıları Sil (Tümünü)
  Future<void> deleteAllUsers() async {
    final db = await DatabaseHelper().database;
    await db.delete('users');
  }

  Future<User?> authenticateUser(String email, String password) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    print("✅ Kullanıcı çıkış yaptı!");
  }
}
