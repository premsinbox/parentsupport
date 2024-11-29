import 'package:parentsupport/notification/motification_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NotificationDBHelper {
  static final NotificationDBHelper _instance = NotificationDBHelper._internal();
  static Database? _database;

  NotificationDBHelper._internal();

  factory NotificationDBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'notifications.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            body TEXT,
            data TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notifications');
    return List.generate(maps.length, (i) => NotificationModel.fromMap(maps[i]));
  }
}
