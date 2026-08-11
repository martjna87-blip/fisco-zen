import 'package:flutter/material.dart';

enum AdvisorMood { tip, warning, danger, success }

class AdvisorTipCard extends StatelessWidget {
  final AdvisorMood mood;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final IconData? icon; // 👈 Supporto icona personalizzata

  const AdvisorTipCard({
    super.key,
    required this.mood,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.onDismiss,
    this.icon,
  });

  Color get _color {
    switch (mood) {
      case AdvisorMood.tip: return const Color(0xFF2DD4BF);
      case AdvisorMood.warning: return const Color(0xFFF59E0B);
      case AdvisorMood.danger: return const Color(0xFFEF4444);
      case AdvisorMood.success: return const Color(0xFF10B981);
    }
  }

  IconData get _effectiveIcon {
    if (icon != null) return icon!;
    switch (mood) {
      case AdvisorMood.tip: return Icons.lightbulb_rounded;
      case AdvisorMood.warning: return Icons.shield_outlined;
      case AdvisorMood.danger: return Icons.warning_rounded;
      case AdvisorMood.success: return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_effectiveIcon, color: _color, size: 20), // 🛡️ Scudo vuoto colorato
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                  ),
                ),
            ],
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionText!,
                    style: TextStyle(
                      color: _color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}