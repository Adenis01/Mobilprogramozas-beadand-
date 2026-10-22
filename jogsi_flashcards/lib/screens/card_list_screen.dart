import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';
import '../widgets/flip_card.dart';
import 'practice_screen.dart';

/// Kártyák böngészése / Kérdésbank képernyő
class CardListScreen extends StatefulWidget {
  final bool kezdetbenCsakKepes;

  const CardListScreen({super.key, this.kezdetbenCsakKepes = false});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final _dbService = DatabaseService();
  List<Flashcard> _osszesKartya = [];
  List<Flashcard> _szurtKartyak = [];
  bool _betoltes = true;

  String _kereses = '';
  String? _kivalasztottTema;
  late bool _csakKepes;

  @override
  void initState() {
    super.initState();
    _csakKepes = widget.kezdetbenCsakKepes;
    _betoltesKartyak();
  }

  Future<void> _betoltesKartyak() async {
    final kartyak = await _dbService.getOsszes();
    if (mounted) {
      setState(() {
        _osszesKartya = kartyak;
        _betoltes = false;
        _szuresAlkalmazasa();
      });
    }
  }

  void _szuresAlkalmazasa() {
    setState(() {
      _szurtKartyak = _osszesKartya.where((k) {
        // Képes szűrés
        if (_csakKepes && (k.kepUrl == null || k.kepUrl!.isEmpty)) {
          return false;
        }
        // Téma szűrés
        if (_kivalasztottTema != null && k.tema != _kivalasztottTema) {
          return false;
        }
        // Keresőszó szűrés
        if (_kereses.isNotEmpty) {
          final query = _kereses.toLowerCase();
          final kerdesEgyezik = k.kerdes.toLowerCase().contains(query);
          final valaszEgyezik = k.valasz.toLowerCase().contains(query);
          final temaEgyezik = k.tema.toLowerCase().contains(query);
          if (!kerdesEgyezik && !valaszEgyezik && !temaEgyezik) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _kartyaMegnyitasa(Flashcard card) {
    showDialog(
      context: context,
      builder: (ctx) => _CardPreviewDialog(card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kepesDarab =
        _osszesKartya.where((k) => k.kepUrl != null && k.kepUrl!.isNotEmpty).length;

    final temak =
        _osszesKartya.map((k) => k.tema).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kérdésbank és Képek'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Kérdések újraszinkronizálása a JSON-ból',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final count = await _dbService.resyncFromAssets();
              await _betoltesKartyak();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count kérdés sikeresen szinkronizálva!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _betoltes
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Gyakorlás indítása banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.tertiaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Képes KRESZ kérdések: $kepesDarab db',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Gyakorold külön a táblákat és ábrákat!',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Gyakorlás'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PracticeScreen(
                                tema: null,
                                csakKepes: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Kereső mező
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Keresés a kérdések és válaszok között...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _kereses.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _kereses = '';
                                  _szuresAlkalmazasa();
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      _kereses = val;
                      _szuresAlkalmazasa();
                    },
                  ),
                ),

                // Szűrő sáv
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Csak képes kérdések kapcsoló chip
                      FilterChip(
                        avatar: const Text('🖼️'),
                        label: Text('Csak képes ($kepesDarab)'),
                        selected: _csakKepes,
                        selectedColor: colorScheme.primaryContainer,
                        onSelected: (val) {
                          setState(() {
                            _csakKepes = val;
                            _szuresAlkalmazasa();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Összes téma chip
                      ChoiceChip(
                        label: const Text('Minden témakör'),
                        selected: _kivalasztottTema == null,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _kivalasztottTema = null;
                              _szuresAlkalmazasa();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      // Témakörönkénti chipek
                      for (final tema in temak) ...[
                        ChoiceChip(
                          label: Text(tema),
                          selected: _kivalasztottTema == tema,
                          onSelected: (val) {
                            setState(() {
                              _kivalasztottTema = val ? tema : null;
                              _szuresAlkalmazasa();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),

                // Találati számláló
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Találatok: ${_szurtKartyak.length} db kártya',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Kártyák listája
                Expanded(
                  child: _szurtKartyak.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              const Text('Nincs a feltételeknek megfelelő kérdés'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _szurtKartyak.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final card = _szurtKartyak[index];
                            final vanKep = card.kepUrl != null &&
                                card.kepUrl!.isNotEmpty;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: vanKep
                                    ? BorderSide(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        width: 1.5,
                                      )
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _kartyaMegnyitasa(card),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Kép vagy ikon
                                      if (vanKep)
                                        Container(
                                          width: 64,
                                          height: 64,
                                          margin:
                                              const EdgeInsets.only(right: 14),
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: colorScheme.outlineVariant,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: card.kepUrl!
                                                  .startsWith('assets/')
                                              ? Image.asset(
                                                  card.kepUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (c, err, st) =>
                                                      const Icon(Icons
                                                          .broken_image,
                                                          size: 28),
                                                )
                                              : Image.network(
                                                  card.kepUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (c, err, st) =>
                                                      const Icon(Icons
                                                          .broken_image,
                                                          size: 28),
                                                ),
                                        )
                                      else
                                        Container(
                                          width: 48,
                                          height: 48,
                                          margin:
                                              const EdgeInsets.only(right: 14),
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .secondaryContainer
                                                .withValues(alpha: 0.4),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.help_outline,
                                            color: colorScheme.secondary,
                                          ),
                                        ),

                                      // Kérdés és téma szöveg
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Text(
                                                    card.tema,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                                if (vanKep) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withValues(alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Text(
                                                      '🖼️ Képes',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              card.kerdes,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Válasz: ${card.valasz}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Icon(Icons.chevron_right, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Kártya részletes előnézeti dialógusa
class _CardPreviewDialog extends StatefulWidget {
  final Flashcard card;

  const _CardPreviewDialog({required this.card});

  @override
  State<_CardPreviewDialog> createState() => _CardPreviewDialogState();
}

class _CardPreviewDialogState extends State<_CardPreviewDialog> {
  bool _megfordult = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 440,
            child: FlipCard(
              card: widget.card,
              isMegfordult: _megfordult,
              onTap: () {
                setState(() => _megfordult = !_megfordult);
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
            icon: const Icon(Icons.close),
            label: const Text('Bezárás'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
