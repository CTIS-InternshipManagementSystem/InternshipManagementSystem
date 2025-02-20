import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    final path = await getDatabasesPath();
    final databasePath = join(path, 'internship_system.db');

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            bilkent_id TEXT UNIQUE,
            name TEXT,
            surname TEXT,
            email TEXT UNIQUE,
            password TEXT,
            role TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE internships (
            id TEXT PRIMARY KEY,
            student_id TEXT,
            course_code TEXT,
            company_name TEXT,
            start_date TEXT,
            end_date TEXT,
            status TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE internship_reports (
            id TEXT PRIMARY KEY,
            internship_id TEXT,
            file_url TEXT,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            grade INTEGER,
            feedback TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (internship_id) REFERENCES internships (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE company_evaluations (
            id TEXT PRIMARY KEY,
            internship_id TEXT,
            file_url TEXT,
            score INTEGER,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (internship_id) REFERENCES internships (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE ctis310_followups (
            id TEXT PRIMARY KEY,
            internship_id TEXT,
            followup_type TEXT,
            file_url TEXT,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (internship_id) REFERENCES internships (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE ctis310_jury (
            id TEXT PRIMARY KEY,
            internship_id TEXT,
            presentation_file_url TEXT,
            jury_score INTEGER,
            comments TEXT,
            evaluation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (internship_id) REFERENCES internships (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE semesters (
            id TEXT PRIMARY KEY,
            year INTEGER,
            semester TEXT,
            course_code TEXT,
            deadline TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }
}
