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
    // Calcolo della dimensione del testo (es. 22 in Home, 52 in Login)
    final double effectiveFontSize = fontSize ?? (imageHeight != null ? imageHeight! * (52 / 170) : 22.0);

    // L'altezza del simbolo è bloccata al 115% del testo per non ingrandirsi mai più delle lettere
    final double symbolHeight = effectiveFontSize * 1.15;

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
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),

        // 2. Simbolo "O" proporzionato
        Padding(
          padding: EdgeInsets.symmetric(horizontal: effectiveFontSize * 0.02),
          child: Image.asset(
            'assets/fiscon_symbol.png',
            height: symbolHeight,
            fit: BoxFit.contain,
          ),
        ),

        // 3. Testo "N"
        Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),

        // 4. Sottotitolo opzionale
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