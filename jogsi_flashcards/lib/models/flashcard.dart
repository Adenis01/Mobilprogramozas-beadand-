/// Egy flashcard (kártya) modellje
class Flashcard {
  final String id;
  final String tema;
  final String kerdes;
  final String valasz;
  final String? kepUrl; // opcionális kép URL (pl. KRESZ tábla képe)

  // Tanulási statisztika mezők
  int tudtamSzam;     // hányszor nyomtuk a "Tudtam" gombot
  int nemTudtamSzam;  // hányszor nyomtuk a "Nem tudtam" gombot

  Flashcard({
    required this.id,
    required this.tema,
    required this.kerdes,
    required this.valasz,
    this.kepUrl,
    this.tudtamSzam = 0,
    this.nemTudtamSzam = 0,
  });

  /// Helyes választ adott — növeljük a számlálót
  void tudtam() {
    tudtamSzam++;
  }

  /// Helytelen válasz — növeljük a számlálót
  void nemTudtam() {
    nemTudtamSzam++;
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
      kepUrl: json['kep_url'] as String?,
    );
  }

  /// Adatbázisból létrehozás
  factory Flashcard.fromDb(Map<String, dynamic> row) {
    return Flashcard(
      id: row['id'] as String,
      tema: row['tema'] as String,
      kerdes: row['kerdes'] as String,
      valasz: row['valasz'] as String,
      kepUrl: row['kep_url'] as String?,
      tudtamSzam: row['tudtam_szam'] as int? ?? 0,
      nemTudtamSzam: row['nem_tudtam_szam'] as int? ?? 0,
    );
  }

  /// Adatbázisba mentéshez
  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'tema': tema,
      'kerdes': kerdes,
      'valasz': valasz,
      'kep_url': kepUrl,
      'tudtam_szam': tudtamSzam,
      'nem_tudtam_szam': nemTudtamSzam,
    };
  }
}
