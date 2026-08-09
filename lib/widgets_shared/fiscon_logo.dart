import 'package:flutter/material.dart';

class FiscOnLogo extends StatelessWidget {
  final double? fontSize;
  final double? imageHeight;
  final String? sottotitolo;

  const FiscOnLogo({
    super.key,
    this.fontSize,
    this.imageHeight,
    this.sottotitolo,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveFontSize = fontSize ?? (imageHeight != null ? imageHeight! * (52 / 170) : 22.0);
    final double effectiveHeight = imageHeight ?? (effectiveFontSize * (170 / 52));

    // Dimensioni proporzionali per lo slot visivo
    final double symbolSlotWidth = effectiveHeight * (48 / 170);
    final double imageLeftOffset = -effectiveHeight * (60 / 170);
    final double imageTopOffset = -effectiveHeight * (60 / 170); // 👈 Bilanciato al centro del font

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Testo "Fisc"
        Text(
          'Fisc',
          style: TextStyle(
            color: Colors.white,
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),

        // 2. Simbolo "O" (Ingombro verticale ridotto per pareggiare il font)
        SizedBox(
          width: symbolSlotWidth,
          height: effectiveFontSize, // 👈 Bloccato a 22px invece di 72px
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: imageLeftOffset,
                top: imageTopOffset,
                width: effectiveHeight,
                height: effectiveHeight,
                child: Image.asset(
                  'assets/fiscon_symbol.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),

        // 3. Testo "N"
        Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),

        // 4. Sottotitolo ("Gestione P.IVA", "Portafoglio Personale")
        if (sottotitolo != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              sottotitolo!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: effectiveFontSize * 0.45,
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