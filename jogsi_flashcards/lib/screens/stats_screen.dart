import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// Statisztika képernyő — témakörönkénti haladás
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _dbService = DatabaseService();
  List<Map<String, dynamic>> _statisztikak = [];
  bool _betoltes = true;

  @override
  void initState() {
    super.initState();
    _statisztikakBetoltese();
  }

  Future<void> _statisztikakBetoltese() async {
    final temak = await _dbService.getTemakPor();
    final stats = <Map<String, dynamic>>[];
    for (final tema in temak) {
      stats.add(await _dbService.getStatisztika(tema));
    }
    setState(() {
      _statisztikak = stats;
      _betoltes = false;
    });
  }

  Color _szinArany(double arany) {
    if (arany >= 0.8) return Colors.green;
    if (arany >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statisztika'),
        centerTitle: true,
      ),
      body: _betoltes
          ? const Center(child: CircularProgressIndicator())
          : _statisztikak.isEmpty
              ? const Center(child: Text('Még nincs statisztika.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Témakörönkénti haladás',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._statisztikak.map((stat) {
                      final arany = (stat['sikerarany'] as double);
                      final szin = _szinArany(arany);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat['tema'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: arany,
                                        backgroundColor: szin.withValues(alpha: 0.2),
                                        valueColor: AlwaysStoppedAnimation(szin),
                                        minHeight: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(arany * 100).round()}%',
                                    style: TextStyle(
                                      color: szin,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stat['tudott']} / ${stat['osszes']} kártya ismert',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
