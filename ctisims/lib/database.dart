import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb sabitini kullanmak için import edin

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;
    if (kIsWeb) {
      dbPath = 'internship_system.db';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      dbPath = join(directory.path, 'internship_system.db');
    }

    final factory = kIsWeb ? databaseFactoryWeb : databaseFactoryIo;
    return await factory.openDatabase(dbPath);
  }
}
