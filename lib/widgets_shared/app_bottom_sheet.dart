import 'dart:ui';
import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Widget child;

  const AppBottomSheet({
    super.key,
    required this.title,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.child,
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
    final bottomInset = mediaQuery.viewInsets.bottom;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    // 🛡️ ALTEZZA MASSIMA
    final maxAvailableHeight = mediaQuery.size.height - topPadding - 12;

    return Material(
      color: const Color(0xFF18181B),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxAvailableHeight),
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
            // 🛡️ SPAZIO DI SICUREZZA PER NOTCH / BATTERIA
            SizedBox(height: topPadding > 0 ? topPadding + 16 : 24), // 👈 Aggiunge +16px extra sotto il Notch

            // 1. DRAG HANDLE
            Center(
              child: Container(
                width: 36,
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

            // 3. CONTENUTO
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 12,
                  bottom: bottomInset > 0 ? bottomInset + 16 : bottomPadding + 16,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}