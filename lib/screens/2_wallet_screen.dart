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
import '../data/advisor_engine.dart';
import '../widgets_shared/advisor_tip_card.dart';

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
  bool _isBussolaEspansa = false; // 👈 Aggiungiamo lo stato (di base è chiusa)

  // 📅 STATI PER IL SELETTORE TEMPORALE DELLA RIPARTIZIONE SPESE
  DateTime _dataFiltroRipartizione = DateTime(2026, 8);
  bool _isVistaAnnuale = false;

  final List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
  ];

  // 🇮🇹 HELPER VALUTA ITALIANA CON DECIMALI (es. 1.000,50 €)
  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  // 🇮🇹 HELPER CIFRA INTERA SENZA DECIMALI CON PUNTO MIGLIAIA (es. 1.000 €)
  String _formattaInt(double importo) {
    final int intVal = importo.round();
    final strVal = intVal.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$strVal €';
  }

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

    // 📌 CALCOLO NETTO SPENDIBILE PRUDENZIALE (CON CUSCINETTO NO-LAVORO)
    final int mesiLavorati = walletProvider.mesiAttivi > 0 ? walletProvider.mesiAttivi : 10;
    final double percentualeFondoFerie = (12 - mesiLavorati) / 12;

    final double sommaContiLiquidi = walletProvider.accounts
        .where((a) => !a.title.toLowerCase().contains('salvadanaio tasse') && !a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double postTasse = (sommaContiLiquidi - tasseDaAccantonare).clamp(0.0, double.infinity);
    final double cuscinettoFerie = postTasse * percentualeFondoFerie;
    final double nettoRealeSpendibile = postTasse - cuscinettoFerie;
    
    final bool isTasseCoperte = residuoTasseDaCoprire <= 0.01;

    // 🤖 CALCOLO DINAMICO DELLE SPESE REALI PER IL PERIODO SELEZIONATO
    final txsFiltrate = movimenti.where((tx) {
      if (tx.isIncome) return false;
      if (tx.category == 'Giroconto' || tx.title.toLowerCase().contains('giroconto')) return false;

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
      } else if (cat.contains('50') || cat.contains('fiss') || cat.contains('alimentar') || cat.contains('casa') || cat.contains('bollet') || cat.contains('auto')) {
        spesoRealeBisogni += tx.amount;
      } else {
        spesoRealeBisogni += tx.amount;
      }
    }

    final double totaleSpeseReali = spesoRealeBisogni + spesoRealeSvago + spesoRealeRisparmio;

    final double entratePeriodo = movimenti.where((tx) {
      if (!tx.isIncome) return false;
      if (tx.category == 'Giroconto' || tx.title.toLowerCase().contains('giroconto')) return false;

      if (_isVistaAnnuale) {
        return tx.date.year == _dataFiltroRipartizione.year;
      } else {
        return tx.date.year == _dataFiltroRipartizione.year &&
               tx.date.month == _dataFiltroRipartizione.month;
      }
    }).fold(0.0, (sum, tx) => sum + tx.amount);

    final double entrateRiferimento = entratePeriodo > 0 ? entratePeriodo : walletProvider.fatturatoTotale;

    final double targetBisogni = entrateRiferimento * 0.50;
    final double targetSvago = entrateRiferimento * 0.30;
    final double targetRisparmio = entrateRiferimento * 0.20;

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
        padding: const EdgeInsets.only(bottom: 50), // 👈 Margine di sicurezza per svincolare i movimenti dalla Bottom Bar
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. IMMAGINE DI SFONDO (Più alta per scendere dietro alla bussola)
                Container(
                  height: headerHeight + 100, // 👈 Allungato
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
                
                // GRADIENTE Mimetico (Il trucco per far sparire il "taglio")
                Container(
                  height: headerHeight + 100, // 👈 Stessa altezza
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.85, 1.0], // 👈 IL SEGRETO: Le percentuali di sfumatura
                      colors: [
                        coloreSfondo.withOpacity(0.0), // Inizia totalmente trasparente
                        coloreSfondo.withOpacity(0.5), // A metà scurisce
                        coloreSfondo, // All'85% dello spazio diventa GIÀ del colore di sfondo solido
                        coloreSfondo, // Al 100% rimane solido, annullando il bordo netto!
                      ],
                    ),
                  ),
                ),

               // 2. ✨ EFFETTO GLOW (Luce Bianca Premium - Glassmorphism)
                Positioned(
                  top: -60,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12), // 👈 Bianco al 12%
                      boxShadow: [
                        BoxShadow(color: Colors.white.withOpacity(0.12), blurRadius: 100, spreadRadius: 40)
                      ],
                    ),
                  ),
                ),

                // 3. LOGO Fisco Zen
                Positioned(
                  top: topPadding + 12,
                  left: 20,
                  child: const FiscOnLogo(
                    fontSize: 22,
                    sottotitolo: 'Portafoglio Personale',
                  ),
                ),

                // 4. TASTO RIEPILOGO
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
                      backgroundColor: Colors.white.withOpacity(0.1), // 👈 Un pelo più visibile
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: 0,
                    ),
                  ),
                ),

                // 5. CARD PATRIMONIO NETTO (Vetro più definito e luminoso)
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 10),
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
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.transparent, // 👈 Trasparente, niente sfondo o vetro
                          ),
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
                              const SizedBox(height: 4),
                              Text(
                                _formattaInt(patrimonioNetto),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (mostraPiva)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // PILLOLA LIQUIDITÀ (Verde)
                              InkWell(
                                onTap: () {},
                                onLongPress: () {
                                  AppPopupWrapper.mostraInfo(
                                    context: context,
                                    icon: Icons.payments_rounded,
                                    color: const Color(0xFF10B981),
                                    titolo: 'Liquidità Reale Spendibile',
                                    descrizione: 'Sono i tuoi veri soldi personali spendibili in serenità. Calcolati prendendo i saldi dei tuoi conti e togliendo sia le tasse stimate che il cuscinetto di protezione per i mesi non lavorati.',
                                    formula: 'Conti Liquidi − Tasse − Cuscinetto No-Lavoro',
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 12),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formattaInt(nettoRealeSpendibile),
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

                              // PILLOLA TASSE (Blu/Viola - Ora con lo Scudo!)
                              InkWell(
                                onTap: () {},
                                onLongPress: () {
                                  AppPopupWrapper.mostraInfo(
                                    context: context,
                                    icon: Icons.shield_outlined, // 👈 Scudo!
                                    color: const Color(0xFF3B82F6),
                                    titolo: 'Riserva Tasse Calcolata',
                                    descrizione: 'È la stima totale delle tasse dovute sulle fatture incassate (Imposta Sostitutiva + INPS).',
                                    formula: 'Stima Fiscale ATECO + Contributi',
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 12), // 👈 Scudo Vuoto!
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formattaInt(tasseTotaliCalcolate),
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // TASTO ACCANTONA DENTRO LA PILLOLA
                                      InkWell(
                                        onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: coloreCard),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isTasseCoperte
                                                ? const Color(0xFF10B981).withOpacity(0.2)
                                                : const Color(0xFF3B82F6),
                                            borderRadius: BorderRadius.circular(12),
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

            // ✨ INIZIO DEL TRUCCO ✨
            Transform.translate(
              offset: const Offset(0, -50), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),

                    // 1. I TRE BOTTONI IN PRIMA LINEA (Subito sotto il saldo!)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildMiniCard(
                              icon: Icons.add_circle_outline_rounded,
                              title: 'Movimenti',
                              value: 'Entrata / Uscita',
                              iconColor: const Color(0xFF10B981),
                              valueColor: Colors.white,
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
                              value: '${walletProvider.accounts.length} Attivi',
                              iconColor: const Color(0xFFF59E0B),
                              valueColor: Colors.white,
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
                              title: 'Pianificazione\nSpese',
                              value: 'Budget',
                              iconColor: const Color(0xFF8B5CF6),
                              valueColor: Colors.white,
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
                    ),

                    const SizedBox(height: 16), // 👈 Spazio tra bottoni e bussola

                    // 🤖 IL CONSULENTE VIRTUALE DEL WALLET (Regole Personali)
      Builder(
        builder: (context) {
          final walletProvider = context.watch<WalletProvider>();
          final tips = AdvisorEngine.getPersonalTips(walletProvider);

          if (tips.isEmpty) return const SizedBox.shrink();

          final currentTip = tips.first;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AdvisorTipCard(
              mood: currentTip.mood,
              title: currentTip.title,
              message: currentTip.message,
              actionText: currentTip.actionText,
              icon: currentTip.icon,
              onDismiss: () => walletProvider.dismissAdvisorTip(currentTip.title),
              onAction: () {
                // Eventuale azione custom per il Wallet
              },
            ),
          );
        }
      ),

                    // 2. LA BUSSOLA SPESE (Scivolata in seconda posizione)
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

                  if (mostraPiva) ...[
                    SerbatoioTasseWidget(
                      cardColor: coloreCard, // Usa il colore standard della card
                      isCollapsible: true,   // Abilita la tendina
                      initiallyExpanded: true, // 🟢 Parte già aperto all'avvio!
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  const Text(
                    'CONTI & CARTE',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: coloreCard.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: walletProvider.accounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final acc = entry.value;
                        final bool isLast = index == walletProvider.accounts.length - 1;

                        final bool isSerbatoioTasse = acc.role == AccountRole.taxReserve || acc.id == '3';
                        final IconData iconaConto = isSerbatoioTasse
                            ? Icons.shield_outlined
                            : (acc.id == '1'
                                ? Icons.account_balance_rounded
                                : (acc.id == '2' ? Icons.credit_card_rounded : Icons.savings_rounded));

                        return Column(
                          children: [
                            _buildAccountCard(
                              icon: iconaConto,
                              title: acc.title,
                              subtitle: acc.subtitle,
                              amount: _formattaValuta(acc.amount),
                              color: acc.color,
                            ),
                            if (!isLast) Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 16, endIndent: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

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
                    ...(() {
                      final List<Map<String, dynamic>> movimentiUnici = [];
                      final Set<String> chiaviProcessate = {};

                      for (int i = 0; i < movimentiFiltrati.length; i++) {
                        final tx = movimentiFiltrati[i];
                        final String catLower = (tx.category ?? '').toLowerCase();
                        final String titleLower = (tx.title ?? '').toLowerCase();

                        final bool isTrasferimento = catLower.contains('giroconto') ||
                            titleLower.contains('giroconto') ||
                            titleLower.contains('accantonamento') ||
                            titleLower.contains('sblocco') ||
                            titleLower.contains('riserva');

                        if (isTrasferimento) {
                          final String chiave = '${tx.date.year}_${tx.date.month}_${tx.date.day}_${tx.date.hour}_${tx.date.minute}_${tx.amount.abs().toStringAsFixed(2)}';

                          if (chiaviProcessate.contains(chiave)) {
                            final idx = movimentiUnici.indexWhere((m) => m['chiave'] == chiave);
                            if (idx != -1) {
                              if (tx.isIncome) {
                                movimentiUnici[idx]['toAccountId'] = tx.accountId;
                              } else {
                                movimentiUnici[idx]['fromAccountId'] = tx.accountId;
                              }
                            }
                            continue;
                          }

                          chiaviProcessate.add(chiave);
                          movimentiUnici.add({
                            'chiave': chiave,
                            'tx': tx,
                            'fromAccountId': !tx.isIncome ? tx.accountId : null,
                            'toAccountId': tx.isIncome ? tx.accountId : null,
                          });
                        } else {
                          movimentiUnici.add({
                            'chiave': 'tx_$i',
                            'tx': tx,
                            'fromAccountId': tx.accountId,
                            'toAccountId': null,
                          });
                        }
                      }

                      return movimentiUnici.map((item) {
                        final tx = item['tx'];
                        return _buildTransactionTile(
                          title: tx.title,
                          subtitle: tx.subtitle,
                          amount: _formattaValuta(tx.amount),
                          isIncome: tx.isIncome,
                          fromAccountId: item['fromAccountId'] as String?,
                          toAccountId: item['toAccountId'] as String?,
                        );
                      });
                    })(),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

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

    final double speseConsumoTotali = spesoBisogni + spesoSvago;
    final double margineRisparmioReale = (entrateRiferimento - speseConsumoTotali).clamp(0.0, entrateRiferimento);

    final bool sforatoBisogni = spesoBisogni > targetBisogni && targetBisogni > 0;
    final bool sforatoSvago = spesoSvago > targetSvago && targetSvago > 0;
    final bool risparmioEroso = margineRisparmioReale < targetRisparmio && entrateRiferimento > 0;
    final bool haSforamenti = sforatoBisogni || sforatoSvago || risparmioEroso;

    final String testoBadgeHeader = haSforamenti ? '⚠️ Fuori Target' : 'In Equilibrio';
    final Color coloreBadgeHeader = haSforamenti ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300), // Effetto tendina fluido!
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✨ 1. HEADER CLICCABILE
            GestureDetector(
              behavior: HitTestBehavior.opaque, // 👈 LA MAGIA: Rende cliccabile TUTTA la riga, anche lo spazio vuoto!
              onTap: () {
                setState(() {
                  _isBussolaEspansa = !_isBussolaEspansa; // Apre/Chiude
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4), // 👈 Dà un po' più di spessore per il tocco del dito
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore_rounded, color: Color(0xFF8B5CF6), size: 18), // 🟣 Viola Neon/Pianificazione
                        const SizedBox(width: 8),
                        const Text(
                          'Bussola Spese (50/30/20)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isBussolaEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                          size: 16,
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
              ),
            ),

            // ✨ 2. IL CORPO DELLA BUSSOLA (Visibile solo se aperta)
            if (_isBussolaEspansa) ...[
              const SizedBox(height: 14),

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
                                child: Container(color: const Color(0xFF10B981)), // Verde
                              ),
                            if (spesoSvago > 0)
                              Expanded(
                                flex: (spesoSvago / entrateRiferimento * 1000).toInt().clamp(1, 1000),
                                child: Container(color: const Color(0xFFF59E0B)), // Arancio
                              ),
                            if (margineRisparmioReale > 0)
                              Expanded(
                                flex: (margineRisparmioReale / entrateRiferimento * 1000).toInt().clamp(1, 1000),
                                child: Container(color: const Color(0xFF8B5CF6)), // Viola
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 14),

              _buildRigaConfrontoRealeTarget(
                titolo: 'Spese Fisse & Bisogni',
                targetPct: 50,
                valoreReale: spesoBisogni,
                valoreRiferimento: targetBisogni,
                colore: const Color(0xFF10B981),
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
                titolo: 'Risparmi & Futuro',
                targetPct: 20,
                valoreReale: margineRisparmioReale,
                valoreRiferimento: targetRisparmio,
                colore: const Color(0xFF8B5CF6),
                isRisparmio: true,
              ),

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
            ], // <-- Fine blocco if(_isBussolaEspansa)
          ],
        ),
      ),
    );
  }

  Widget _buildRigaConfrontoRealeTarget({
    required String titolo,
    required int targetPct,
    required double valoreReale,
    required double valoreRiferimento,
    required Color colore,
    bool isRisparmio = false,
  }) {
    final bool inAllarme = isRisparmio
        ? (valoreReale < valoreRiferimento && valoreRiferimento > 0)
        : (valoreReale > valoreRiferimento && valoreRiferimento > 0);

    final String etichettaTarget = isRisparmio
        ? 'min. ${_formattaInt(valoreRiferimento)}'
        : '/ ${_formattaInt(valoreRiferimento)}';

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
              _formattaInt(valoreReale),
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
    final accentColor = iconColor ?? const Color(0xFF2DD4BF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: coloreCard.withOpacity(0.4), // 🥷 Sfondo scuro e minimale (niente colore di fondo invasivo)
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.35), // 💡 Bordo sottile con il colore tematico
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08), // ✨ Leggerissimo bagliore neon sul bordo
              blurRadius: 12,
              spreadRadius: -2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white, // Testo candido, pulito ed elegante
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
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
          Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile({
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
    String? fromAccountId,
    String? toAccountId,
    String? fallbackAccountName,
    IconData icon = Icons.receipt_long_rounded,
  }) {
    final walletProvider = context.watch<WalletProvider>();

    String getNomeConto(String? id, String defaultName) {
      if (id != null && id.isNotEmpty) {
        final matches = walletProvider.accounts.where((acc) => acc.id == id);
        if (matches.isNotEmpty && matches.first.title.isNotEmpty) {
          return matches.first.title;
        }
      }
      return defaultName;
    }

    String dataStr = subtitle;
    if (subtitle.contains('-')) {
      dataStr = subtitle.split('-').first.trim();
    } else if (subtitle.contains('•')) {
      dataStr = subtitle.split('•').first.trim();
    }

    final String titoloPulito = title.replaceAll('⚠️', '').replaceAll('🛡️', '').trim();
    final String titleLower = titoloPulito.toLowerCase();
    final String importoPuro = amount.replaceAll('+', '').replaceAll('-', '').trim();

    IconData iconaFinale = icon;
    Color coloreIcona = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    Color coloreImporto = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    String titoloBreve = titoloPulito;
    String importoFormattato = isIncome ? '+$importoPuro' : '-$importoPuro';
    String rigaDettaglio = subtitle;

    // 1. 🛡️ ACCANTONAMENTO TASSE (Scudo Blu)
    if (titleLower.contains('accantonamento') || titleLower.contains('ricezione riserva') || titleLower.contains('versamento riserva')) {
      iconaFinale = Icons.shield_rounded;
      coloreIcona = const Color(0xFF3B82F6);
      coloreImporto = const Color(0xFF3B82F6);
      titoloBreve = 'Accantonamento Tasse';
      importoFormattato = importoPuro;

      final String da = getNomeConto(fromAccountId, fallbackAccountName ?? 'Conto Liquido');
      final String a = getNomeConto(toAccountId, 'Salvadanaio Tasse');
      rigaDettaglio = '$dataStr • Da $da ➔ $a';

    // 2. 🔓 SBLOCCO RISERVA TASSE (Scudo Giallo)
    } else if (titleLower.contains('rientro') || titleLower.contains('prelievo da riserva') || titleLower.contains('sblocco')) {
      iconaFinale = Icons.shield_outlined;
      coloreIcona = const Color(0xFFF59E0B);
      coloreImporto = const Color(0xFFF59E0B);
      titoloBreve = 'Sblocco Riserva';
      importoFormattato = importoPuro;

      final String da = getNomeConto(fromAccountId, 'Salvadanaio Tasse');
      final String a = getNomeConto(toAccountId, fallbackAccountName ?? 'Conto Liquido');
      rigaDettaglio = '$dataStr • Da $da ➔ $a';

    // 3. 🔄 GIROCONTO ORDINARIO (Grigio Neutro)
    } else if (titleLower.contains('giroconto')) {
      iconaFinale = Icons.sync_alt_rounded;
      coloreIcona = const Color(0xFFA1A1AA);
      coloreImporto = const Color(0xFFA1A1AA);
      titoloBreve = 'Giroconto';
      importoFormattato = importoPuro;

      final String da = getNomeConto(fromAccountId, fallbackAccountName ?? 'Conto Origine');
      final String a = getNomeConto(toAccountId, 'Conto Destinazione');
      rigaDettaglio = '$dataStr • Da $da ➔ $a';

    // 4. 💼 STIPENDIO / ENTRATE / USCITE
    } else {
      if (titleLower.contains('stipendio') || titleLower.contains('busta paga')) {
        iconaFinale = Icons.work_rounded;
        coloreIcona = const Color(0xFF10B981);
      } else if (titleLower.contains('incasso') || titleLower.contains('fattura')) {
        iconaFinale = Icons.request_quote_rounded;
      } else if (!isIncome) {
        if (titleLower.contains('affitto')) {
          iconaFinale = Icons.home_rounded;
        } else if (titleLower.contains('supermercato') || titleLower.contains('alimentari')) {
          iconaFinale = Icons.shopping_cart_rounded;
        } else if (titleLower.contains('ristorante') || titleLower.contains('bar')) {
          iconaFinale = Icons.restaurant_rounded;
        } else {
          iconaFinale = Icons.north_east_rounded;
        }
      }

      final String nomeConto = getNomeConto(fromAccountId, fallbackAccountName ?? '');
      rigaDettaglio = nomeConto.isNotEmpty ? '$dataStr • $nomeConto' : subtitle;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: coloreIcona.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconaFinale, color: coloreIcona, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titoloBreve,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rigaDettaglio,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                importoFormattato,
                style: TextStyle(
                  color: coloreImporto,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.white.withOpacity(0.06), height: 1),
      ],
    );
  }
}