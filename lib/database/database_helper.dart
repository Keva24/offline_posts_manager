import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _databaseName = 'posts_manager.db';
  static const int _databaseVersion = 1;

  static const String _tableName = 'posts';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnAuthor = 'author';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        // FIX: Added onUpgrade handler to prevent crashes on future version bumps.
        onUpgrade: (db, oldVersion, newVersion) async {
          // Handle future schema migrations here.
        },
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $_tableName(
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnTitle TEXT NOT NULL,
          $columnContent TEXT NOT NULL,
          $columnAuthor TEXT NOT NULL,
          $columnCreatedAt TEXT NOT NULL,
          $columnUpdatedAt TEXT NOT NULL
        )
      ''');
    } catch (e) {
      throw Exception('Failed to create table: $e');
    }
  }

  // Create - Insert a new post
  Future<int> insertPost(Post post) async {
    try {
      final db = await database;
      return await db.insert(
        _tableName,
        post.toMap(),
        // FIX: Changed from ConflictAlgorithm.replace to .abort.
        // .replace silently deletes and re-inserts the row (changing its id),
        // which is dangerous for a posts manager.
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw Exception('Failed to insert post: $e');
    }
  }

  // Read - Get all posts
  Future<List<Post>> getAllPosts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: '$columnCreatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return Post.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // Read - Get a single post by ID
  Future<Post?> getPostById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Post.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  // Update - Edit an existing post
  Future<int> updatePost(Post post) async {
    try {
      final db = await database;
      // FIX 1: Remove 'id' from the update map to avoid passing it
      // in the data alongside the WHERE clause, which can cause conflicts.
      // FIX 2: Manually set 'updated_at' to now, since the Post object's
      // updatedAt is already set correctly in AddEditPostScreen, but
      // this acts as a safety net.
      final map = post.toMap()..remove('id');
      map['updated_at'] = DateTime.now().toIso8601String();

      return await db.update(
        _tableName,
        map,
        where: '$columnId = ?',
        whereArgs: [post.id],
      );
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // Delete - Remove a post
  Future<int> deletePost(int id) async {
    try {
      final db = await database;
      return await db.delete(
        _tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Search posts by title or content
  Future<List<Post>> searchPosts(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '$columnTitle LIKE ? OR $columnContent LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '$columnCreatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return Post.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  // Get posts count
  Future<int> getPostsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get posts count: $e');
    }
  }

  // Delete all posts
  Future<int> deleteAllPosts() async {
    try {
      final db = await database;
      return await db.delete(_tableName);
    } catch (e) {
      throw Exception('Failed to delete all posts: $e');
    }
  }
}