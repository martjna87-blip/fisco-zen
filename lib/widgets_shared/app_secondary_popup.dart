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
  final double maxWidth; // 🎯 Modifica: aggiunta proprietà maxWidth

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
    this.maxWidth = double.infinity, // 🎯 Modifica: default a larghezza massima
  });

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
    double maxWidth = double.infinity, // 🎯 Modifica: parametro facoltativo
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
        maxWidth: maxWidth, // 🎯 Modifica: passaggio parametro
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompatto = maxWidth < 400;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompatto ? 32.0 : 16.0,
      ),
      backgroundColor: backgroundColor,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: maxWidth, // 🎯 Modifica: vincolo applicato qui
          maxHeight: 560,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 200.0),
                  child: child,
                ),
              ),
            ),
            const SizedBox(height: 12),
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

// ===========================================================================
// 🎨 DROPDOWN CARD UNICA IN OVERLAY CON AUTO-SCROLL GARANTITO
// ===========================================================================
class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppSecondaryDropdown<T> extends StatefulWidget {
  final String? label;
  final T selectedValue;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onSelect;
  final Color accentColor;

  const AppSecondaryDropdown({
    super.key,
    this.label,
    required this.selectedValue,
    required this.items,
    required this.onSelect,
    this.accentColor = const Color(0xFF38BDF8),
  });

  @override
  State<AppSecondaryDropdown<T>> createState() => _AppSecondaryDropdownState<T>();
}

class _AppSecondaryDropdownState<T> extends State<AppSecondaryDropdown<T>> {
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _toggleDropdown() {
    if (_isExpanded) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );

    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.selectedValue,
      orElse: () => widget.items.first,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final size = renderBox.size;

      _overlayEntry = OverlayEntry(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDropdown,
          child: Stack(
            children: [
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0.0, 0.0),
                  child: Material(
                    elevation: 16,
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.accentColor.withOpacity(0.8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _closeDropdown,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  if (selectedItem.icon != null) ...[
                                    Icon(selectedItem.icon, color: widget.accentColor, size: 16),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      selectedItem.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: widget.accentColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            color: Colors.white.withOpacity(0.12),
                            height: 1,
                            thickness: 1,
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 148.0),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: widget.items.map((item) {
                                  final bool isSelected = item.value == widget.selectedValue;
                                  return InkWell(
                                    onTap: () {
                                      widget.onSelect(item.value);
                                      _closeDropdown();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      color: isSelected
                                          ? widget.accentColor.withOpacity(0.15)
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons.circle_outlined,
                                            color: isSelected
                                                ? widget.accentColor
                                                : Colors.white24,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 8),
                                          if (item.icon != null) ...[
                                            Icon(item.icon, color: Colors.white70, size: 14),
                                            const SizedBox(width: 6),
                                          ],
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.white70,
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        _isExpanded = true;
      });
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.selectedValue,
      orElse: () => widget.items.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isExpanded ? widget.accentColor.withOpacity(0.8) : Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: _toggleDropdown,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (selectedItem.icon != null) ...[
                      Icon(selectedItem.icon, color: widget.accentColor, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        selectedItem.label,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: _isExpanded ? widget.accentColor : Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}