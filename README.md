# KRESZ tanulás kártyákkal

Mobilalkalmazás beadandó – Udvardy Balázs

---

## Az alkalmazás célja és funkciói

Egy KRESZ-tanulást segítő flashcard (kártyás) alkalmazás, amellyel témakörökre bontva, interaktív kártyaforgatással és vizsgaszimulációs tesztmóddal lehet gyakorolni az elméleti vizsgára. Az alkalmazás rögzíti a „Tudtam" / „Nem tudtam" válaszokat, így témakörönként nyomon követhető a tanulási haladás.

### Főbb funkciók

| Funkció | Leírás |
|---|---|
| **Témakörök** | 4 témakör: Elsőbbségadás, Közlekedési táblák, Sebességkorlátozás, Büntetőpontok |
| **Képes kérdések** | 11 db KRESZ-táblás és közlekedési ábrás kérdés külön gyakorlási és szűrési móddal |
| **Kérdésbank** | Összes kérdés böngészése, keresés és témakör/képes szűrés |
| **Kártyaforgatás** | 3D flip animáció — előlapon kérdés (és opcionális kép), hátlapon válasz |
| **Statisztika** | Témakörönkénti haladás százalékban, progress bar-ral a helyes válaszok aránya alapján |
| **Tesztmód** | 20 véletlenszerű kérdés, vizsgaszimulációként — a végén pontszám és 86%-os vizsgaértékelés |
| **Utolsó gyakorlás** | A főmenün látszik, mikor gyakoroltál utoljára |

---

## Technológia

- **Flutter** (Dart) – cross-platform keretrendszer, Androidon tesztelve
- **SQLite** (`sqflite` csomag) – helyi adatbázis, szerver nem szükséges
- **shared_preferences** – utolsó gyakorlás dátumának tárolásához
- **Material 3** – Flutter beépített modern UI rendszere

```
lib/
├── main.dart      # alkalmazás belépési pont, Material 3 világos/sötét téma
├── models/        # adatmodellek (Flashcard)
├── services/      # adatbázis logika (DatabaseService)
├── screens/       # képernyők (főmenü, gyakorlás, kérdésbank, statisztika, tesztmód)
└── widgets/       # újrafelhasználható elemek (FlipCard animáció)
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

> Ha `flutter doctor` valami hiányzó Android SDK eszközt jelez:  
> Android Studio → SDK Manager → SDK Tools → **Android SDK Command-line Tools** telepítése megoldja.

Az app első indításkor automatikusan betölti a beépített 50 KRESZ kérdést (köztük 11 képes táblakérdést) a `assets/data/kerdesek.json` fájlból — nem indul üresen.

---

## Ismert hibák / hiányosságok

- A kártyaforgatás animáció néha akadhat nagyon lassú emulátoron; fizikai eszközön nem tapasztalható
- Az adatbázis törlése esetén az app újrainduláskor visszaállítja az alap kérdéseket, de a korábbi haladás elvész (ez szándékos reset-ként is használható)
- A beépített kérdések száma (50 db) a valódi KRESZ vizsgához képest kevés — éles verzióban az összes ~800 kérdést lehetne belevenni

## Fejlesztési lehetőségek

- Több kérdés hozzáadása (az összes magyarországi KRESZ kérdés)
- Emlékeztető push notification: „Ma még nem gyakoroltál"
- Tábla felismerős mód: csak a tábla képe látszik, szöveg nélkül kell felismerni
- Felhasználói fiókok és felhőszinkronizáció

---

Neptun: I6UY10  
Oktató: Dávid Márta  
Határidő: 2026.11.18
