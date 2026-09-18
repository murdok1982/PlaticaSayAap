import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';

class ConversationEntry {
  final int? id;
  final DateTime timestamp;
  final String sourceLang;
  final String targetLang;
  final String sourceText;
  final String translatedText;

  const ConversationEntry({
    this.id,
    required this.timestamp,
    required this.sourceLang,
    required this.targetLang,
    required this.sourceText,
    required this.translatedText,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'source_text': sourceText,
        'translated_text': translatedText,
      };

  static ConversationEntry fromMap(Map<String, Object?> map) => ConversationEntry(
        id: map['id'] as int?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        sourceLang: map['source_lang'] as String,
        targetLang: map['target_lang'] as String,
        sourceText: map['source_text'] as String,
        translatedText: map['translated_text'] as String,
      );
}

class HistoryStore {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = '${await getDatabasesPath()}/${AppConstants.dbName}';
    _db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            source_lang TEXT NOT NULL,
            target_lang TEXT NOT NULL,
            source_text TEXT NOT NULL,
            translated_text TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> insert(ConversationEntry entry) async {
    final db = await database;
    return db.insert('history', entry.toMap());
  }

  Future<List<ConversationEntry>> recent({int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(ConversationEntry.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('history');
  }
}
