import 'dart:ui';
import 'package:flutter/material.dart';

class AppPopupWrapper extends StatelessWidget {
  final String title;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Widget child;
  final String? backgroundImageUrl;
  final VoidCallback? onClose;

  const AppPopupWrapper({
    super.key,
    required this.title,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.child,
    this.backgroundImageUrl,
    this.onClose,
  });

  /// 🛡️ METODO UNIVERSALE PER APRIRE QUALSIASI POP-UP
  /// Garantisce la STESSA animazione di apertura, lo STESSO sfondo oscurato e la STESSA simmetria in tutta l'app!
  static Future<T?> mostra<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chiudi',
      barrierColor: Colors.black.withOpacity(0.70), // Sfondo scuro elegante
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) => child,
      transitionBuilder: (context, anim1, anim2, childWidget) {
        final curve = Curves.easeOutCubic;
        final tweenScale = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: curve),
        );
        final tweenFade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: curve),
        );

        return FadeTransition(
          opacity: tweenFade,
          child: ScaleTransition(
            scale: tweenScale,
            child: childWidget,
          ),
        );
      },
    );
  }

  /// 💡 POP-UP INFORMATIVO UNIVERSALE (Spiegazioni Tap-to-Explore)
  static Future<void> mostraInfo({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String titolo,
    required String descrizione,
    String? formula,
  }) {
    return mostra(
      context: context,
      child: Dialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                titolo,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                descrizione,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              if (formula != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    formula,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ho Capito', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    final notchHeight = MediaQuery.of(context).viewPadding.top;
    final topMargin = (notchHeight > 0 ? notchHeight : 44.0) + 22.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: topMargin,
        bottom: isKeyboardOpen ? 10 : 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Container(
            color: const Color(0xFF18181B),
            child: Stack(
              children: [
                // 1. SFONDO FOTOGRAFICO STANDARD O CUSTOM
                Positioned.fill(
                  child: Image.network(
                    backgroundImageUrl ??
                        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                
                // 2. OVERLAY SCURO
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.75),
                  ),
                ),

                // 3. STRUTTURA CONTENUTO (HEADER + CORPO)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // HEADER STANDARD CON TASTO X, TITOLO E BADGE OPZIONALE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: onClose ?? () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border:
                                            Border.all(color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (badgeColor ?? const Color(0xFF2DD4BF))
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (badgeColor ?? const Color(0xFF2DD4BF))
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                badgeText!,
                                style: TextStyle(
                                  color: badgeTextColor ??
                                      badgeColor ??
                                      const Color(0xFF2DD4BF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // CORPO PRINCIPALE
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B).withOpacity(0.60),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}