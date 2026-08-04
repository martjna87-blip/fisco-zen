import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '2_1_wallet_add_movement.dart';
import '2_2_wallet_manage_accounts.dart';
import '2_4_wallet_budget_pilot.dart';
import '2_5_wallet_annual_summary.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/serbatoio_tasse_widget.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '2_4_wallet_budget_pilot_v2.dart';

class WalletScreen extends StatefulWidget {
  final bool isPiva;

  const WalletScreen({super.key, this.isPiva = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  // 🎨 =======================================================================
  // 🎛️ REGOLATORE COMANDO COLORI (MODIFICA SOLO QUESTI DUE PER CAMBIARE TUTTO!)
  // ==========================================================================
  //
  // 🟢 OPZIONE 1 (SMERALDO):  Sfondo: Color(0xFF062C22) | Card: Color(0xFF0F3C2E)
  // 🟣 OPZIONE 2 (AMETISTA):  Sfondo: Color(0xFF1E1B2E) | Card: Color(0xFF2A2438)
  // 🟤 OPZIONE 3 (MOKA):      Sfondo: Color(0xFF1C1917) | Card: Color(0xFF292524)
  //
  final Color coloreSfondo = const Color(0xFF1C1917); // 👈 CAMBIA QUI LO SFONDO
  final Color coloreCard   = const Color(0xFF292524); // 👈 CAMBIA QUI LE CARD / BOTTONI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top; // 👈 Spazio hardware di orologio/notch
    final double headerHeight = 220 + topPadding; // 👈 Altezza fluida che riempie il vetro in cima

    final walletProvider = context.watch<WalletProvider>();
    final patrimonioNetto = walletProvider.patrimonioNetto;
    final spesoBisogni = walletProvider.spesoBisogni;
    final spesoSvago = walletProvider.spesoSvago;
    final spesoRisparmi = walletProvider.spesoRisparmi;
    final movimenti = walletProvider.transactions;
    
    // 🎯 Attiva la vista P.IVA se richiesta dal widget o impostata nel provider
    final bool mostraPiva = widget.isPiva || walletProvider.isPartitaIVA;

    // 🎯 1. Tasse reali dovute dalle fatture incassate (Dovuto Ateco)
    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    // 🎯 2. Soldi al sicuro nel Salvadanaio
    final double riservaGiaAccantonata = walletProvider.accounts
        .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, acc) => sum + acc.amount);

    // 🎯 3. Tasse in sospeso rimaste sul Conto Principale da coprire
    final double tasseDaAccantonare = walletProvider.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double residuoTasseDaCoprire = tasseDaAccantonare;

    // 🎯 4. NETTO DISPONIBILE: Liquidità dei conti (escluso Salvadanaio) meno tasse in sospeso
    final double sommaContiLiquidi = walletProvider.accounts
        .where((a) => !a.title.toLowerCase().contains('salvadanaio tasse') && !a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);
    final double nettoReale = (sommaContiLiquidi - tasseDaAccantonare).clamp(0.0, double.infinity);
    
    final bool isTasseCoperte = residuoTasseDaCoprire <= 0.01;

    return Scaffold(
      backgroundColor: coloreSfondo,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 🎯 HEADER WALLET IMMERSIVO & NATIVO (Stile iOS/Android)
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. Immagine di sfondo Edge-to-Edge
                Container(
                  height: headerHeight,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?q=80&w=1000&auto=format&fit=crop',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.45,
                    ),
                  ),
                ),
                // 2. Sfocatura/Sfumatura
                Container(
                  height: headerHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        coloreSfondo.withOpacity(0.5),
                        coloreSfondo,
                      ],
                    ),
                  ),
                ),

                // 3. 🎯 TITOLO DI PAGINA IN ALTO A SINISTRA (Stile H1 Nativo)
                Positioned(
                  top: topPadding + 12,
                  left: 20,
                  child: const Text(
                    'Portafoglio Personale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // 4. Pulsante Riepilogo in alto a destra
                Positioned(
                  top: topPadding + 10,
                  right: 16,
                  child: FilledButton.icon(
                    onPressed: () {
                      AppPopupWrapper.mostra(
                        context: context,
                        child: const AnnualSummarySheet(),
                      );
                    },
                    icon: const Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFF2DD4BF)),
                    label: const Text(
                      'Riepilogo',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

                // 5. CONTENUTO CENTRATO: PATRIMONIO NETTO (44pt) + SUB-ROW SPECCHIATA ALLA HOME
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 📊 1. PATRIMONIO NETTO (Stesso stile 44pt di Fatturato Lordo in Home)
                      InkWell(
                        onLongPress: () {
                          AppPopupWrapper.mostraInfo(
                            context: context,
                            icon: Icons.account_balance_rounded,
                            color: Colors.white,
                            titolo: 'Patrimonio Netto Complessivo',
                            descrizione: 'Somma totale dei saldi di tutti i tuoi conti correnti e del salvadanaio tasse.',
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'PATRIMONIO NETTO',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${patrimonioNetto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 💵 🐷 2. RIGA DETTAGLIO DISPONIBILE & SALVADANAIO (Centrata sotto, stile Tasse Dovute)
                      if (mostraPiva)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 💳 1. LIQUIDITÀ SPENDIBILE (Dollarino)
                              InkWell(
                                onTap: () {},
                                onLongPress: () {
                                  AppPopupWrapper.mostraInfo(
                                    context: context,
                                    icon: Icons.payments_rounded,
                                    color: const Color(0xFF10B981),
                                    titolo: 'Liquidità Reale Spendibile',
                                    descrizione: 'Sono i tuoi veri soldi personali spendibili. Calcolati prendendo i saldi dei tuoi conti e togliendo le tasse stimate in sospeso.',
                                    formula: 'Conti Liquidi − Tasse da Accantonare',
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${nettoReale.toStringAsFixed(0)} €',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // 🐷 2. TASSE & BADGE ACCANTONA/PROTETTE (Maialino)
                              InkWell(
                                onTap: () {},
                                onLongPress: () {
                                  AppPopupWrapper.mostraInfo(
                                    context: context,
                                    icon: Icons.savings_rounded,
                                    color: const Color(0xFF3B82F6),
                                    titolo: 'Riserva Tasse Calcolata',
                                    descrizione: 'È la stima totale delle tasse dovute sulle fatture incassate (Imposta Sostitutiva + INPS).',
                                    formula: 'Stima Fiscale ATECO + Contributi',
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${tasseTotaliCalcolate.toStringAsFixed(0)} €',
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // 🛡️ BADGE (Tap: Dialog Accantonamento | LongPress: Info Pop-up)
                                      InkWell(
                                        onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: coloreCard),
                                        onLongPress: () {
                                          AppPopupWrapper.mostraInfo(
                                            context: context,
                                            icon: isTasseCoperte ? Icons.shield_rounded : Icons.warning_amber_rounded,
                                            color: isTasseCoperte ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                            titolo: isTasseCoperte ? 'Tasse 100% Protette! 🛡️' : 'Accantonamento Tasse',
                                            descrizione: isTasseCoperte
                                                ? 'Hai già trasferito la totalità delle tasse dovute nel Salvadanaio. La tua liquidità sul conto principale è al sicuro!'
                                                : 'Ci sono tasse stimate che risiedono ancora sul tuo conto principale. Fai un tap per spostarle nel Salvadanaio.',
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isTasseCoperte
                                                ? const Color(0xFF10B981).withOpacity(0.2)
                                                : const Color(0xFF3B82F6),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isTasseCoperte
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF3B82F6),
                                            ),
                                          ),
                                          child: isTasseCoperte
                                              ? const Row(
                                                  children: [
                                                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Protette',
                                                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                )
                                              : const Text(
                                                  'Accantona',
                                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // CONTENUTO SCROLLABILE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 🛡️ 1. SERBATOIO RISERVA TASSE (Allineato a 12px esatti come in Home P.IVA)
                  if (mostraPiva) ...[
                    GestureDetector(
                      onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: coloreCard),
                      onLongPress: () {
                        AppPopupWrapper.mostraInfo(
                          context: context,
                          icon: Icons.shield_rounded,
                          color: const Color(0xFF3B82F6),
                          titolo: 'Serbatoio Riserva Tasse',
                          descrizione: 'Mostra lo stato di copertura delle tue tasse stimate. Fai un tap per accantonare subito le tasse scoperte nel Salvadanaio.',
                          formula: 'In Salvadanaio ÷ Dovuto ATECO',
                        );
                      },
                      child: SerbatoioTasseWidget(
                        cardColor: coloreCard,
                      ),
                    ),
                  ],

                  // 2. 3 QUADRANTI AZIONE (Allineati a 86px esattamente come Home P.IVA)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildMiniCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Movimenti',
                          value: 'Entrata / Uscita',
                          onTap: () {
                            AppPopupWrapper.mostra(
                              context: context,
                              child: const AddMovementSheet(initialTab: 'riepilogo'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMiniCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Gestione\nConti',
                          value: '3 Attivi',
                          onTap: () {
                            AppPopupWrapper.mostra(
                              context: context,
                              child: ManageAccountsSheet(isPiva: widget.isPiva),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMiniCard(
                          icon: Icons.pie_chart_outline_rounded,
                          title: 'Pilotaggio\nBudget',
                          value: 'Pianificazione',
                          onTap: () {
                            AppPopupWrapper.mostra(
                              context: context,
                              child: const PianoSpesaSheet(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. BARRA EQUILIBRIO
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: coloreCard.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Equilibrio Portafoglio',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '880,00 € / 5.120 €',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 880 / 5120,
                            minHeight: 6,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. GRAFICO A TORTA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: coloreCard.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RIPARTIZIONE BUDGET (50 / 30 / 20)',
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CustomPaint(
                                painter: DonutChartPainter(
                                  values: [spesoBisogni, spesoSvago, spesoRisparmi],
                                  colors: const [Color(0xFF2DD4BF), Color(0xFFF59E0B), Color(0xFF3B82F6)],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLegendItem('50% Bisogni', '${spesoBisogni.toInt()} €', const Color(0xFF2DD4BF)),
                                  const SizedBox(height: 10),
                                  _buildLegendItem('30% Svago', '${spesoSvago.toInt()} €', const Color(0xFFF59E0B)),
                                  const SizedBox(height: 10),
                                  _buildLegendItem('20% Risparmi', '${spesoRisparmi.toInt()} €', const Color(0xFF3B82F6)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'CONTI & CARTE',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  ...walletProvider.accounts.map((acc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildAccountCard(
                          icon: acc.id == '1'
                              ? Icons.account_balance_rounded
                              : (acc.id == '2' ? Icons.credit_card_rounded : Icons.savings_rounded),
                          title: acc.title,
                          subtitle: acc.subtitle,
                          amount: '${acc.amount.toStringAsFixed(2)} €',
                          color: acc.color,
                        ),
                      )),

                  const Text(
                    'ULTIMI MOVIMENTI',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  if (movimenti.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Nessun movimento presente', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    )
                  else
                    ...movimenti.map((tx) => _buildTransactionTile(
                          icon: tx.isIncome ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined,
                          title: tx.title,
                          subtitle: tx.subtitle,
                          amount: '${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} €',
                          isIncome: tx.isIncome,
                        )),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? iconColor,
    Color? valueColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 86, // 👈 ALTEZZA FISSA 86px IDENTICA A HOME P.IVA
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: coloreCard.withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: iconColor != null 
                ? iconColor.withOpacity(0.3) 
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 10, 
                height: 10, 
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildAccountCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFF10B981).withOpacity(0.12) : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isIncome ? const Color(0xFF10B981) : Colors.white70, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isIncome ? const Color(0xFF10B981) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.reduce((a, b) => a + b);
   
    if (total == 0) return;

    double startAngle = -pi / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(7, 7, size.width - 14, size.height - 14);

    for (int i = 0; i < values.length; i++) {
      final double sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}