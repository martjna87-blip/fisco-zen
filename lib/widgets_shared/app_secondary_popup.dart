import 'package:flutter/material.dart';

class AppSecondaryPopup extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titolo;
  final Widget child;
  final String? testoConferma;
  final String testoAnnulla;
  final VoidCallback? onConferma;
  final VoidCallback? onAnnulla;
  final Color backgroundColor;

  const AppSecondaryPopup({
    super.key,
    required this.icon,
    this.iconColor = const Color(0xFF3B82F6),
    required this.titolo,
    required this.child,
    this.testoConferma,
    this.testoAnnulla = 'Annulla',
    this.onConferma,
    this.onAnnulla,
    this.backgroundColor = const Color(0xFF1C1C21),
  });

  /// 🚀 METODO STATICO PER APRIRE IL POP-UP CON UNICA CHIAMATA
  static Future<T?> mostra<T>({
    required BuildContext context,
    required IconData icon,
    Color iconColor = const Color(0xFF3B82F6),
    required String titolo,
    required Widget child,
    String? testoConferma,
    String testoAnnulla = 'Annulla',
    VoidCallback? onConferma,
    VoidCallback? onAnnulla,
    Color backgroundColor = const Color(0xFF1C1C21),
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        icon: icon,
        iconColor: iconColor,
        titolo: titolo,
        child: child,
        testoConferma: testoConferma,
        testoAnnulla: testoAnnulla,
        onConferma: onConferma,
        onAnnulla: onAnnulla,
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ HEADER STANDARDIZZATO (Icona + Titolo + Tasto X)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titolo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 🧩 CONTENUTO DINAMICO
            Flexible(child: child),

            const SizedBox(height: 20),

            // 🔘 BOTTONI D'AZIONE STANDARDIZZATI
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onAnnulla ?? () => Navigator.of(context).pop(),
                  child: Text(
                    testoAnnulla,
                    style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                if (testoConferma != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onConferma,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      testoConferma!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}