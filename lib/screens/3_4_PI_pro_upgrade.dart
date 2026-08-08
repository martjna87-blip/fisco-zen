import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class ProUpgradeSheet extends StatefulWidget {
  final String funzionalita;

  const ProUpgradeSheet({super.key, required this.funzionalita});

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  // 0 = Mensile, 1 = Annuale
  int _pianoSelezionato = 1;

  void _simulaInserimentoCarta(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form inserimento Carta / Apple Pay pronto per l\'integrazione Stripe!'),
      ),
    );
  }

  void _confermaAnnullamentoPro(BuildContext context, WalletProvider walletProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Disattivare FiscON PRO?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Tornando all\'Account Base disabiliterai la Riserva Tasse automatica e le stime ATECO avanzate.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mantieni PRO', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              elevation: 0,
              side: const BorderSide(color: Colors.redAccent, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              walletProvider.impostaStatoPro(false);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sei tornato all\'Account Base.')),
              );
            },
            child: const Text('Disdici PRO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final bool giaPro = walletProvider.isProUser;

    // 🎨 PALETTE TITANIO & OTTANIO BRAND
    const Color coloreSfondo = Color(0xFF12181B);
    const Color coloreCard   = Color(0xFF1F2428);
    const Color coloreOttanio = Color(0xFF2DD4BF);
    const Color coloreOro    = Color(0xFFF59E0B);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: coloreSfondo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ➖ BARRA SUPERIORE
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 🏷️ BADGE OFFERTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (giaPro ? coloreOttanio : coloreOro).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: giaPro ? coloreOttanio : coloreOro, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    giaPro ? Icons.verified_user_rounded : Icons.local_offer_rounded,
                    color: giaPro ? coloreOttanio : coloreOro,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    giaPro ? 'PIANO PRO ATTIVO' : 'OFFERTA DI LANCIAR • 1 MESE GRATIS',
                    style: TextStyle(
                      color: giaPro ? coloreOttanio : coloreOro,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              giaPro ? 'Gestione Abbonamento' : 'Sblocca FiscON PRO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              giaPro
                  ? 'Gestisci il tuo piano, le carte di credito e la promozione amici.'
                  : 'Sblocca "${widget.funzionalita}" e prova gratis tutti i servizi senza vincoli.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 20),

            // 📦 SELETTORE PIANI (MENSILE VS ANNUALE)
            Row(
              children: [
                Expanded(
                  child: _buildPianoCard(
                    index: 0,
                    titolo: 'Mensile',
                    prezzoVecchio: '9,99€',
                    prezzoAttuale: '0€',
                    sottoTesto: '1° Mese Gratis',
                    isSelected: _pianoSelezionato == 0,
                    coloreAccento: coloreOttanio,
                    onTap: () => setState(() => _pianoSelezionato = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPianoCard(
                    index: 1,
                    titolo: 'Annuale',
                    prezzoVecchio: '99,00€',
                    prezzoAttuale: '0€',
                    sottoTesto: 'Risparmi il 20%',
                    isBestValue: true,
                    isSelected: _pianoSelezionato == 1,
                    coloreAccento: coloreOro,
                    onTap: () => setState(() => _pianoSelezionato = 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🎁 REFERRAL CARD: INVITA UN AMICO
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: coloreCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: coloreOro.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: coloreOro.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: coloreOro, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Guadagna 3 Mesi GRATIS!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Invita un amico: se attiva il piano Annuale, ricevi 3 mesi aggiuntivi in omaggio.',
                          style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 💳 CARTA DI CREDITO / METODO DI PAGAMENTO
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: coloreCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'METODO DI PAGAMENTO (RINNOVI FUTURI)',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              giaPro ? 'Visa termina in •••• 4242' : 'Nessuna carta collegata',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              giaPro ? 'Scadenza 12/28 • Predefinita' : 'Collegamento sicuro per acquisti futuri',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _simulaInserimentoCarta(context),
                        child: Text(
                          giaPro ? 'Modifica' : 'Aggiungi',
                          style: const TextStyle(
                            color: coloreOttanio,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔘 BOTTONE ATTIVAZIONE / CHIUSURA
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: giaPro ? Colors.white12 : coloreOttanio,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (!giaPro) {
                    walletProvider.impostaStatoPro(true);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Prova gratuita attivata! Benvenuto in FiscON PRO.'),
                        backgroundColor: coloreOttanio,
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  giaPro ? 'Chiudi' : 'Attiva 1 Mese Gratis (0€)',
                  style: TextStyle(
                    color: giaPro ? Colors.white : const Color(0xFF12181B),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            // 🔴 DISDETTA ABBONAMENTO (SE PRO)
            if (giaPro) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                label: const Text(
                  'Annulla abbonamento e torna a Account Base',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _confermaAnnullamentoPro(context, walletProvider),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🛠️ WIDGET CARD PIANO
  Widget _buildPianoCard({
    required int index,
    required String titolo,
    required String prezzoVecchio,
    required String prezzoAttuale,
    required String sottoTesto,
    required bool isSelected,
    required Color coloreAccento,
    required VoidCallback onTap,
    bool isBestValue = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2428),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? coloreAccento : Colors.white.withOpacity(0.08),
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
                  titolo,
                  style: TextStyle(
                    color: isSelected ? coloreAccento : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: coloreAccento.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PROMO',
                      style: TextStyle(color: coloreAccento, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$prezzoVecchio ',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  prezzoAttuale,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sottoTesto,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}