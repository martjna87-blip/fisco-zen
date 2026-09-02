import 'dart:ui';
import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Widget child;
  final double defaultHeightFactor; // Di base 0.55 (55%)
  final double expandedHeightFactor; // Con tastiera 0.70 (70%)

  const AppBottomSheet({
    super.key,
    required this.title,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.child,
    this.defaultHeightFactor = 0.70,
    this.expandedHeightFactor = 0.50,
  });

  /// 🚀 METODO UNIVERSALE PER APRIRE IL MODALE DAL BASSO
  static Future<T?> mostra<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.70),
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    final bool isKeyboardOpen = keyboardHeight > 0;

    // 🎯 55% SENZA TASTIERA | 70% CON TASTIERA
    final double activeFactor = isKeyboardOpen ? expandedHeightFactor : defaultHeightFactor;

    // 🛡️ LIMITATORE ANTI-NOTCH (Impedisce alla scheda di salire sopra l'orologio)
    final double maxSafeHeight = screenHeight - topPadding - 16.0;
    final double targetHeight = (screenHeight * activeFactor).clamp(200.0, maxSafeHeight);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Material(
        color: const Color(0xFF18181B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: targetHeight,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white10, width: 1),
              left: BorderSide(color: Colors.white10, width: 1),
              right: BorderSide(color: Colors.white10, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              // 1. DRAG HANDLE
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: badgeColor ?? const Color(0xFF2DD4BF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  badgeText!.toUpperCase(),
                                  style: TextStyle(
                                    color: (badgeColor ?? const Color(0xFF2DD4BF)).withOpacity(0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),

              // 3. CONTENUTO SCROLLABILE INTERNO
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 12,
                    bottom: isKeyboardOpen ? 12 : bottomPadding + 12,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}