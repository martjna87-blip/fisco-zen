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
            alignment: const Alignment(0, 0.85), // Parte dal tasto + in basso
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. SFONDO SFOCATO AL TAP SULLO SCHERMO CHIUDE IL MENU
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // 2. CONTENITORE PULSANTI (Posizionato in basso sopra la barra)
          Positioned(
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📄 1. NUOVA FATTURA (P.IVA)
                _buildActionTile(
                  context: context,
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF2DD4BF),
                  label: 'Nuova Fattura',
                  subtitle: 'Emetti o registra compenso P.IVA',
                  onTap: widget.onNuovaFattura,
                ),

                const SizedBox(height: 12),

                // 💰 2. NUOVA ENTRATA
                _buildActionTile(
                  context: context,
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Nuova Entrata',
                  subtitle: 'Incasso o movimento in ingresso',
                  onTap: widget.onNuovaEntrata,
                ),

                const SizedBox(height: 12),

                // 💸 3. NUOVA USCITA
                _buildActionTile(
                  context: context,
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFEF4444),
                  label: 'Nuova Uscita',
                  subtitle: 'Spesa, acquisto o spesa ricorrente',
                  onTap: widget.onNuovaUscita,
                ),

                const SizedBox(height: 28),

                // ❌ TASTO CHIUDI (Ruotato a 45°)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2DD4BF).withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.black, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(); // Chiude lo speed dial
          onTap(); // Esegue l'azione desiderata
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C21).withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}