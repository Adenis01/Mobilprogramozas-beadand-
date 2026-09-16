/// Egy flashcard (kártya) modellje
class Flashcard {
  final String id;
  final String tema;
  final String kerdes;
  final String valasz;

  // Spaced repetition mezők (a "okos ismétlés" logikájához)
  int tudtamSzam;     // hányszor nyomtuk a "Tudom" gombot
  int nemTudtamSzam;  // hányszor nyomtuk a "Nem tudom" gombot
  double interval;    // napokban, mikor kell következő alkalommal megmutatni
  DateTime? kovetkezoMegmutatas;

  Flashcard({
    required this.id,
    required this.tema,
    required this.kerdes,
    required this.valasz,
    this.tudtamSzam = 0,
    this.nemTudtamSzam = 0,
    this.interval = 1.0,
    this.kovetkezoMegmutatas,
  });

  /// Helyes választ adott — növeljük az intervalt (ritkábban kell majd)
  void tudtam() {
    tudtamSzam++;
    // Egyszerű spaced repetition: minden helyes válasznál duplázódik az interval
    if (interval < 1) {
      interval = 1;
    } else {
      interval = interval * 2.0;
    }
    if (interval > 30) interval = 30; // max 30 nap
    kovetkezoMegmutatas = DateTime.now().add(Duration(hours: (interval * 24).round()));
  }

  /// Helytelen válasz — visszaállítjuk az intervalt (hamarabb kell majd)
  void nemTudtam() {
    nemTudtamSzam++;
    interval = 0.5; // fél nap múlva jelenjen meg újra
    kovetkezoMegmutatas = DateTime.now().add(const Duration(hours: 12));
  }

  /// Esedékes-e a kártya megmutatásra?
  bool get esedekesE {
    if (kovetkezoMegmutatas == null) return true;
    return DateTime.now().isAfter(kovetkezoMegmutatas!);
  }

  /// Hány %-os a sikerességi arány ennél a kártyánál?
  double get sikerArany {
    final osszesen = tudtamSzam + nemTudtamSzam;
    if (osszesen == 0) return 0.0;
    return tudtamSzam / osszesen;
  }

  /// JSON-ból létrehozás (az assets fájlból való betöltéshez)
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      tema: json['tema'] as String,
      kerdes: json['kerdes'] as String,
      valasz: json['valasz'] as String,
    );
  }

  /// Adatbázisból létrehozás
  factory Flashcard.fromDb(Map<String, dynamic> row) {
    return Flashcard(
      id: row['id'] as String,
      tema: row['tema'] as String,
      kerdes: row['kerdes'] as String,
      valasz: row['valasz'] as String,
      tudtamSzam: row['tudtam_szam'] as int? ?? 0,
      nemTudtamSzam: row['nem_tudtam_szam'] as int? ?? 0,
      interval: (row['interval_nap'] as num?)?.toDouble() ?? 1.0,
      kovetkezoMegmutatas: row['kovetkezo_megmutatas'] != null
          ? DateTime.parse(row['kovetkezo_megmutatas'] as String)
          : null,
    );
  }

  /// Adatbázisba mentéshez
  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'tema': tema,
      'kerdes': kerdes,
      'valasz': valasz,
      'tudtam_szam': tudtamSzam,
      'nem_tudtam_szam': nemTudtamSzam,
      'interval_nap': interval,
      'kovetkezo_megmutatas': kovetkezoMegmutatas?.toIso8601String(),
    };
  }
}
