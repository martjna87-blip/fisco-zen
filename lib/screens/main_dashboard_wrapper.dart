import 'package:flutter/material.dart';
import '3_home_PI_screen.dart'; 
import '2_wallet_screen.dart';

class MainDashboardWrapper extends StatefulWidget {
  final bool hasPartitaIva; 
  final String? codiceAtecoIniziale;
  final double? coefficienteIniziale;
  final double? aliquotaImpostaIniziale;

  const MainDashboardWrapper({
    super.key,
    required this.hasPartitaIva,
    this.codiceAtecoIniziale,
    this.coefficienteIniziale,
    this.aliquotaImpostaIniziale,
  });

  @override
  State<MainDashboardWrapper> createState() => _MainDashboardWrapperState();
}

class _MainDashboardWrapperState extends State<MainDashboardWrapper> {
  // Gestisce lo scorrimento
  final PageController _pageController = PageController(initialPage: 0);
  
  // 📍 Variabile per tenere traccia della pagina attuale
  int _currentPage = 0; 

  // Animazione per far scivolare il Wallet se premi il bottone
  void _scorriVersoWallet() {
    _pageController.animateToPage(
      1, 
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se l'utente non ha la P.IVA, vede solo il Wallet normale (nessun carosello)
    if (!widget.hasPartitaIva) {
      return const WalletScreen(isPiva: false);
    }

    // Se l'utente HA la P.IVA, vede il carosello
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      // 📍 Usiamo uno Stack per sovrapporre i pallini sopra le pagine
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            // 📍 Quando scorri, aggiorna la pagina attiva
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              // Pagina Sinistra: P.IVA
              HomeScreen(
                codiceAtecoIniziale: widget.codiceAtecoIniziale,
                coefficienteIniziale: widget.coefficienteIniziale,
                aliquotaImpostaIniziale: widget.aliquotaImpostaIniziale,
                onSwipeToWallet: _scorriVersoWallet, 
              ),
              
              // Pagina Destra: Wallet
              const WalletScreen(isPiva: true),
            ],
          ),

          // 📍 INDICATORE DI PAGINA
          Positioned(
            bottom: 10, // Distanza dal fondo dello schermo
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final bool isSelected = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    // Il pallino attivo diventa una "pillola" allungata, quello inattivo resta tondo
                    width: isSelected ? 24 : 8, 
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}