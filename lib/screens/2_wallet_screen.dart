import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '2_1_wallet_add_movement.dart';
import '2_2_wallet_manage_accounts.dart';
import '2_5_wallet_annual_summary.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/serbatoio_tasse_widget.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '2_4_wallet_budget_pilot_v2.dart';
import '../widgets_shared/fiscon_logo.dart';

class WalletScreen extends StatefulWidget {
  final bool isPiva;

  const WalletScreen({super.key, this.isPiva = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _filtroMeseMovimenti = 'ultimi_5';

  // 🎨 REGOLATORE COMANDO COLORI
  final Color coloreSfondo = const Color(0xFF1C1917);
  final Color coloreCard   = const Color(0xFF292524);

  // 📅 STATI PER IL SELETTORE TEMPORALE DELLA RIPARTIZIONE SPESE
  DateTime _dataFiltroRipartizione = DateTime(2026, 8);
  bool _isVistaAnnuale = false;

  final List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
  ];

  void _cambiaPeriodoRipartizione(int delta) {
    setState(() {
      if (_isVistaAnnuale) {
        _dataFiltroRipartizione = DateTime(_dataFiltroRipartizione.year + delta, _dataFiltroRipartizione.month);
      } else {
        _dataFiltroRipartizione = DateTime(_dataFiltroRipartizione.year, _dataFiltroRipartizione.month + delta);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = 220 + topPadding;

    final walletProvider = context.watch<WalletProvider>();
    final patrimonioNetto = walletProvider.patrimonioNetto;
    final movimenti = walletProvider.transactions;
    
    final bool mostraPiva = widget.isPiva || walletProvider.isPartitaIVA;

    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    final double tasseDaAccantonare = walletProvider.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double residuoTasseDaCoprire = tasseDaAccantonare;

    final double sommaContiLiquidi = walletProvider.accounts
        .where((a) => !a.title.toLowerCase().contains('salvadanaio tasse') && !a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);
    final double nettoReale = (sommaContiLiquidi - tasseDaAccantonare).clamp(0.0, double.infinity);
    
    final bool isTasseCoperte = residuoTasseDaCoprire <= 0.01;

    // 🤖 CALCOLO DINAMICO DELLE SPESE REALI PER IL PERIODO SELEZIONATO
    final txsFiltrate = movimenti.where((tx) {
      if (tx.isIncome) return false;
      if (_isVistaAnnuale) {
        return tx.date.year == _dataFiltroRipartizione.year;
      } else {
        return tx.date.year == _dataFiltroRipartizione.year &&
               tx.date.month == _dataFiltroRipartizione.month;
      }
    }).toList();

    double spesoRealeBisogni = 0;
    double spesoRealeSvago = 0;
    double spesoRealeRisparmio = 0;

    for (var tx in txsFiltrate) {
      final cat = tx.category.toLowerCase();
      if (cat.contains('30') || cat.contains('svag') || cat.contains('divertiment') || cat.contains('variabil')) {
        spesoRealeSvago += tx.amount;
      } else if (cat.contains('20') || cat.contains('risparm') || cat.contains('invest')) {
        spesoRealeRisparmio += tx.amount;
      } else {
        spesoRealeBisogni += tx.amount;
      }
    }

    final double totaleSpeseReali = spesoRealeBisogni + spesoRealeSvago + spesoRealeRisparmio;

    // Entrate di riferimento per calcolare i target 50/30/20 del periodo
    final double entratePeriodo = movimenti.where((tx) {
      if (!tx.isIncome) return false;
      if (_isVistaAnnuale) {
        return tx.date.year == _dataFiltroRipartizione.year;
      } else {
        return tx.date.year == _dataFiltroRipartizione.year &&
               tx.date.month == _dataFiltroRipartizione.month;
      }
    }).fold(0.0, (sum, tx) => sum + tx.amount);

    final double entrateRiferimento = entratePeriodo > 0 
        ? entratePeriodo 
        : (_isVistaAnnuale ? 30000.0 : 2500.0);

    final double targetBisogni = entrateRiferimento * 0.50;
    final double targetSvago = entrateRiferimento * 0.30;
    final double targetRisparmio = entrateRiferimento * 0.20;

    // 🔍 LOGICA FILTRAGGIO MOVIMENTI
    final List<dynamic> movimentiFiltrati = (() {
      final lista = List.from(movimenti);
      lista.sort((a, b) => b.date.compareTo(a.date));

      if (_filtroMeseMovimenti == 'ultimi_5') {
        return lista.take(5).toList();
      } else {
        final parts = _filtroMeseMovimenti.split('_');
        final m = int.tryParse(parts[0]) ?? 8;
        final y = int.tryParse(parts[1]) ?? 2026;
        return lista
            .where((tx) => tx.date.month == m && tx.date.year == y)
            .toList();
      }
    })();

    return Scaffold(
      backgroundColor: coloreSfondo,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 🎯 HEADER WALLET IMMERSIVO
            Stack(
              alignment: Alignment.center,
              children: [
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

                Positioned(
                  top: topPadding + 12,
                  left: 20,
                  child: const FiscOnLogo(
                    fontSize: 22,
                    sottotitolo: 'Portafoglio Personale',
                  ),
                ),

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
                      'RIEPILOGO',
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

                Padding(
                  padding: EdgeInsets.only(top: topPadding + 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

                      if (mostraPiva)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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

                                      InkWell(
                                        onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: coloreCard),
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

                  // 1. 📊 SCHEDA BUSSOLA SPESE (Ora posizionata in alto)
                  _buildRipartizioneSpeseCard(
                    spesoBisogni: spesoRealeBisogni,
                    spesoSvago: spesoRealeSvago,
                    spesoRisparmio: spesoRealeRisparmio,
                    totaleSpeseReali: totaleSpeseReali,
                    targetBisogni: targetBisogni,
                    targetSvago: targetSvago,
                    targetRisparmio: targetRisparmio,
                    entrateRiferimento: entrateRiferimento,
                  ),

                  const SizedBox(height: 16),

                  // 2. 3 QUADRANTI AZIONE (Interposti al centro)
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

                  // 3. SERBATOIO RISERVA TASSE (Sotto i 3 quadranti)
                  if (mostraPiva) ...[
                    GestureDetector(
                      onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: coloreCard),
                      child: SerbatoioTasseWidget(
                        cardColor: coloreCard,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

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

                  // 🎯 HEADER CON TITOLO E TENDINA SELETTORE MESI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MOVIMENTI',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: coloreCard.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: DropdownButton<String>(
                          value: _filtroMeseMovimenti,
                          dropdownColor: const Color(0xFF1C1C21),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2DD4BF), size: 16),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _filtroMeseMovimenti = val);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'ultimi_5', child: Text('Ultimi 5 recenti')),
                            DropdownMenuItem(value: '8_2026', child: Text('Agosto 2026')),
                            DropdownMenuItem(value: '7_2026', child: Text('Luglio 2026')),
                            DropdownMenuItem(value: '6_2026', child: Text('Giugno 2026')),
                            DropdownMenuItem(value: '5_2026', child: Text('Maggio 2026')),
                            DropdownMenuItem(value: '4_2026', child: Text('Aprile 2026')),
                            DropdownMenuItem(value: '3_2026', child: Text('Marzo 2026')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 📌 LISTA MOVIMENTI O STATO VUOTO
                  if (movimentiFiltrati.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: coloreCard.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: const Center(
                        child: Text(
                          'Nessun movimento in questo periodo',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...movimentiFiltrati.map((tx) => _buildTransactionTile(
                          icon: tx.isIncome ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined,
                          title: tx.title,
                          subtitle: tx.subtitle,
                          amount: '${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} €',
                          isIncome: tx.isIncome,
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📊 SCHEDA BUSSOLA SPESE (UX Flusso di Cassa: Margine Residuo Reale)
  Widget _buildRipartizioneSpeseCard({
    required double spesoBisogni,
    required double spesoSvago,
    required double spesoRisparmio,
    required double totaleSpeseReali,
    required double targetBisogni,
    required double targetSvago,
    required double targetRisparmio,
    required double entrateRiferimento,
  }) {
    final String etichettaPeriodo = _isVistaAnnuale
        ? '${_dataFiltroRipartizione.year}'
        : '${_nomiMesiBrevi[_dataFiltroRipartizione.month - 1]} ${_dataFiltroRipartizione.year}';

    // 🧠 CALCOLO DEL MARGINE RESIDUO REALE (Entrate - Spese di Consumo)
    final double speseConsumoTotali = spesoBisogni + spesoSvago;
    final double margineRisparmioReale = (entrateRiferimento - speseConsumoTotali).clamp(0.0, entrateRiferimento);

    final bool sforatoBisogni = spesoBisogni > targetBisogni && targetBisogni > 0;
    final bool sforatoSvago = spesoSvago > targetSvago && targetSvago > 0;
    final bool risparmioEroso = margineRisparmioReale < targetRisparmio && entrateRiferimento > 0;
    final bool haSforamenti = sforatoBisogni || sforatoSvago || risparmioEroso;

    final String testoBadgeHeader = haSforamenti ? '⚠️ Fuori Target' : 'In Equilibrio';
    final Color coloreBadgeHeader = haSforamenti ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    final double margineSvago = targetSvago - spesoSvago;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 1. HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.explore_rounded, color: Color(0xFF2DD4BF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Bussola Spese (50/30/20)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: coloreBadgeHeader.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  testoBadgeHeader,
                  style: TextStyle(
                    color: coloreBadgeHeader,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 📌 2. SELETTORE PERIODO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _cambiaPeriodoRipartizione(-1),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.chevron_left_rounded, color: Color(0xFF2DD4BF), size: 18),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    etichettaPeriodo,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _cambiaPeriodoRipartizione(1),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.chevron_right_rounded, color: Color(0xFF2DD4BF), size: 18),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isVistaAnnuale = false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: !_isVistaAnnuale ? const Color(0xFF2DD4BF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Mese',
                          style: TextStyle(
                            color: !_isVistaAnnuale ? Colors.black : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isVistaAnnuale = true),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isVistaAnnuale ? const Color(0xFF2DD4BF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Anno',
                          style: TextStyle(
                            color: _isVistaAnnuale ? Colors.black : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 📌 3. BARRA GLOBALE (100% Entrate = Verde + Arancio + Blu Residuo)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: Colors.white10,
              child: entrateRiferimento > 0
                  ? Row(
                      children: [
                        if (spesoBisogni > 0)
                          Expanded(
                            flex: (spesoBisogni / entrateRiferimento * 1000).toInt().clamp(1, 1000),
                            child: Container(color: const Color(0xFF2DD4BF)),
                          ),
                        if (spesoSvago > 0)
                          Expanded(
                            flex: (spesoSvago / entrateRiferimento * 1000).toInt().clamp(1, 1000),
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                        if (margineRisparmioReale > 0)
                          Expanded(
                            flex: (margineRisparmioReale / entrateRiferimento * 1000).toInt().clamp(1, 1000),
                            child: Container(color: const Color(0xFF3B82F6)),
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 14),

          // 📌 4. LE 3 RIGHE AGGIORNATE
          _buildRigaConfrontoRealeTarget(
            titolo: 'Bisogni Fissi',
            targetPct: 50,
            valoreReale: spesoBisogni,
            valoreRiferimento: targetBisogni,
            colore: const Color(0xFF2DD4BF),
          ),
          const SizedBox(height: 8),
          _buildRigaConfrontoRealeTarget(
            titolo: 'Spese Variabili & Libero',
            targetPct: 30,
            valoreReale: spesoSvago,
            valoreRiferimento: targetSvago,
            colore: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          _buildRigaConfrontoRealeTarget(
            titolo: 'Margine & Risparmio', // 👈 NUOVA LOGICA: MARGINE RESIDUO
            targetPct: 20,
            valoreReale: margineRisparmioReale,
            valoreRiferimento: targetRisparmio,
            colore: const Color(0xFF3B82F6),
            isRisparmio: true,
          ),

          // 📌 5. SUGGERIMENTO CONVERSAZIONALE
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                haSforamenti ? Icons.info_outline_rounded : Icons.lightbulb_outline_rounded,
                color: haSforamenti ? const Color(0xFFF59E0B) : const Color(0xFF2DD4BF),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  risparmioEroso
                      ? 'Attenzione: le spese stanno riducendo la quota da preservare per il futuro.'
                      : (haSforamenti
                          ? 'Consiglio: riduci le spese variabili per rientrare nei parametri.'
                          : 'Ottimo! Stai preservando oltre il 20% delle entrate per il tuo futuro.'),
                  style: TextStyle(
                    color: haSforamenti ? const Color(0xFFF59E0B) : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📌 RIGA INTELLIGENTE (Gestisce Spese massime vs Margine minimo)
  Widget _buildRigaConfrontoRealeTarget({
    required String titolo,
    required int targetPct,
    required double valoreReale,
    required double valoreRiferimento,
    required Color colore,
    bool isRisparmio = false,
  }) {
    // Per i consumi: allarme se SPESO > TARGET. Per il risparmio: allarme se MARGINE < TARGET MINIMO.
    final bool inAllarme = isRisparmio
        ? (valoreReale < valoreRiferimento && valoreRiferimento > 0)
        : (valoreReale > valoreRiferimento && valoreRiferimento > 0);

    final String etichettaTarget = isRisparmio
        ? 'min. ${valoreRiferimento.toStringAsFixed(0)} €'
        : '/ ${valoreRiferimento.toStringAsFixed(0)} €';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: colore, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              titolo,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 5),
            Text(
              '($targetPct%)',
              style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              '${valoreReale.toStringAsFixed(0)} €',
              style: TextStyle(
                color: inAllarme ? const Color(0xFFEF4444) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              etichettaTarget,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isRisparmio
                  ? (!inAllarme ? Icons.check_circle_rounded : Icons.warning_amber_rounded)
                  : (inAllarme ? Icons.error_outline_rounded : Icons.check_circle_rounded),
              color: isRisparmio
                  ? (!inAllarme ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                  : (inAllarme ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
              size: 13,
            ),
          ],
        ),
      ],
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
        height: 102,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            Icon(icon, color: iconColor ?? Colors.white70, size: 24),
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