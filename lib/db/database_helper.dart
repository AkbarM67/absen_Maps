import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/absen_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;
  static const String userTable = 'users';
  static const String absenTable = 'absen';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $absenTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        latitude REAL,
        longitude REAL,
        imagePath TEXT,
        timestamp TEXT,
        status TEXT,
        pulangTime TEXT
      )
    ''');
  }

  // ================= USER =================
  Future<int> insertUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert(userTable, user.toMap());
  }

  Future<UserModel?> getUser(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      userTable,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<bool> userExists(String username) async {
    final db = await instance.database;
    final result = await db.query(
      userTable,
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

//  akses absen
 Future<int> insertAbsen(AbsenModel absen) async {
  final db = await database;
  final result = await db.insert('absen', absen.toMap());
  print("Berhasil insert absen dengan ID: $result");
  return result;
}

  Future<List<AbsenModel>> getAbsenByUsername(String username) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'absen',
    where: 'username = ?',
    whereArgs: [username],
  );

  print("Data absen ditemukan untuk $username: ${maps.length} data"); // debug

  return List.generate(maps.length, (i) {
    return AbsenModel.fromMap(maps[i]);
  });
}
}
