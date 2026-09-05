import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';

class ProUpgradeSheet extends StatefulWidget {
  final String funzionalita;

  const ProUpgradeSheet({
    super.key,
    required this.funzionalita,
  });

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  late UserTier _selectedTier;
  bool _isAnnualSelected = true; // Di default proponiamo l'annuale (più conveniente)

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.funzionalita.contains('SDI') ? UserTier.premium : UserTier.pro;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPremium = _selectedTier == UserTier.premium;
    final Color mainColor = isPremium ? const Color(0xFFD946EF) : const Color(0xFFF59E0B);
    final String tierName = isPremium ? "PREMIUM" : "PRO";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // ✨ EFFETTO GLOW (LUCE SOFFUSA SULLO SFONDO)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              top: -100,
              right: isPremium ? -50 : null,
              left: !isPremium ? -50 : null,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mainColor.withOpacity(0.12),
                  boxShadow: [
                    BoxShadow(color: mainColor.withOpacity(0.12), blurRadius: 120, spreadRadius: 40)
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // 🔙 APP BAR CON MAGGIORE SPAZIATURA IN ALTO
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 💎 TITOLO CON GRADIENTE
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE0E0E0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Sblocca il tuo\npotenziale.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Scegli il piano giusto per te. Fase di lancio: accesso illimitato totalmente gratuito.',
                            style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4),
                          ),
                          const SizedBox(height: 32),

                          // 🟡 CARD 1: FISCON PRO
                          _buildExpandableCard(
                            tier: UserTier.pro,
                            title: 'FiscON PRO',
                            icon: Icons.workspace_premium_rounded,
                            monthlyPrice: '4,99€',
                            annualPrice: '49,00€',
                            color: const Color(0xFFF59E0B),
                            isSelected: _selectedTier == UserTier.pro,
                            badgeText: 'CONSIGLIATO',
                            features: [
                              'Lettura ricevute con Fotocamera (OCR)',
                              'Gestione Riserva Tasse F24 illimitata',
                              'Previsione e pianificazione mensile'
                            ],
                            onTap: () {
                              if (_selectedTier != UserTier.pro) {
                                setState(() {
                                  _selectedTier = UserTier.pro;
                                  _isAnnualSelected = true;
                                });
                              }
                            },
                          ),
                          
                          const SizedBox(height: 16),

                          // 🟣 CARD 2: FISCON PREMIUM
                          _buildExpandableCard(
                            tier: UserTier.premium,
                            title: 'FiscON PREMIUM',
                            icon: Icons.workspace_premium_rounded,
                            monthlyPrice: '9,99€',
                            annualPrice: '99,00€',
                            color: const Color(0xFFD946EF),
                            isSelected: _selectedTier == UserTier.premium,
                            badgeText: 'FATTURA ELETTRONICA',
                            features: [
                              'Tutte le funzioni del piano PRO',
                              'Emissione Fatture SDI Illimitate',
                              'Ricezione ciclo passivo e Conservazione'
                            ],
                            onTap: () {
                              if (_selectedTier != UserTier.premium) {
                                setState(() {
                                  _selectedTier = UserTier.premium;
                                  _isAnnualSelected = true;
                                });
                              }
                            },
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // 🔘 BOTTOM CALL TO ACTION (CTA) E GESTIONE ABBONAMENTO
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0F),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0A0A0F).withOpacity(0.9), blurRadius: 20, offset: const Offset(0, -10))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard_rounded, color: mainColor.withOpacity(0.8), size: 14),
                            const SizedBox(width: 6),
                            const Text('Promo Lancio: Nessun pagamento richiesto oggi.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: mainColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Provider.of<WalletProvider>(context, listen: false).setUserTier(_selectedTier);
                              Navigator.pop(context);
                              AppNotifications.mostraInAlto(
                                context,
                                'Piano $tierName attivato gratis! 🎉',
                                type: NotificationType.success,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Attiva $tierName Gratis',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        if (Provider.of<WalletProvider>(context).userTier != UserTier.free) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Provider.of<WalletProvider>(context, listen: false).setUserTier(UserTier.free);
                              Navigator.pop(context);
                              AppNotifications.mostraInAlto(
                                context,
                                'Abbonamento annullato. Sei tornato al piano Base.',
                                type: NotificationType.warning,
                              );
                            },
                            child: const Text(
                              'Annulla iscrizione (Torna al piano Base)',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💳 COSTRUTTORE DELLA CARD ESPANDIBILE (STILE APP STORE / BLINKIST)
  Widget _buildExpandableCard({
    required UserTier tier,
    required String title,
    required IconData icon,
    required String monthlyPrice,
    required String annualPrice,
    required Color color,
    required bool isSelected,
    String? badgeText,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.8) : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER DELLA CARD
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isSelected ? color : Colors.white54, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (badgeText != null && isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badgeText, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (!isSelected)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                  ),
              ],
            ),
            
            // SE LA CARD E' SELEZIONATA, ESPANDI I DETTAGLI E I PREZZI
            if (isSelected) ...[
              const SizedBox(height: 20),
              
              // SELETTORE INTERNO MENSILE / ANNUALE (Elegante)
              Row(
                children: [
                  // OPZIONE MENSILE
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAnnualSelected = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: !_isAnnualSelected ? color.withOpacity(0.1) : Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !_isAnnualSelected ? color.withOpacity(0.5) : Colors.transparent),
                        ),
                        child: Column(
                          children: [
                            Text('Mensile', style: TextStyle(color: !_isAnnualSelected ? Colors.white : Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(monthlyPrice, style: TextStyle(color: !_isAnnualSelected ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // OPZIONE ANNUALE (Evidenziata)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAnnualSelected = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _isAnnualSelected ? color.withOpacity(0.1) : Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isAnnualSelected ? color.withOpacity(0.5) : Colors.transparent),
                        ),
                        child: Column(
                          children: [
                            Text('Annuale', style: TextStyle(color: _isAnnualSelected ? Colors.white : Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(annualPrice, style: TextStyle(color: _isAnnualSelected ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.05), height: 1),
              const SizedBox(height: 20),
              
              // LISTA FUNZIONALITÀ
              ...features.map((feat) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.black, size: 12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feat,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            
            // SE LA CARD *NON* E' SELEZIONATA, MOSTRA SOLO UN PREZZO DI PARTENZA DISCRETO
            if (!isSelected) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 48), // Allineato col testo
                child: Text(
                  'A partire da $monthlyPrice / mese',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}