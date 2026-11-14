import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flashcard.dart';

/// 3D megforgatható kártya widget — képtámogatással
class FlipCard extends StatefulWidget {
  final Flashcard card;
  final bool isMegfordult;
  final VoidCallback onTap;

  const FlipCard({
    super.key,
    required this.card,
    required this.isMegfordult,
    required this.onTap,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMegfordult != oldWidget.isMegfordult) {
      if (widget.isMegfordult) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    // Ha új kártyára váltunk, azonnal visszaforgatjuk
    if (widget.card.id != oldWidget.card.id) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final showBack = angle > pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspektíva
              ..rotateY(angle),
            alignment: Alignment.center,
            child: showBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _CardFace(
                      szoveg: widget.card.valasz,
                      tema: widget.card.tema,
                      kepUrl: null, // válasz oldalon nem mutatjuk a képet
                      isElolap: false,
                    ),
                  )
                : _CardFace(
                    szoveg: widget.card.kerdes,
                    tema: widget.card.tema,
                    kepUrl: widget.card.kepUrl, // kérdés oldalon mutatjuk a képet
                    isElolap: true,
                  ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String szoveg;
  final String tema;
  final String? kepUrl;
  final bool isElolap;

  const _CardFace({
    required this.szoveg,
    required this.tema,
    required this.kepUrl,
    required this.isElolap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vanKep = kepUrl != null && kepUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isElolap
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fejléc chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isElolap
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isElolap ? 'Kérdés' : 'Válasz',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isElolap ? colorScheme.primary : colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tema,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),

            // Kép megjelenítése (ha van: local asset vagy network URL)
            if (vanKep) ...[
              Flexible(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kepUrl!.startsWith('assets/')
                      ? Image.asset(
                          kepUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => _buildImageError(colorScheme),
                        )
                      : Image.network(
                          kepUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) => _buildImageError(colorScheme),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Fő szöveg
            Flexible(
              flex: vanKep ? 2 : 4,
              child: Center(
                child: Text(
                  szoveg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: vanKep ? 15 : 18,
                    height: 1.5,
                    color: isElolap
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Tipp (csak ha nincs kép, hogy ne toljuk ki a layoutot)
            if (isElolap && !vanKep) ...[
              const SizedBox(height: 16),
              Text(
                'Koppints a megfordításhoz →',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image_outlined,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        Text(
          'Kép nem tölthető be',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
