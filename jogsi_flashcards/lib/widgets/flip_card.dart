import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flashcard.dart';

/// 3D megforgatható kártya widget
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
                      isElolap: false,
                    ),
                  )
                : _CardFace(
                    szoveg: widget.card.kerdes,
                    tema: widget.card.tema,
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
  final bool isElolap;

  const _CardFace({
    required this.szoveg,
    required this.tema,
    required this.isElolap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fejléc
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isElolap
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isElolap ? '❓ Kérdés' : '✅ Válasz',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isElolap ? colorScheme.primary : colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tema,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            // Fő szöveg
            Text(
              szoveg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                color: isElolap
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            // Tipp
            if (isElolap)
              Text(
                'Koppints a megfordításhoz →',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
