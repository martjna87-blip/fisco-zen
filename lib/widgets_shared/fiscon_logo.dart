// FILE: lib/widgets_shared/fiscon_logo.dart

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🛡️ ICONA ACCENSIONE "ON" CON BORDO NEON
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
          ),
          child: const Icon(
            Icons.power_settings_new_rounded,
            color: Color(0xFF2DD4BF),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),

        // 🔤 TESTO BRANDIZZATO "FiscON"
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              fontFamily: 'Roboto',
            ),
            children: const [
              TextSpan(
                text: 'Fisc',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'ON',
                style: TextStyle(
                  color: Color(0xFF2DD4BF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        // 🏷️ SOTTOTITOLO OPZIONALE (es. "Wallet" o "P.IVA")
        if (sottotitolo != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sottotitolo!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}