import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'practice_screen.dart';
import 'stats_screen.dart';

/// Főképernyő — témakörök listája
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService();
  List<String> _temak = [];
  bool _betoltes = true;

  @override
  void initState() {
    super.initState();
    _temakBetoltese();
  }

  Future<void> _temakBetoltese() async {
    final temak = await _dbService.getTemakPor();
    setState(() {
      _temak = temak;
      _betoltes = false;
    });
  }

  // Témakörönként egy ikon
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🚗 Jogsi Flashcards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statisztika',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
        ],
      ),
      body: _betoltes
          ? const Center(child: CircularProgressIndicator())
          : _temak.isEmpty
              ? const Center(
                  child: Text('Nincsenek témakörök. Próbáld újraindítani az appot.'),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Válassz témakört a gyakorláshoz:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ..._temak.map((tema) => _TemakorKartya(
                          tema: tema,
                          ikon: _temaIkon(tema),
                          szin: _temaColor(tema),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PracticeScreen(tema: tema),
                              ),
                            );
                          },
                        )),
                    const SizedBox(height: 8),
                    // "Mind" gomb — az összes témakör keverve
                    _TemakorKartya(
                      tema: 'Összes témakör',
                      ikon: Icons.shuffle,
                      szin: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PracticeScreen(tema: null),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}

class _TemakorKartya extends StatelessWidget {
  final String tema;
  final IconData ikon;
  final Color szin;
  final VoidCallback onTap;

  const _TemakorKartya({
    required this.tema,
    required this.ikon,
    required this.szin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: szin.withValues(alpha: 0.15),
          child: Icon(ikon, color: szin),
        ),
        title: Text(
          tema,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
