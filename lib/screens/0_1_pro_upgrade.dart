// 📍 INIZIO CODICE: lib/screens/3_4_PI_pro_upgrade.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';

class ProUpgradeSheet extends StatefulWidget {
  final String funzionalita;

  const ProUpgradeSheet({super.key, required this.funzionalita});

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  bool _isAnnualSelected = true; // Di default spingiamo l'annuale
  bool _isLoading = false;

  // 🎨 Palette FiscON
  final Color coloreSfondo = const Color(0xFF12181B); // Titanio
  final Color coloreCard = const Color(0xFF1F2428); // Ardesia
  final Color coloreOro = const Color(0xFFF59E0B); // Amber PRO
  final Color coloreOttanio = const Color(0xFF2DD4BF); // Brand

  void _simulaAttivazionePro() async {
    setState(() => _isLoading = true);

    // Simuliamo l'elaborazione del sistema (es. collegamento con Apple/Google in futuro)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Sblocchiamo le funzioni PRO nel Provider
    final provider = context.read<WalletProvider>();
    provider.attivaPro();

    setState(() => _isLoading = false);

    Navigator.pop(context);
    
    // Mostriamo un feedback di grande impatto
    AppNotifications.mostraInAlto(
      context, 
      'Benvenuta in FiscON PRO! 🎉 Tutte le funzioni avanzate sono ora sbloccate.',
      type: NotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final bool giaPro = walletProvider.isProUser;

    // Se l'utente è già PRO, mostriamo una schermata di gestione
    if (giaPro) {
      return Scaffold(
        backgroundColor: coloreSfondo,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: coloreOro.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.workspace_premium_rounded, color: coloreOro, size: 64),
              ),
              const SizedBox(height: 24),
              const Text('Sei già un utente PRO', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Hai sbloccato tutte le potenzialità di FiscON.', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  context.read<WalletProvider>().disattivaPro();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simula Disdetta Abbonamento', style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: coloreSfondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: coloreOro.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: coloreOro.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, color: coloreOro, size: 14),
              const SizedBox(width: 6),
              Text('FiscON PRO', style: TextStyle(color: coloreOro, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🌟 HEADER PROMOZIONALE
                    const Text(
                      'Sblocca il tuo potenziale',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Attiva ora il piano PRO per accedere a "${widget.funzionalita}".\nApprofitta dell\'Offerta Lancio: provalo gratis e senza vincoli.',
                      style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 🏷️ SELETTORE PIANI (MENSILE / ANNUALE)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlanCard(
                            isAnnual: false,
                            title: 'Mensile',
                            price: '9,99€',
                            subtitle: 'Fatturato mensilmente',
                            isSelected: !_isAnnualSelected,
                            onTap: () => setState(() => _isAnnualSelected = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanCard(
                            isAnnual: true,
                            title: 'Annuale',
                            price: '99,00€',
                            subtitle: 'Risparmi il 17%',
                            isSelected: _isAnnualSelected,
                            isPromo: true,
                            onTap: () => setState(() => _isAnnualSelected = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 🎁 REFERRAL CARD (PORTA UN AMICO)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: coloreCard.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: coloreOttanio.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: coloreOttanio.withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(Icons.card_giftcard_rounded, color: coloreOttanio, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Guadagna 3 Mesi Gratis!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(height: 4),
                                Text(
                                  'Invita un amico: se attiva il piano Annuale, ricevi 3 mesi aggiuntivi in omaggio sul tuo account.',
                                  style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 💳 METODO DI PAGAMENTO (MOCKUP PER OFFERTA LANCIO)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('METODO DI PAGAMENTO (RINNOVI FUTURI)', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: coloreCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card_rounded, color: Colors.white54, size: 28),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nessuna carta richiesta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Fase di lancio: accesso gratuito', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.check_circle_rounded, color: coloreOttanio, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 🚀 BOTTOM BAR CON CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: coloreSfondo,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simulaAttivazionePro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coloreOttanio,
                        foregroundColor: coloreSfondo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Color(0xFF12181B), strokeWidth: 3),
                            )
                          : const Text(
                              'Attiva Mese di Prova (0€)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                  // 📍 INIZIO MODIFICA: Testo Rassicurazione Bottom (0_1_pro_upgrade.dart)
                  const SizedBox(height: 12),
                  Text(
                    'Accesso gratuito garantito per tutta la "Fase di Lancio".\nNessun rinnovo automatico a sorpresa: sarai tu a decidere se abbonarti in futuro o tornare al piano base.',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
// 📍 FINE MODIFICA: Testo Rassicurazione Bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🃏 WIDGET PER LE CARD DEI PIANI
  Widget _buildPlanCard({
    required bool isAnnual,
    required String title,
    required String price,
    required String subtitle,
    required bool isSelected,
    bool isPromo = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? coloreOro.withOpacity(0.08) : coloreCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? coloreOro : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? coloreOro : Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPromo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: coloreOro,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('PROMO', style: TextStyle(color: Color(0xFF12181B), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isPromo && isSelected ? coloreOro : Colors.white38,
                fontSize: 11,
                fontWeight: isPromo && isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// 📍 FINE CODICE: lib/screens/3_4_PI_pro_upgrade.dart