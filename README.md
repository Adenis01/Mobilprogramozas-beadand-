# Jogsi Flashcards

Mobilalkalmazás beadandó – Udvardy Balázs

---

## Az alkalmazás célja és funkciói

Egy KRESZ-tanulást segítő flashcard (kártyás) alkalmazás, amely **spaced repetition** (okos ismétléses) rendszerrel működik. A legtöbb KRESZ-es app csak teszteket kínál vagy véletlenszerűen kavarja a kérdéseket — ez az app azt is figyeli, mit tudsz és mit nem: amit nem tudsz, hamarabb visszadobja, amit jól tudsz, egyre ritkábban mutatja.

### Főbb funkciók

| Funkció | Leírás |
|---|---|
| **Témakörök** | 4 témakör: Elsőbbségadás, Közlekedési táblák, Sebességkorlátozás, Büntetőpontok |
| **Képes KRESZ kérdések** | KRESZ-táblákat tartalmazó képes kérdések külön gyakorlási móddal (STOP, elsőbbségadás, körforgalom, lakó-pihenő övezet stb.) |
| **Kártyaforgatás** | 3D flip animáció — előlapon a kérdés (és KRESZ-tábla képe), hátlapon a válasz |
| **Okos ismétlés** | Saját implementációjú spaced repetition: tudtam → ritkábban jön, nem tudtam → hamarabb visszajön |
| **Kérdésbank és kereső** | Az összes kártya böngészése, szabadszavas keresés, témakör- és képes szűrés, valamint kártya-előnézet |
| **Statisztika** | Témakörönkénti haladás százalékban, színkódolt progress bar-ral |
| **Tesztmód** | 20 véletlenszerű kérdés vizsgaszimulációként — a végén pontszám és értékelés (86%-os küszöbbel) |
| **Utolsó gyakorlás** | A főmenün látszik, mikor gyakoroltál utoljára |

---

## Technológia

- **Flutter** (Dart) – cross-platform keretrendszer, Androidon tesztelve
- **SQLite** (`sqflite` csomag) – helyi adatbázis a kártyák és a tanulási haladás tárolásához, automatikus JSON-szinkronizációval
- **shared_preferences** – utolsó gyakorlás dátumának tárolásához
- **Material 3** – Flutter modern UI rendszere automatikus világos/sötét témával (`ThemeMode.system`)

```
lib/
├── models/        # adatmodellek (Flashcard + spaced repetition logika)
├── services/      # adatbázis logika és szinkronizáció (DatabaseService)
├── screens/       # képernyők (főmenü, gyakorlás, kérdésbank, statisztika, tesztmód)
└── widgets/       # újrafelhasználható elemek (FlipCard 3D animáció)
```

---

## Telepítési / futtatási útmutató

### Szükséges

- Flutter SDK 3.x (`flutter --version` a verzió ellenőrzéséhez)
- Android Studio + Android emulátor, vagy fizikai Android eszköz (USB debugging bekapcsolva)

### Lépések

```bash
# 1. Csomagok letöltése
cd jogsi_flashcards
flutter pub get

# 2. Emulátor indítása (Android Studio-ból, vagy parancssorból)
# 3. Futtatás
flutter run
```

> Ha a `flutter doctor` valami hiányzó Android SDK eszközt jelez:  
> Android Studio → SDK Manager → SDK Tools → **Android SDK Command-line Tools** telepítése megoldja.

Az app első indításkor automatikusan betölti és szinkronizálja a beépített 50 KRESZ kérdést az `assets/data/kerdesek.json` fájlból és a KRESZ-tábla képeket az `assets/images/` mappából — nem indul üresen.

---

## Ismert hibák / hiányosságok

- A kártyaforgatás animáció nagyon lassú emulátoron néha megakadhat; fizikai eszközön folyamatos
- Az adatbázis törlése esetén az app újrainduláskor visszaállítja az alap kérdéseket, de a korábbi haladás elvész (ez szándékos reset-ként is használható)
- A beépített kérdések száma (50 db) a valódi KRESZ vizsgához képest kevesebb — éles verzióban a teljes hivatalos kérdésbankot érdemes belevenni

## Jövőbeni fejlesztési lehetőségek

- Több kérdés hozzáadása (az összes magyarországi KRESZ vizsgakérdés és forgalmi szituációs ábra)
- Emlékeztető push notification: „Ma még nem gyakoroltál"
- Feleletválasztós (A/B/C/D) vizsgamód a kártyás önértékelés mellett
- Felhasználói fiókok és felhőszinkronizáció

---

Neptun: I6UY10  
Oktató: Dávid Márta  
Határidő: 2026.11.18
