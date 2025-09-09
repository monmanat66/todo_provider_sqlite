import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class TodoDB {
  static final TodoDB _instance = TodoDB._internal();
  factory TodoDB() => _instance;
  TodoDB._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todos_plus.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            notes TEXT,
            due_at INTEGER,
            priority INTEGER NOT NULL DEFAULT 0,
            is_done INTEGER NOT NULL DEFAULT 0,
            tags TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // migrate from basic table to extended columns if needed
          // In case old DB exists with fewer columns, add missing columns.
          await db.execute("ALTER TABLE todos ADD COLUMN notes TEXT");
          await db.execute("ALTER TABLE todos ADD COLUMN due_at INTEGER");
          await db.execute("ALTER TABLE todos ADD COLUMN priority INTEGER NOT NULL DEFAULT 0");
          await db.execute("ALTER TABLE todos ADD COLUMN tags TEXT");
          await db.execute("ALTER TABLE todos ADD COLUMN created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000)");
          await db.execute("ALTER TABLE todos ADD COLUMN updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000)");
        }
      },
    );
  }

  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return db.insert('todos', todo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Todo>> getTodos() async {
    final db = await database;
    final res = await db.query('todos', orderBy: 'is_done ASC, priority DESC, COALESCE(due_at, 9999999999999) ASC, id DESC');
    return res.map((e) => Todo.fromMap(e)).toList();
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await database;
    final data = todo.toMap();
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return db.update('todos', data, where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    return db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('todos');
  }
}
