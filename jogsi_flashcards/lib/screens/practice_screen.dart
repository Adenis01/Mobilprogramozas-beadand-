import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';
import '../widgets/flip_card.dart';

/// Gyakorló képernyő — kártyák megforgatásával
class PracticeScreen extends StatefulWidget {
  final String? tema; // null = összes témakör

  const PracticeScreen({super.key, required this.tema});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _dbService = DatabaseService();
  List<Flashcard> _kartyak = [];
  int _aktualisIndex = 0;
  bool _betoltes = true;
  bool _megfordult = false; // látszik-e a hátlap

  @override
  void initState() {
    super.initState();
    _kartyakBetoltese();
  }

  Future<void> _kartyakBetoltese() async {
    List<Flashcard> kartyak;
    if (widget.tema != null) {
      kartyak = await _dbService.getEsedekes(tema: widget.tema);
      // Ha minden esedékes kártya el lett végezve, mutassuk az összeset
      if (kartyak.isEmpty) {
        kartyak = await _dbService.getKartyakTema(widget.tema!);
        kartyak.shuffle();
      }
    } else {
      kartyak = await _dbService.getEsedekes();
      if (kartyak.isEmpty) {
        kartyak = await _dbService.getOsszes();
        kartyak.shuffle();
      }
    }

    setState(() {
      _kartyak = kartyak;
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
    setState(() => _megfordult = !_megfordult);
  }

  Future<void> _tudtam() async {
    final kartya = _aktualisKartya;
    if (kartya == null) return;
    kartya.tudtam();
    await _dbService.updateKartya(kartya);
    _kovetkezo();
  }

  Future<void> _nemTudtam() async {
    final kartya = _aktualisKartya;
    if (kartya == null) return;
    kartya.nemTudtam();
    await _dbService.updateKartya(kartya);
    _kovetkezo();
  }

  void _kovetkezo() {
    if (_aktualisIndex < _kartyak.length - 1) {
      setState(() {
        _aktualisIndex++;
        _megfordult = false;
      });
    } else {
      // Vége a sorozatnak
      _vegeredmeny();
    }
  }

  void _vegeredmeny() {
    final osszes = _kartyak.length;
    final tudott = _kartyak.where((k) => k.tudtamSzam > k.nemTudtamSzam).length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Kör vége!'),
        content: Text(
          'Befejezted a kört!\n\n'
          'Összesen: $osszes kártya\n'
          'Tudtad: $tudott\n'
          'Nem tudtad: ${osszes - tudott}',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tema ?? 'Összes témakör'),
        centerTitle: true,
      ),
      body: _betoltes
          ? const Center(child: CircularProgressIndicator())
          : _kartyak.isEmpty
              ? const Center(child: Text('Nincsenek kártyák ebben a témakörben.'))
              : Column(
                  children: [
                    // Haladás jelző
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            '${_aktualisIndex + 1} / ${_kartyak.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (_aktualisIndex + 1) / _kartyak.length,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // A kártya maga (forgatható)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      padding: const EdgeInsets.all(24),
                      child: _megfordult
                          ? Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    label: const Text(
                                      'Nem tudtam',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onPressed: _nemTudtam,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Tudtam'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onPressed: _tudtam,
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
