
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  // 플랫폼 미지원(웹/일부 데스크톱) 시 안전 폴백용 인메모리 캐시
  final Map<String, List<Map<String, dynamic>>> _memoryStore = {
    'professors': [],
    'students': [],
  };

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint('로컬 SQLite 초기화 우회 (인메모리 모드 전환): $e');
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'face_attendance_local.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _onCreate(db, newVersion);
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute("DROP TABLE IF EXISTS course_enrollments");
    await db.execute("DROP TABLE IF EXISTS courses");
    await db.execute("DROP TABLE IF EXISTS students");
    await db.execute("DROP TABLE IF EXISTS professors");

    await db.execute('''
      CREATE TABLE professors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        login_id TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        school TEXT,
        department TEXT,
        face_template TEXT,
        image_path TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        school TEXT,
        major TEXT,
        face_template TEXT,
        image_path TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT NOT NULL,
        professor_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (professor_id) REFERENCES professors (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertUser(Map<String, dynamic> user, String role) async {
    final table = (role == "교수") ? 'professors' : 'students';
    try {
      final db = await database;
      if (db != null) {
        return await db.insert(table, user, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('SQLite insert fallback: $e');
    }

    // 인메모리 폴백 캐싱
    final list = _memoryStore[table]!;
    final idKey = (role == "교수") ? 'login_id' : 'student_id';
    list.removeWhere((item) => item[idKey] == user[idKey]);
    list.add(Map<String, dynamic>.from(user));
    return 1;
  }

  Future<Map<String, dynamic>?> loginUser(String id, String password, String role) async {
    final table = (role == "교수") ? 'professors' : 'students';
    final idField = (role == "교수") ? 'login_id' : 'student_id';

    try {
      final db = await database;
      if (db != null) {
        final List<Map<String, dynamic>> maps = await db.query(
          table,
          where: '$idField = ? AND password = ?',
          whereArgs: [id, password],
        );
        if (maps.isNotEmpty) return maps.first;
      }
    } catch (e) {
      debugPrint('SQLite query fallback: $e');
    }

    // 인메모리 폴백 조회
    final list = _memoryStore[table] ?? [];
    for (final item in list) {
      if (item[idField] == id && item['password'] == password) {
        return item;
      }
    }
    return null;
  }
}
