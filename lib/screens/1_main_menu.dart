import 'dart:ui';
import 'package:flutter/material.dart';

// Importiamo le TUE VERE schermate
import 'main_dashboard_wrapper.dart';
import '2_wallet_screen.dart'; 
import '2_1_wallet_add_movement.dart'; 

class MainMenu extends StatefulWidget {
  // Riceviamo i dati dal SetupScreen
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
    // 🗂️ QUI CARICHIAMO LE TUE VERE SCHERMATE
    _screens = [
      // Indice 0: La tua VERA Dashboard
      MainDashboardWrapper(
        hasPartitaIva: widget.hasPartitaIva,
        codiceAtecoIniziale: widget.codiceAtecoIniziale,
        coefficienteIniziale: widget.coefficienteIniziale,
        aliquotaImpostaIniziale: widget.aliquotaImpostaIniziale,
      ),
      // Indice 1: Il tuo VERO Wallet
      const WalletScreen(), 
      // Indice 2 e 3: Pagine provvisorie in attesa di essere create
      const Center(child: Text('Notifiche / Scadenze (In arrivo)', style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text('Profilo & Impostazioni (In arrivo)', style: TextStyle(color: Colors.white, fontSize: 18))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      // 👇 ABBIAMO AVVOLTO L'INDEXEDSTACK IN UNA SAFEAREA
      body: SafeArea(
        bottom: false, // 🟢 Lasciamo a false sotto per non rovinare l'effetto vetro della barra
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      extendBody: true, 
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  // ✨ BARRA DI NAVIGAZIONE EFFETTO VETRO
  Widget _buildGlassBottomNav() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B).withOpacity(0.75),
              borderRadius: BorderRadius.circular(30),
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
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF2DD4BF) : Colors.white54,
          size: 26,
        ),
      ),
    );
  }

  // 🟢 PULSANTE CENTRALE RIALZATO CHE APRE DIRETTAMENTE USCITA!
  Widget _buildCenterAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddMovementSheet(initialTab: 'uscita'), // 👈 Passiamo 'uscita'!
        );
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2DD4BF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2DD4BF).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
      ),
    );
  }
}