// FILE: lib/widgets_shared/fiscon_logo.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class FiscOnLogo extends StatelessWidget {
  final double fontSize;
  final String? sottotitolo;

  const FiscOnLogo({
    super.key,
    this.fontSize = 22,
    this.sottotitolo,
  });

  @override
  Widget build(BuildContext context) {
    // Calcolo proporzioni ottiche perfette per allinearsi alle lettere maiuscole
    final double oSize = fontSize * 0.82;
    final double strokeWidth = fontSize * 0.15; // Spessore grassetto identico al testo

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. "Fisc" IN BIANCO GRASSETTO
        Text(
          'Fisc',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.0,
          ),
        ),

        // 2. LA "O" DI ACCENSIONE VETTORIALE (Zero spazi vuoti ai lati)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: CustomPaint(
            size: Size(oSize, oSize),
            painter: _PowerOPainter(
              color: const Color(0xFF2DD4BF),
              strokeWidth: strokeWidth,
            ),
          ),
        ),

        // 3. LA "N" IN VERDE CIANO LUMINOSO
        Text(
          'N',
          style: TextStyle(
            color: const Color(0xFF2DD4BF),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.0,
            shadows: [
              Shadow(
                color: const Color(0xFF2DD4BF).withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),

        // 🏷️ SOTTOTITOLO OPZIONALE ("P.IVA" o "Wallet")
        if (sottotitolo != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              sottotitolo!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// 🎨 PITTORE VETTORIALE PER UNA "O" DI ACCENSIONE PERFETTA
class _PowerOPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PowerOPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // 1. Disegna l'arco del cerchio aperto in alto (da ore 1 a ore 11 in senso orario)
    const double startAngle = -math.pi / 2 + 0.48; // Ore ~1:00
    const double sweepAngle = 2 * math.pi - (0.48 * 2); // Fino a ore ~11:00

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // 2. Disegna il trattino verticale di accensione in alto al centro
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height * 0.46),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}