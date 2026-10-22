import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/flashcard.dart';

/// Adatbázis szolgáltatás — SQLite alapú helyi tárolás
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jogsi_flashcards.db');

    final database = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    // Automatikusan szinkronizáljuk a JSON kérdéseket és képeket az adatbázissal
    await resyncFromAssets(database);
    return database;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        tema TEXT NOT NULL,
        kerdes TEXT NOT NULL,
        valasz TEXT NOT NULL,
        kep_url TEXT,
        tudtam_szam INTEGER DEFAULT 0,
        nem_tudtam_szam INTEGER DEFAULT 0,
        interval_nap REAL DEFAULT 1.0,
        kovetkezo_megmutatas TEXT
      )
    ''');

    // Betöltjük az alap KRESZ kérdéseket az assets fájlból
    await _seedFromAssets(db);
  }

  /// Adatbázis migráció — régi DB-khez hozzáadja a kép oszlopot és frissíti a kérdéseket
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE flashcards ADD COLUMN kep_url TEXT');
      } catch (_) {}
    }
    await resyncFromAssets(db);
  }

  /// JSON-ból frissíti a kep_url mezőket és hozzáadja az új kérdéseket
  /// — a meglévő haladást (tudtam_szam, interval stb.) megtartja
  Future<int> resyncFromAssets([Database? customDb]) async {
    try {
      final dbInstance = customDb ?? await db;

      // Biztosítjuk, hogy a kep_url oszlop létezzen régi adatbázisoknál is
      try {
        await dbInstance.execute('ALTER TABLE flashcards ADD COLUMN kep_url TEXT');
      } catch (_) {}

      final String jsonStr =
          await rootBundle.loadString('assets/data/kerdesek.json');
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;

      int frissitve = 0;
      for (final item in jsonList) {
        final card = Flashcard.fromJson(item as Map<String, dynamic>);
        // Frissítjük a kártya kép URL-jét, kérdését, válaszát, témáját
        final updated = await dbInstance.rawUpdate(
          '''
          UPDATE flashcards
          SET kep_url = ?, kerdes = ?, valasz = ?, tema = ?
          WHERE id = ?
          ''',
          [card.kepUrl, card.kerdes, card.valasz, card.tema, card.id],
        );
        // Ha nem létezett még ez a kártya, beszúrjuk
        if (updated == 0) {
          await dbInstance.insert(
            'flashcards',
            card.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        frissitve++;
      }
      return frissitve;
    } catch (e) {
      return 0;
    }
  }

  /// Alap kérdések betöltése a kerdesek.json fájlból
  Future<void> _seedFromAssets(Database db) async {
    try {
      final String jsonStr =
          await rootBundle.loadString('assets/data/kerdesek.json');
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;

      final batch = db.batch();
      for (final item in jsonList) {
        final card = Flashcard.fromJson(item as Map<String, dynamic>);
        batch.insert('flashcards', card.toDb(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Ha nem sikerül, az app üres adatbázissal indul
    }
  }

  /// Az összes kártya lekérése témakör szerint szűrve
  Future<List<Flashcard>> getKartyakTema(String tema) async {
    final database = await db;
    final rows = await database.query(
      'flashcards',
      where: 'tema = ?',
      whereArgs: [tema],
      orderBy: 'kovetkezo_megmutatas ASC',
    );
    return rows.map(Flashcard.fromDb).toList();
  }

  /// Az összes kártya lekérése
  Future<List<Flashcard>> getOsszes() async {
    final database = await db;
    final rows = await database.query('flashcards');
    return rows.map(Flashcard.fromDb).toList();
  }

  /// Esedékes kártyák lekérése (spaced repetition)
  Future<List<Flashcard>> getEsedekes({String? tema}) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();

    List<Map<String, dynamic>> rows;
    if (tema != null) {
      rows = await database.query(
        'flashcards',
        where: 'tema = ? AND (kovetkezo_megmutatas IS NULL OR kovetkezo_megmutatas <= ?)',
        whereArgs: [tema, now],
        orderBy: 'kovetkezo_megmutatas ASC',
      );
    } else {
      rows = await database.query(
        'flashcards',
        where: 'kovetkezo_megmutatas IS NULL OR kovetkezo_megmutatas <= ?',
        whereArgs: [now],
        orderBy: 'kovetkezo_megmutatas ASC',
      );
    }
    return rows.map(Flashcard.fromDb).toList();
  }

  /// Kártya frissítése (pl. tudom/nem tudom után)
  Future<void> updateKartya(Flashcard card) async {
    final database = await db;
    await database.update(
      'flashcards',
      card.toDb(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Az összes témakör lekérése
  Future<List<String>> getTemakPor() async {
    final database = await db;
    final rows = await database.rawQuery(
        'SELECT DISTINCT tema FROM flashcards ORDER BY tema ASC');
    return rows.map((r) => r['tema'] as String).toList();
  }

  /// Statisztika egy témakörre
  Future<Map<String, dynamic>> getStatisztika(String tema) async {
    final database = await db;
    final rows = await database.query(
      'flashcards',
      where: 'tema = ?',
      whereArgs: [tema],
    );
    final cards = rows.map(Flashcard.fromDb).toList();
    final osszes = cards.length;
    final tudott = cards.where((c) => c.sikerArany >= 0.7).length;

    return {
      'tema': tema,
      'osszes': osszes,
      'tudott': tudott,
      'nem_tudott': osszes - tudott,
      'sikerarany': osszes > 0 ? tudott / osszes : 0.0,
    };
  }

  /// Csak a képpel rendelkező kártyák lekérése
  Future<List<Flashcard>> getKepesKartyak() async {
    final database = await db;
    final rows = await database.query(
      'flashcards',
      where: 'kep_url IS NOT NULL AND kep_url != ""',
      orderBy: 'tema ASC',
    );
    return rows.map(Flashcard.fromDb).toList();
  }

  /// Képes kártyák száma
  Future<int> getKepesKartyakSzama() async {
    final database = await db;
    final res = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM flashcards WHERE kep_url IS NOT NULL AND kep_url != ""',
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Teljes adatbázis újratelepítése (törlés és újratöltés a legfrissebb JSON-ból)
  Future<void> resetDatabase() async {
    final database = await db;
    await database.delete('flashcards');
    await _seedFromAssets(database);
  }
}

