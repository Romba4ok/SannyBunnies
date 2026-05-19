import 'dart:io';
import 'dart:typed_data';

import 'package:sannybunnies/services/database_helper.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  // Collection/document cache
  Future<void> cacheCollection(String collectionName, List<Map<String, dynamic>> items) async {
    return await DatabaseHelper().cacheCollection(collectionName, items);
  }

  Future<List<Map<String, dynamic>>> getCachedCollection(String collectionName) async {
    return await DatabaseHelper().getCachedCollection(collectionName);
  }

  Future<void> cacheDocument(String collectionName, String docId, Map<String, dynamic> item) async {
    return await DatabaseHelper().cacheDocument(collectionName, docId, item);
  }

  Future<Map<String, dynamic>?> getCachedDocument(String collectionName, String docId) async {
    return await DatabaseHelper().getCachedDocument(collectionName, docId);
  }

  Future<DateTime?> getCacheTimestamp(String collectionName) async {
    return await DatabaseHelper().getCacheTimestamp(collectionName);
  }

  Future<void> clearCollectionCache(String collectionName) async {
    return await DatabaseHelper().clearCollectionCache(collectionName);
  }

  Future<void> clearAllFirestoreCache() async {
    return await DatabaseHelper().clearAllFirestoreCache();
  }

  // Image cache
  Future<List<int>?> getCachedImage(String url) async {
    return await DatabaseHelper().getCachedImage(url);
  }

  Future<void> cacheImage(String url, {File? file}) async {
    return await DatabaseHelper().cacheImage(url, file: file);
  }

  Future<void> deleteImage(String url) async {
    return await DatabaseHelper().deleteImage(url);
  }

  Future<int> clearOldImages({Duration maxAge = const Duration(days: 30)}) async {
    return await DatabaseHelper().clearOldImages(maxAge: maxAge);
  }
}
