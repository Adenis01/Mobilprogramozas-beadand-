import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'card_list_screen.dart';
import 'practice_screen.dart';
import 'stats_screen.dart';
import 'test_screen.dart';

/// Főképernyő — témakörök listája
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService();
  List<String> _temak = [];
  Map<String, Map<String, dynamic>> _statisztikak = {};
  int _kepesKartyakSzama = 0;
  bool _betoltes = true;
  String? _utolsoPakorlas; // shared_preferences-ből

  @override
  void initState() {
    super.initState();
    _betoltesInditas();
  }

  Future<void> _betoltesInditas() async {
    await Future.wait([
      _temakBetoltese(),
      _utolsoGakorlasBetoltese(),
    ]);
  }

  Future<void> _temakBetoltese() async {
    final temak = await _dbService.getTemakPor();
    final kepesSzam = await _dbService.getKepesKartyakSzama();
    final statMap = <String, Map<String, dynamic>>{};
    for (final tema in temak) {
      statMap[tema] = await _dbService.getStatisztika(tema);
    }
    if (mounted) {
      setState(() {
        _temak = temak;
        _statisztikak = statMap;
        _kepesKartyakSzama = kepesSzam;
        _betoltes = false;
      });
    }
  }

  Future<void> _utolsoGakorlasBetoltese() async {
    final prefs = await SharedPreferences.getInstance();
    final datum = prefs.getString('utolso_gyakorlas');
    if (datum != null && mounted) {
      setState(() => _utolsoPakorlas = _formatDatum(datum));
    }
  }

  String _formatDatum(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final most = DateTime.now();
      final kulonbseg = most.difference(dt);
      if (kulonbseg.inMinutes < 1) return 'Éppen most';
      if (kulonbseg.inMinutes < 60) return '${kulonbseg.inMinutes} perce';
      if (kulonbseg.inHours < 24) return '${kulonbseg.inHours} órája';
      if (kulonbseg.inDays == 1) return 'Tegnap';
      return '${kulonbseg.inDays} napja';
    } catch (_) {
      return '';
    }
  }

  IconData _temaIkon(String tema) {
    switch (tema) {
      case 'Elsőbbségadás':
        return Icons.traffic;
      case 'Közlekedési táblák':
        return Icons.signpost;
      case 'Sebességkorlátozás':
        return Icons.speed;
      case 'Büntetőpontok':
        return Icons.gavel;
      default:
        return Icons.menu_book;
    }
  }

  Color _temaColor(String tema) {
    switch (tema) {
      case 'Elsőbbségadás':
        return Colors.orange;
      case 'Közlekedési táblák':
        return Colors.blue;
      case 'Sebességkorlátozás':
        return Colors.red;
      case 'Büntetőpontok':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  Future<void> _utolsoGakarlasElmentese() async {
    final prefs = await SharedPreferences.getInstance();
    final most = DateTime.now().toIso8601String();
    await prefs.setString('utolso_gyakorlas', most);
    if (mounted) {
      setState(() => _utolsoPakorlas = _formatDatum(most));
    }
  }

  void _gyakorlasInditas(String? tema, {bool csakKepes = false}) async {
    await _utolsoGakarlasElmentese();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          tema: tema,
          csakKepes: csakKepes,
        ),
      ),
    );
    _temakBetoltese();
  }

  Future<void> _szinkronizalas() async {
    final db = DatabaseService();
    final count = await db.resyncFromAssets();
    await _temakBetoltese();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $count kérdés és KRESZ tábla szinkronizálva!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🚗 Jogsi Flashcards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Kérdések újraszinkronizálása a JSON-ból',
            onPressed: _szinkronizalas,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Kérdésbank / Kártyák böngészése',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardListScreen()),
              );
              _temakBetoltese();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statisztika',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
              _temakBetoltese();
            },
          ),
        ],
      ),
      body: _betoltes
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _szinkronizalas,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Utolsó gyakorlás info chip
                  if (_utolsoPakorlas != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.history,
                              size: 16,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text(
                            'Utolsó gyakorlás: $_utolsoPakorlas',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Kiemelt banner: KÉPES KÉRDÉSEK ÉS KRESZ TÁBLÁK
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CardListScreen(
                                kezdetbenCsakKepes: true),
                          ),
                        );
                        _temakBetoltese();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE65100), // Narancssárga
                              Color(0xFFF57C00),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.image,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '🖼️ Képes Kérdések',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$_kepesKartyakSzama db',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'KRESZ táblák (STOP, elsőbbség, körforgalom...)',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFE65100),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              onPressed: () =>
                                  _gyakorlasInditas(null, csakKepes: true),
                              child: const Text('Gyakorlás'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Kérdésbank / böngészés gomb
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child:
                            Icon(Icons.menu_book, color: colorScheme.primary),
                      ),
                      title: const Text(
                        '📚 Kérdésbank (Összes kérdés listája)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Keresés, szűrés és kártyák megtekintése',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CardListScreen()),
                        );
                        _temakBetoltese();
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Témakörök szerinti gyakorlás:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Témakör kártyák
                  ..._temak.map((tema) {
                    final stat = _statisztikak[tema];
                    final arany = stat != null
                        ? (stat['sikerarany'] as double)
                        : 0.0;
                    final vanKep = tema == 'Elsőbbségadás' ||
                        tema == 'Közlekedési táblák' ||
                        tema == 'Sebességkorlátozás';

                    return _TemakorKartya(
                      tema: tema,
                      ikon: _temaIkon(tema),
                      szin: _temaColor(tema),
                      arany: arany,
                      vanKep: vanKep,
                      onTap: () => _gyakorlasInditas(tema),
                    );
                  }),

                  const SizedBox(height: 4),

                  // „Összes témakör" gomb
                  _TemakorKartya(
                    tema: 'Összes témakör',
                    ikon: Icons.shuffle,
                    szin: Colors.teal,
                    arany: null,
                    vanKep: false,
                    onTap: () => _gyakorlasInditas(null),
                  ),

                  const SizedBox(height: 20),

                  // Tesztmód gomb (kiemelt)
                  Card(
                    color: colorScheme.errorContainer,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            colorScheme.error.withValues(alpha: 0.2),
                        child: Icon(Icons.quiz, color: colorScheme.error),
                      ),
                      title: Text(
                        '🧪 Tesztmód',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      subtitle: Text(
                        '20 véletlen kérdés · vizsgaszimuláció',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: colorScheme.onErrorContainer),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TestScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _TemakorKartya extends StatelessWidget {
  final String tema;
  final IconData ikon;
  final Color szin;
  final double? arany; // null = nem mutatunk %-ot (pl. "összes" módnál)
  final bool vanKep;
  final VoidCallback onTap;

  const _TemakorKartya({
    required this.tema,
    required this.ikon,
    required this.szin,
    required this.arany,
    this.vanKep = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: szin.withValues(alpha: 0.15),
                child: Icon(ikon, color: szin),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tema,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (vanKep) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '🖼️ Képes',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (arany != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: arany,
                                backgroundColor: szin.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation(szin),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(arany! * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: szin,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
