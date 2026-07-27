import 'dart:ui';
import 'package:flutter/material.dart';
// Test sincronizzazione Mac ok
// Importiamo le TUE VERE schermate
import 'main_dashboard_wrapper.dart';
import '2_wallet_screen.dart'; 
import '2_1_wallet_add_movement.dart'; 

class MainMenu extends StatefulWidget {
  final bool hasPartitaIva;
  final String? codiceAtecoIniziale;
  final double? coefficienteIniziale;
  final double? aliquotaImpostaIniziale;

  const MainMenu({
    super.key,
    required this.hasPartitaIva,
    this.codiceAtecoIniziale,
    this.coefficienteIniziale,
    this.aliquotaImpostaIniziale,
  });

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // Indice 0: GESTISCE TUTTO (Swipe P.IVA oppure solo Wallet per Dipendente)
      MainDashboardWrapper(
        hasPartitaIva: widget.hasPartitaIva,
        codiceAtecoIniziale: widget.codiceAtecoIniziale,
        coefficienteIniziale: widget.coefficienteIniziale,
        aliquotaImpostaIniziale: widget.aliquotaImpostaIniziale,
      ),
      // Indice 1: Schermata "fantasma" (non verrà mai chiamata dal menù in basso)
      const SizedBox.shrink(), 
      // Indice 2: Avvisi
      const Center(child: Text('Notifiche / Scadenze (In arrivo)', style: TextStyle(color: Colors.white, fontSize: 18))),
      // Indice 3: Profilo
      const Center(child: Text('Profilo & Impostazioni (In arrivo)', style: TextStyle(color: Colors.white, fontSize: 18))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      extendBody: true, 
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  Widget _buildGlassBottomNav() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141417).withOpacity(0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.dashboard_outlined, index: 0, label: 'Home'),
                _buildNavItem(icon: Icons.account_balance_wallet_outlined, index: 1, label: 'Wallet'),
                _buildCenterAddButton(context),
                _buildNavItem(icon: Icons.notifications_none_rounded, index: 2, label: 'Avvisi'),
                _buildNavItem(icon: Icons.person_outline_rounded, index: 3, label: 'Profilo'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    // Il tasto si illumina se è selezionato
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (index == 0 || index == 1) {
            // 🎯 NEUTRALIZZAZIONE: Sia cliccando su Home che su Wallet, 
            // forziamo l'app a stare nell'indice 0 (MainDashboardWrapper).
            // Lo swipe gestirà la vista tra le due schede.
            _currentIndex = 0;
          } else {
            // Per Avvisi (2) e Profilo (3) navighiamo normalmente.
            _currentIndex = index;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF2DD4BF) : Colors.white54,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddMovementSheet(initialTab: 'uscita'),
        );
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2DD4BF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2DD4BF).withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
      ),
    );
  }
}