import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';
import '../widgets/flip_card.dart';

/// Tesztmód képernyő — 20 véletlenszerű kérdés, vizsgaszimuláció
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _dbService = DatabaseService();

  static const int _kerdessek = 20;

  List<Flashcard> _kartyak = [];
  int _aktualisIndex = 0;
  bool _betoltes = true;
  bool _megfordult = false;

  // Eredmények nyomon követése
  final List<bool> _valaszok = []; // true = tudtam, false = nem tudtam

  @override
  void initState() {
    super.initState();
    _kartyakBetoltese();
  }

  Future<void> _kartyakBetoltese() async {
    final osszes = await _dbService.getOsszes();
    osszes.shuffle();
    final kivalasztott = osszes.take(_kerdessek).toList();

    setState(() {
      _kartyak = kivalasztott;
      _aktualisIndex = 0;
      _betoltes = false;
      _megfordult = false;
    });
  }

  Flashcard? get _aktualisKartya =>
      _kartyak.isNotEmpty && _aktualisIndex < _kartyak.length
          ? _kartyak[_aktualisIndex]
          : null;

  void _megforditas() {
    setState(() => _megfordult = true);
  }

  void _valaszt(bool tudtam) {
    _valaszok.add(tudtam);
    if (_aktualisIndex < _kartyak.length - 1) {
      setState(() {
        _aktualisIndex++;
        _megfordult = false;
      });
    } else {
      _vegeredmeny();
    }
  }

  void _vegeredmeny() {
    final helyes = _valaszok.where((v) => v).length;
    final osszes = _valaszok.length;
    final szazalek = (helyes / osszes * 100).round();

    // Magyar KRESZ vizsgán 86% kell az átmenéshez
    final megfelelt = szazalek >= 86;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(megfelelt ? 'Megfelelt!' : 'Nem felelt meg'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$szazalek%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: megfelelt ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('$helyes helyes / $osszes kérdés'),
            const SizedBox(height: 12),
            Text(
              megfelelt
                  ? 'Gratulálok! A valódi vizsgán is sikerülne!'
                  : 'A vizsgán 86% kell az átmenéshez. Még egy kis gyakorlás kell!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Vissza a főmenübe'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _valaszok.clear();
                _betoltes = true;
              });
              _kartyakBetoltese();
            },
            child: const Text('Újra'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tesztmód'),
        centerTitle: true,
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
      ),
      body: _betoltes
          ? const Center(child: CircularProgressIndicator())
          : _kartyak.isEmpty
              ? const Center(child: Text('Nincs elég kártya a teszthez.'))
              : Column(
                  children: [
                    // Vizsga fejléc
                    Container(
                      width: double.infinity,
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18, color: colorScheme.error),
                          const SizedBox(width: 6),
                          Text(
                            'Vizsgaszimuláció · ${_aktualisIndex + 1} / ${_kartyak.length}',
                            style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_valaszok.where((v) => v).length} ✓',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_valaszok.where((v) => !v).length} ✗',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Progress bar
                    LinearProgressIndicator(
                      value: (_aktualisIndex + 1) / _kartyak.length,
                      backgroundColor:
                          colorScheme.error.withValues(alpha: 0.15),
                      valueColor:
                          AlwaysStoppedAnimation(colorScheme.error),
                    ),

                    // A kártya
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _aktualisKartya != null
                            ? FlipCard(
                                card: _aktualisKartya!,
                                isMegfordult: _megfordult,
                                onTap: _megforditas,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),

                    // Gombok
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _megfordult
                          ? Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    label: const Text(
                                      'Nem tudtam',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    onPressed: () => _valaszt(false),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Tudtam'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    onPressed: () => _valaszt(true),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.flip),
                                label: const Text('Megfordítás'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                ),
                                onPressed: _megforditas,
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
