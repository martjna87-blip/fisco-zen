import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '1_onboarding_wizard.dart';
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MainDashboardWrapper(
        hasPartitaIva: widget.hasPartitaIva,
        codiceAtecoIniziale: widget.codiceAtecoIniziale,
        coefficienteIniziale: widget.coefficienteIniziale,
        aliquotaImpostaIniziale: widget.aliquotaImpostaIniziale,
      ),
      const SizedBox.shrink(),
      const Center(
        child: Text(
          'Notifiche / Scadenze (In arrivo)',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      const ProfiloSandboxScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (index == 0 || index == 1) {
            _currentIndex = 0;
          } else {
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
        AppPopupWrapper.mostra(
          context: context,
          child: const AddMovementSheet(initialTab: 'uscita'),
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

// 🎯 SCHERMATA SEPARATA PER PROFILO & TEST SANDBOX
class ProfiloSandboxScreen extends StatelessWidget {
  const ProfiloSandboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profilo & Test Sandbox',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Strumenti di controllo per simulare il comportamento dell\'app.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // 🔴 TASTO 1: RESET CONTI & FATTURE
              InkWell(
                onTap: () async {
                  final walletProvider = context.read<WalletProvider>();
                  await walletProvider.resetSoloMovimentieFatture();
                  if (!context.mounted) return;
                  AppNotifications.mostraInAlto(
                    context, 
                    'Fatture e conti azzerati! Profilo ATECO conservato', 
                    type: NotificationType.warning,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded, color: Color(0xFFEF4444), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Azzera Conti e Fatture', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Mantiene intatto il tuo profilo ATECO', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🟡 TASTO 2: RESET TOTALE & PRIMO AVVIO
              InkWell(
                onTap: () async {
                  final walletProvider = context.read<WalletProvider>();
                  await walletProvider.resetTuttiIDati();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingWizard(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.restart_alt_rounded, color: Color(0xFFF59E0B), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reset Totale (Primo Avvio)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Riavvia il questionario iniziale da zero', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🟣 TASTO 3: TOGGLE PRO / FREE
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return InkWell(
                    onTap: () {
                      walletProvider.toggleProUser();
                      AppNotifications.mostraInAlto(
                        context, 
                        walletProvider.isProUser
                            ? '✨ Modalità PRO Attivata (Test)' 
                            : '🔒 Modalità FREE Attivata (Test)',
                        type: NotificationType.warning,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: walletProvider.isProUser 
                            ? const Color(0xFFA855F7).withOpacity(0.15) 
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: walletProvider.isProUser 
                              ? const Color(0xFFA855F7).withOpacity(0.4) 
                              : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded, 
                            color: walletProvider.isProUser ? const Color(0xFFA855F7) : Colors.white54, 
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  walletProvider.isProUser ? 'Piano Attivo: Fisco Zen PRO ✨' : 'Piano Attivo: Fisco Zen FREE 🔒', 
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const Text('Tocca per passare da Free a Pro per i tuoi test', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // 🏷️ BADGE VERSIONE
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined, color: Color(0xFF2DD4BF), size: 14),
                      SizedBox(width: 6),
                      Text('Versione V2.0 Stabile', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}