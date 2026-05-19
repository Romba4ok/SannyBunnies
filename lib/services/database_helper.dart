












import 'dart:io';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  
  
  
  static final Map<String, Future<List<int>?>> _imageFutureCache = {};

  static const _dbName = 'app.db';
  static const _dbVersion = 2;

  static const _table = 'cached_images';
  static const _colUrl = 'url';
  static const _colPath = 'path';
  static const _colCreatedAt = 'created_at';

  Database? _db;

  

  Future<void> initDatabase() async {
    await _database; 
  }

  
  
  
  
  
  
  
  
  Future<List<int>?> getCachedImage(String url) {
    if (url.isEmpty) return Future.value(null);
    return _imageFutureCache.putIfAbsent(url, () async {
      final file = await getCachedImageFile(url);
      if (file == null) return null;
      try {
        final bytes = await file.readAsBytes();
        
        
        if (bytes.isEmpty) {
          print('⚠️ Пустые данные для $url - удаляем из кэше');
          await deleteImage(url);
          return null;
        }
        
        
        
        
        
        if (!_isValidImageData(bytes)) {
          print('⚠️ Невалидные данные изображения для $url - удаляем из кэше');
          await deleteImage(url);
          return null;
        }
        
        return bytes;
      } catch (e) {
        print('❌ Ошибка чтения кэшированного файла $url: $e');
        await deleteImage(url); 
        return null;
      }
    });
  }

  
  bool _isValidImageData(List<int> bytes) {
    if (bytes.length < 4) return false;
    
    
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true; 
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true; 
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return true; 
    }
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return true; 
    }
    
    return false;
  }

  
  Future<File?> getCachedImageFile(String url) async {
    if (url.isEmpty) return null;

    
    final existingPath = await getImagePath(url);
    if (existingPath != null) {
      final f = File(existingPath);
      if (await f.exists()) {
        print('Кэш найден для $url: $existingPath');
        return f;
      } else {
        print('Файл не существует для $url: $existingPath');
      }
    }

    
    try {
      print('Скачиваем изображение для $url');
      final imagesDir = await _ensureImagesDir();
      final uri = Uri.parse(url);
      var fileName = p.basename(uri.path);
      if (fileName.isEmpty) {
        fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else if (p.extension(fileName).isEmpty) {
        fileName = '$fileName.jpg';
      }
      final targetFile = File(p.join(imagesDir.path, fileName));

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        print('Ошибка скачивания $url: статус ${res.statusCode}');
        return null;
      }

      await targetFile.writeAsBytes(res.bodyBytes);
      print('Файл сохранен: ${targetFile.path}');

      
      final db = await _database;
      await db.insert(
        _table,
        {
          _colUrl: url,
          _colPath: targetFile.path,
          _colCreatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Запись в БД добавлена для $url');
      return targetFile;
    } catch (e) {
      print('Ошибка кэширования $url: $e');
      return null;
    }
  }

  Future<void> deleteImage(String url) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      columns: [_colPath],
      where: '$_colUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final path = rows.first[_colPath] as String;
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
      await db.delete(_table, where: '$_colUrl = ?', whereArgs: [url]);
    }
  }

  

  Future<String?> getImagePath(String url) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      columns: [_colPath],
      where: '$_colUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final path = rows.first[_colPath] as String;
    if (await File(path).exists()) {
      return path;
    } else {
      await db.delete(_table, where: '$_colUrl = ?', whereArgs: [url]);
      return null;
    }
  }

  Future<void> cacheImage(String url, {File? file}) async {
    final existingPath = await getImagePath(url);
    if (existingPath != null) {

      return;
    }

    final imagesDir = await _ensureImagesDir();
    String fileName;
    if (url.isNotEmpty) {
      final parsed = Uri.tryParse(url);
      final base = parsed != null ? p.basename(parsed.path) : '';
      fileName = base.isNotEmpty ? base : 'img_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      fileName = 'picked_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (p.extension(fileName).isEmpty) fileName = '$fileName.jpg';

    final target = File(p.join(imagesDir.path, fileName));
    if (file != null && await file.exists()) {
      await file.copy(target.path);
      print('Файл скопирован для $url: ${target.path}');
    } else if (url.isNotEmpty) {
      try {

        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) {

          return;
        }
        await target.writeAsBytes(res.bodyBytes);

      } catch (e) {

        return;
      }
    } else {
      return;
    }

    final db = await _database;
    await db.insert(
      _table,
      {
        _colUrl: url,
        _colPath: target.path,
        _colCreatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Запись в БД добавлена в cacheImage для $url');
  }

  Future<int> clearOldImages({Duration maxAge = const Duration(days: 30)}) async {
    final db = await _database;
    final threshold = DateTime.now().millisecondsSinceEpoch - maxAge.inMilliseconds;

    final rows = await db.query(
      _table,
      columns: [_colUrl, _colPath, _colCreatedAt],
      where: '$_colCreatedAt < ?',
      whereArgs: [threshold],
    );

    int removed = 0;
    for (final row in rows) {
      final path = row[_colPath] as String;
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      await db.delete(_table, where: '$_colUrl = ?', whereArgs: [row[_colUrl]]);
      removed++;
    }
    return removed;
  }

  
  dynamic _sanitizeForJson(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitizeForJson(v)));
    }
    if (value is List) {
      return value.map(_sanitizeForJson).toList();
    }
    if (value is Timestamp) {
      
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }

  Future<void> cacheCollection(String collectionName, List<Map<String, dynamic>> items) async {
    final db = await _database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS firestore_cache(
        collection TEXT NOT NULL,
        doc_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (collection, doc_id)
      )
    ''');

    await db.transaction((txn) async {
      await txn.delete('firestore_cache', where: 'collection = ?', whereArgs: [collectionName]);
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final item in items) {
        final id = item['id']?.toString() ?? '';
        
        final safe = _sanitizeForJson(item);
        final jsonData = jsonEncode(safe);
        await txn.insert(
          'firestore_cache',
          {
            'collection': collectionName,
            'doc_id': id,
            'data': jsonData,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getCachedCollection(String collectionName) async {
    final db = await _database;
    final rows = await db.query(
      'firestore_cache',
      columns: ['doc_id', 'data'],
      where: 'collection = ?',
      whereArgs: [collectionName],
      orderBy: 'created_at ASC',
    );
    final list = <Map<String, dynamic>>[];
    for (final row in rows) {
      try {
        final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        data['id'] = row['doc_id'];
        list.add(data);
      } catch (e) {
        
      }
    }
    return list;
  }

  Future<Map<String, dynamic>?> getCachedDocument(String collectionName, String docId) async {
    if (collectionName.isEmpty || docId.isEmpty) return null;
    final db = await _database;
    final rows = await db.query(
      'firestore_cache',
      columns: ['data'],
      where: 'collection = ? AND doc_id = ?',
      whereArgs: [collectionName, docId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final data = jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
      data['id'] = docId;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheDocument(String collectionName, String docId, Map<String, dynamic> item) async {
    if (collectionName.isEmpty || docId.isEmpty || item.isEmpty) return;
    final db = await _database;
    final safe = _sanitizeForJson(item);
    final jsonData = jsonEncode(safe);
    await db.insert(
      'firestore_cache',
      {
        'collection': collectionName,
        'doc_id': docId,
        'data': jsonData,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getCacheTimestamp(String collectionName) async {
    final db = await _database;
    final rows = await db.query(
      'firestore_cache',
      columns: ['created_at'],
      where: 'collection = ?',
      whereArgs: [collectionName],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ms = rows.first['created_at'] as int;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  

  Future<void> clearCollectionCache(String collectionName) async {
    try {
      final db = await _database;
      await db.delete('firestore_cache', where: 'collection = ?', whereArgs: [collectionName]);
      print('✅ DatabaseHelper: кеш для "$collectionName" очищен');
    } catch (e) {
      print('⚠️ DatabaseHelper: ошибка при очистке кеша "$collectionName": $e');
    }
  }

  Future<void> clearAllFirestoreCache() async {
    try {
      final db = await _database;
      await db.delete('firestore_cache');
      print('✅ DatabaseHelper: весь Firestore кэш очищен');
    } catch (e) {
      print('⚠️ DatabaseHelper: ошибка при очистке всего Firestore кеша: $e');
    }
  }

  Future<void> clearAllImages() async {
    final db = await _database;
    final rows = await db.query(_table, columns: [_colPath]);
    for (final row in rows) {
      try {
        final f = File(row[_colPath] as String);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await db.delete(_table);
  }

  
  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);
    _db = await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table(
            $_colUrl TEXT PRIMARY KEY,
            $_colPath TEXT NOT NULL,
            $_colCreatedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS firestore_cache(
            collection TEXT NOT NULL,
            doc_id TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (collection, doc_id)
          )
        ''');
      },
      onOpen: (db) async {
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS firestore_cache(
            collection TEXT NOT NULL,
            doc_id TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (collection, doc_id)
          )
        ''');
      },
    );
    return _db!;
  }

  Future<Directory> _ensureImagesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  

  
  

  


  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}


