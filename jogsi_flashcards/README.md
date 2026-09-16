# Jogsi Flashcards

Mobilalkalmazás beadandó – Udvardy Balázs

---

## Az ötlet

Amikor a jogosítvány elméleti vizsgájára készültem, azt vettem észre, hogy a legtöbb KRESZ-es app vagy csak teszteket kínál (ahol megnyomod a választ és kész), vagy rengeteg kérdést zúdít rád egyszerre, de nem segít abban, hogy melyiken kell még dolgozni. Ezért csináltam egy flashcard alapú appot, ahol a kártyás rendszer azt is figyelembe veszi, hogy mit tudsz és mit nem – amit nem tudsz, azt hamarabb dobja vissza, amit jól tudsz, azt egyre ritkábban mutatja.

## Funkciók

**Témakörök:** Az anyag négy témakörre van felosztva – elsőbbségadás, közlekedési táblák, sebességkorlátozás, büntetőpontok. Nem kell egyszerre az egészet átnyomni, hanem lehet célzottan csak egy témakörrel foglalkozni.

**Kártyaforgatás:** A kártyán az elején a kérdés látszik, rákoppintásra megfordul és megjelenik a válasz. Utána eldöntöd, hogy tudtad-e vagy sem.

**Okos ismétlés:** Ha azt mondod, hogy tudtad, a következő alkalommal tovább vár azzal a kártyával. Ha nem tudtad, hamar visszajön. Ez egy egyszerű spaced repetition rendszer, amit én implementáltam, nem külső könyvtár.

**Statisztika:** A főmenüből elérhető egy statisztika oldal, ahol látszik témakörönként, hogy hány kártyát ismersz már és hány százalékon állsz.

**Beépített kérdések:** Az app első indításkor betölt egy JSON fájlból ~25 kérdést, szóval nem indul üresen.

## Technológia

- **Flutter** (Dart) – cross-platform keretrendszer, Androidon teszteltem
- **SQLite** (sqflite csomag) – helyi adatbázis, szerver nem kell hozzá
- **Material 3** – a Flutter beépített UI rendszere

A projekt struktúrája:
```
lib/
├── models/        # adatmodellek (Flashcard)
├── services/      # adatbázis logika
├── screens/       # képernyők (főmenü, gyakorlás, statisztika)
└── widgets/       # újrafelhasználható elemek (flip kártya animáció)
```

## Futtatás

### Szükséges:
- Flutter SDK (3.x)
- Android Studio + Android emulátor (vagy fizikai Android eszköz)

### Lépések:

```bash
# Csomagok letöltése
flutter pub get

# Futtatás (emulátor indítása után)
flutter run
```

Ha az `flutter doctor` valami hiányzó Android SDK eszközt jelez, Android Studióban az SDK Manager → SDK Tools → Command-line Tools telepítésével megoldható.

## Ismert hibák / hiányosságok

- A kártyaforgatás animáció néha fagyhat le lassabb emulátoron, fizikai eszközön nem vettem észre ilyet
- Ha manuálisan kitörli valaki az adatbázist, az app következő indításnál újratölti a JSON-t, de a haladás elvész (ez amúgy szándékos reset-ként is használható)
- A beépített kérdések száma elég kevés (25 db), ezt lehetne bővíteni

## Fejlesztési lehetőségek

Amik az ötleteknél is szerepeltek, de időhiány miatt nem kerültek bele:

- **Tesztmód**: 20 véletlenszerű kérdés, a végén pontszám – mint egy mini vizsga
- **Emlékeztető értesítés**: "Ma még nem gyakoroltál" push notification
- **Tábla felismerős mód**: csak képet mutat, szöveg nélkül, azt kell felismerni
- Több kérdés hozzáadása (akár az összes KRESZ kérdés)

---

Neptun: I6UY10
