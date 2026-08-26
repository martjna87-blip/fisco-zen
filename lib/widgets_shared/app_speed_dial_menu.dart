import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class AppSpeedDialMenu extends StatefulWidget {
  final VoidCallback onNuovaFattura;
  final VoidCallback onNuovaEntrata;
  final VoidCallback onNuovaUscita;

  const AppSpeedDialMenu({
    super.key,
    required this.onNuovaFattura,
    required this.onNuovaEntrata,
    required this.onNuovaUscita,
  });

  /// 🚀 METODO STATICO PER MOSTRARE IL MENU VELOCE
  static Future<void> mostra({
    required BuildContext context,
    required VoidCallback onNuovaFattura,
    required VoidCallback onNuovaEntrata,
    required VoidCallback onNuovaUscita,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SpeedDial',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => AppSpeedDialMenu(
        onNuovaFattura: onNuovaFattura,
        onNuovaEntrata: onNuovaEntrata,
        onNuovaUscita: onNuovaUscita,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            alignment: const Alignment(0, 0.88), // Parte esattamente dal tasto +
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AppSpeedDialMenu> createState() => _AppSpeedDialMenuState();
}

class _AppSpeedDialMenuState extends State<AppSpeedDialMenu> {
  @override
  Widget build(BuildContext context) {
    // 🎯 Configurazione Voci del Ventaglio (Angoli in gradi, colori ed icone)
    final List<Map<String, dynamic>> items = [
      {
        'label': 'Uscita',
        'icon': Icons.arrow_upward_rounded,
        'color': const Color(0xFFEF4444), // Rosso
        'angle': -145.0, // Top-Left
        'action': widget.onNuovaUscita,
      },
      {
        'label': 'Fattura P.IVA',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF3B82F6), // 🎯 Blu Zaffiro P.IVA
        'angle': -90.0, // Top-Center
        'action': widget.onNuovaFattura,
      },
      {
        'label': 'Entrata',
        'icon': Icons.arrow_downward_rounded,
        'color': const Color(0xFF10B981), // Verde
        'angle': -35.0, // Top-Right
        'action': widget.onNuovaEntrata,
      },
    ];

    const double radius = 115.0; // Distanza dal centro del tasto +

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. SFONDO SFOCATO CON TAP PER CHIUDERE
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),

          // 2. DISPOSIZIONE AD ARCO (VENTAGLIO)
          Positioned(
            bottom: 38,
            child: SizedBox(
              width: 320,
              height: 220,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // 🎯 Generazione dinamica dei pulsanti ad arco
                  ...items.map((item) {
                    final double angleRad = (item['angle'] as double) * (math.pi / 180.0);
                    final double dx = math.cos(angleRad) * radius;
                    final double dy = math.sin(angleRad) * radius;

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: _buildFanButton(
                        context: context,
                        icon: item['icon'] as IconData,
                        color: item['color'] as Color,
                        label: item['label'] as String,
                        onTap: item['action'] as VoidCallback,
                      ),
                    );
                  }),

                  // ❌ TASTO CENTRALE DI CHIUSURA (Ruotato a 45°)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              onTap();
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C21).withOpacity(0.90),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}