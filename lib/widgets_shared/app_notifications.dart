import 'package:flutter/material.dart';

/// 🎨 Tipi di notifica disponibili nell'app
enum NotificationType { success, error, warning }

class AppNotifications {
  /// 🔔 Banner sempre in primo piano (Overlay) con durata personalizzabile
  static void mostraInAlto(
    BuildContext context, 
    String messaggio, {
    NotificationType type = NotificationType.success,
    int secondiDurata = 3, // ⏱️ Default: 3 secondi
  }) {
    try {
      final overlay = Navigator.of(context, rootNavigator: true).overlay;
      if (overlay == null) return;

      late OverlayEntry overlayEntry;

      // 🎨 Impostazione dinamica dei 3 colori e delle 3 icone
      late Color coloreBanner;
      late IconData icona;

      switch (type) {
        case NotificationType.success:
          coloreBanner = const Color(0xFF10B981); // 🟢 Verde Smeraldo
          icona = Icons.check_circle_rounded;
          break;
        case NotificationType.error:
          coloreBanner = const Color(0xFFEF4444); // 🔴 Rosso Errore
          icona = Icons.error_outline_rounded;
          break;
        case NotificationType.warning:
          coloreBanner = const Color(0xFFF59E0B); // 🟡 Giallo Ambra
          icona = Icons.warning_amber_rounded;
          break;
      }

      overlayEntry = OverlayEntry(
        builder: (ctx) => Positioned(
          top: MediaQuery.of(ctx).padding.top + 20,
          left: 16,
          right: 16,
          child: Material(
            elevation: 10,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: coloreBanner,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icona, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      messaggio,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // ⏱️ Rimuove la notifica dopo i secondi specificati
      Future.delayed(Duration(seconds: secondiDurata), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    } catch (e) {
      debugPrint('Errore notifica overlay: $e');
    }
  }
}