import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '2_1_wallet_add_movement.dart';
import '2_2_wallet_manage_accounts.dart';
import '2_5_wallet_annual_summary.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/serbatoio_tasse_widget.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_bottom_sheet.dart'; // 👈 GUSCIO UNICO BOTTOM SHEET
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

  // 🎨 COLORI ACCENTO PER IL VETRO
  final Color oceanCyan  = const Color(0xFF38BDF8); 
  final Color goldAccent = const Color(0xFFFBBF24); 
  final Color purpleZen  = const Color(0xFFC084FC); 
  final Color taxBlue    = const Color(0xFF60A5FA); 

  // 👇 CONTATORE PER IL TEST DELLE FOTO
  int _testIndex = 0;

  // 📸 GALLERIA SFONDI (Link stabili di test)
  final List<String> _sfondiSettimanali = [
    'https://images.unsplash.com/photo-1505413687799-90481dfc0203?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fG1hcmV8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1555412654-72a95a495858?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YWNxdWF8ZW58MHx8MHx8fDA%3D',
    'https://plus.unsplash.com/premium_photo-1674517879286-0ee281fc5262?w=700&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDR8fHxlbnwwfHx8fHw%3D',
    'https://images.unsplash.com/photo-1481819613568-3701cbc70156?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8cGlhbmV0aXxlbnwwfHwwfHx8MA%3D%3D',
    'https://plus.unsplash.com/premium_photo-1711434824963-ca894373272e?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8bmF0dXJhfGVufDB8fDB8fHww',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8bmF0dXJhfGVufDB8fDB8fHww',
  ];

  bool _isBussolaEspansa = false;
  DateTime _dataFiltroRipartizione = DateTime(2026, 8);
  bool _isVistaAnnuale = false;

  final List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
  ];

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

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

  // 🛑 ALERT DI SICUREZZA PER ELIMINAZIONE TOTALE STORICO
  void _mostraAlertConfermaEliminazioneTotale(BuildContext context, String id, String desc) {
    showDialog(
      context: context,
      builder: (ctxAlert) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('⚠️ ELIMINAZIONE TOTALE', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Sei sicuro di voler eliminare TUTTI i movimenti di "$desc"?\n\n🚨 Verrà cancellato anche lo STORICO PASSATO nei mesi precedenti. L\'operazione è irreversibile.',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctxAlert),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              context.read<WalletProvider>().deleteTransaction(id);
              Navigator.pop(ctxAlert);
              setState(() {});
              AppNotifications.mostraInAlto(
                context,
                'Intera serie di "$desc" eliminata (compreso lo storico passato)',
                type: NotificationType.error,
              );
            },
            child: const Text('SÌ, ELIMINA TUTTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // 🔄 GESTIONE REGOLE RICORRENZA ED ELIMINAZIONE SINGOLA
  void _gestisciEliminazioneMovimento(BuildContext context, dynamic tx) {
    final bool isRecurrent = tx.isRecurrent ?? false;
    final String desc = tx.title ?? 'Movimento';
    final String id = tx.id as String;
    final DateTime date = tx.date as DateTime;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isRecurrent ? Icons.event_repeat_rounded : Icons.warning_amber_rounded, color: const Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isRecurrent ? 'Gestisci Ricorrenza' : 'Elimina Movimento',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRecurrent
                  ? 'Stai eliminando "$desc" (ricorrente).\nScegli come procedere:'
                  : 'Vuoi davvero eliminare "$desc"?\nIl saldo del conto verrà aggiornato.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (isRecurrent) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2DD4BF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    context.read<WalletProvider>().deleteButKeepRecurrence(id);
                    Navigator.pop(ctx);
                    setState(() {});
                    AppNotifications.mostraInAlto(context, 'Movimento eliminato solo per questo mese! 🎉');
                  },
                  child: const Text('Elimina solo questo mese', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    context.read<WalletProvider>().stopRecurrenceFromDate(id, date);
                    Navigator.pop(ctx);
                    setState(() {});
                    AppNotifications.mostraInAlto(
                      context,
                      'Ricorrenza disdetta da questo mese in poi! (Storico salvato)',
                      type: NotificationType.warning,
                    );
                  },
                  child: const Text('Elimina questa e future (Salva passato)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Elimina TUTTE (comprese le passate)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _mostraAlertConfermaEliminazioneTotale(context, id, desc);
                  },
                ),
              ),
            ],
          ],
        ),
        actions: isRecurrent
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    context.read<WalletProvider>().deleteTransaction(id);
                    Navigator.pop(ctx);
                    setState(() {});
                    AppNotifications.mostraInAlto(context, 'Movimento "$desc" eliminato 🎉');
                  },
                  child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
      ),
    );
  }
// 💳 MOSTRA MODALE MOVIMENTI FILTRATI PER SINGOLO CONTO (CON SWIPE-TO-DELETE E LIVE UPDATE)
  void _mostraMovimentiConto(BuildContext context, dynamic acc) {
    AppBottomSheet.mostra(
      context: context,
      child: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          // 💡 Calcola i movimenti in tempo reale. Se uno viene eliminato, la lista si aggiorna subito!
          final txsConto = walletProvider.transactions
              .where((tx) => tx.accountId == acc.id)
              .toList();
              
          txsConto.sort((a, b) => b.date.compareTo(a.date));

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ➖ BARRETTA DI TRASCINAMENTO (INDICATORE SWIPE-DOWN)
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (acc.color as Color).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: acc.color as Color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Movimenti: ${acc.title}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              acc.subtitle as String,
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (txsConto.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Nessun movimento registrato per questo conto.',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...txsConto.map((tx) {
                      final bool isIncome = tx.isIncome;
                      final Color color = isIncome ? oceanCyan : const Color(0xFFF43F5E);
                      final String sign = isIncome ? '+' : '-';
                      final String dateStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}';

                      return Dismissible(
                        key: Key('modal_dismiss_${tx.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8), // Allinea lo sfondo al bordo
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                        ),
                        confirmDismiss: (direction) async {
                          // Chiama la stessa funzione sicura del Wallet principale
                          _gestisciEliminazioneMovimento(context, tx);
                          return false; 
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: color,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      tx.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (tx.isRecurrent ?? false) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.sync_rounded, color: oceanCyan.withOpacity(0.8), size: 13),
                                  ],
                                ],
                              ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$dateStr • ${tx.category}',
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$sign${_formattaValuta(tx.amount)}',
                                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final String currentBackgroundUrl = _sfondiSettimanali[_testIndex % _sfondiSettimanali.length];

    final double topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    final walletProvider = context.watch<WalletProvider>();
    final patrimonioNetto = walletProvider.patrimonioNetto;
    final movimenti = walletProvider.transactions;
    final bool mostraPiva = widget.isPiva || walletProvider.isPartitaIVA;

    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    final double tasseDaAccantonare = walletProvider.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double residuoTasseDaCoprire = tasseDaAccantonare;

    final int mesiLavorati = walletProvider.mesiAttivi > 0 ? walletProvider.mesiAttivi : 10;
    final double percentualeFondoFerie = (12 - mesiLavorati) / 12;

    final double sommaContiLiquidi = walletProvider.accounts
        .where((a) => !a.title.toLowerCase().contains('salvadanaio tasse') && !a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double postTasse = (sommaContiLiquidi - tasseDaAccantonare).clamp(0.0, double.infinity);
    final double cuscinettoFerie = postTasse * percentualeFondoFerie;
    final double nettoRealeSpendibile = postTasse - cuscinettoFerie;
    
    final bool isTasseCoperte = residuoTasseDaCoprire <= 0.01;

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
      final bussola = walletProvider.ottieniBussolaSemplificata(tx);
      if (bussola == 'Svago') {
        spesoRealeSvago += tx.amount;
      } else if (bussola == 'Risparmi') {
        spesoRealeRisparmio += tx.amount;
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
        return lista.where((tx) => tx.date.month == m && tx.date.year == y).toList();
      }
    })();

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.75,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _testIndex++;
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  key: ValueKey<String>(currentBackgroundUrl),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(currentBackgroundUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.99),
                          Colors.black.withOpacity(0.4),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 16, left: 20, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _testIndex++;
                          });
                        },
                        child: const FiscOnLogo(fontSize: 22, sottotitolo: 'Portafoglio Personale'),
                      ),
                      
                      // 🚀 RIEPILOGO ANNUALE CON APP BOTTOM SHEET
                      _buildGlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => AppBottomSheet.mostra(context: context, child: const AnnualSummarySheet()),
                          child: Row(
                            children: [
                              Icon(Icons.show_chart_rounded, size: 14, color: oceanCyan),
                              const SizedBox(width: 6),
                              const Text('RIEPILOGO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 45),

                Center(
                  child: InkWell(
                    onLongPress: () {
                      AppPopupWrapper.mostraInfo(
                        context: context,
                        icon: Icons.account_balance_rounded,
                        color: Colors.white,
                        titolo: 'Patrimonio Netto',
                        descrizione: 'Somma totale dei saldi di tutti i tuoi conti correnti e del salvadanaio tasse.',
                      );
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        Text(
                          'PATRIMONIO NETTO',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formattaInt(patrimonioNetto),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.0,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 4))],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                if (mostraPiva)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 16),
                        _buildGlassBadge(
                          icon: Icons.payments_rounded,
                          color: oceanCyan,
                          value: _formattaInt(nettoRealeSpendibile),
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _buildGlassBadge(
                          icon: Icons.shield_outlined,
                          color: taxBlue,
                          value: _formattaInt(tasseTotaliCalcolate),
                          isTasse: true,
                          isProtetta: isTasseCoperte,
                          onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: const Color(0xFF18181B)),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),

                const SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 🚀 1. STORICO MOVIMENTI CON APP BOTTOM SHEET
                            Expanded(
                              child: _buildGlassMiniCard(
                                icon: Icons.add_circle_outline_rounded,
                                title: 'Storico\nMovimenti',
                                value: 'Riepilogo',
                                iconColor: oceanCyan,
                                onTap: () => AppBottomSheet.mostra(context: context, child: const AddMovementSheet(initialTab: 'riepilogo')),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 🚀 2. GESTIONE CONTI CON APP BOTTOM SHEET
                            Expanded(
                              child: _buildGlassMiniCard(
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'I Tuoi\nConti',
                                value: '${walletProvider.accounts.length} Attivi',
                                iconColor: goldAccent,
                                onTap: () => AppBottomSheet.mostra(context: context, child: ManageAccountsSheet(isPiva: widget.isPiva)),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 🚀 3. PIANO SPESA CON APP BOTTOM SHEET
                            Expanded(
                              child: _buildGlassMiniCard(
                                icon: Icons.pie_chart_outline_rounded,
                                title: 'Gestione\nSpese',
                                value: 'Budget',
                                iconColor: purpleZen,
                                onTap: () => AppBottomSheet.mostra(context: context, child: const PianoSpesaSheet()),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildRipartizioneSpeseGlass(
                        spesoBisogni: spesoRealeBisogni,
                        spesoSvago: spesoRealeSvago,
                        spesoRisparmio: spesoRealeRisparmio,
                        totaleSpeseReali: totaleSpeseReali,
                        targetBisogni: targetBisogni,
                        targetSvago: targetSvago,
                        targetRisparmio: targetRisparmio,
                        entrateRiferimento: entrateRiferimento,
                      ),

                      const SizedBox(height: 24),

                      if (mostraPiva) ...[
                        _buildGlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(24),
                          child: const SerbatoioTasseWidget(
                            cardColor: Colors.transparent,
                            isCollapsible: true,
                            initiallyExpanded: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'CONTI & CARTE',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassContainer(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: walletProvider.accounts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final acc = entry.value;
                            final bool isLast = index == walletProvider.accounts.length - 1;

                            final bool isSerbatoioTasse = acc.role == AccountRole.taxReserve || acc.id == '3';
                            final IconData iconaConto = isSerbatoioTasse
                                ? Icons.shield_outlined
                                : (acc.id == '1' ? Icons.account_balance_rounded : (acc.id == '2' ? Icons.credit_card_rounded : Icons.savings_rounded));

                            return Column(
                              children: [
                                _buildAccountRow(
                                  icon: iconaConto,
                                  title: acc.title,
                                  subtitle: acc.subtitle,
                                  amount: _formattaValuta(acc.amount),
                                  color: acc.color,
                                  onTap: () => _mostraMovimentiConto(context, acc),
                                ),
                                if (!isLast) Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 20, endIndent: 20),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MOVIMENTI',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                            _buildGlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              borderRadius: BorderRadius.circular(12),
                              child: DropdownButton<String>(
                                value: _filtroMeseMovimenti,
                                dropdownColor: const Color(0xFF18181B),
                                underline: const SizedBox(),
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: oceanCyan, size: 16),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                onChanged: (val) {
                                  if (val != null) setState(() => _filtroMeseMovimenti = val);
                                },
                                items: const [
                                  DropdownMenuItem(value: 'ultimi_5', child: Text('Ultimi 5')),
                                  DropdownMenuItem(value: '8_2026', child: Text('Agosto 2026')),
                                  DropdownMenuItem(value: '7_2026', child: Text('Luglio 2026')),
                                  DropdownMenuItem(value: '6_2026', child: Text('Giugno 2026')),
                                  DropdownMenuItem(value: '5_2026', child: Text('Maggio 2026')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (movimentiFiltrati.isEmpty)
                        _buildGlassContainer(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(child: Text('Nessun movimento in questo periodo', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13))),
                        )
                      else
                        _buildGlassContainer(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: (() {
                              final List<Map<String, dynamic>> movimentiUnici = [];
                              final Set<String> chiaviProcessate = {};
                              for (int i = 0; i < movimentiFiltrati.length; i++) {
                                final tx = movimentiFiltrati[i];
                                final String catLower = (tx.category ?? '').toLowerCase();
                                final String titleLower = (tx.title ?? '').toLowerCase();
                                final bool isTrasferimento = catLower.contains('giroconto') || titleLower.contains('giroconto') || titleLower.contains('accantonamento') || titleLower.contains('sblocco') || titleLower.contains('riserva');

                                if (isTrasferimento) {
                                  final String chiave = '${tx.date.year}_${tx.date.month}_${tx.date.day}_${tx.date.hour}_${tx.date.minute}_${tx.amount.abs().toStringAsFixed(2)}';
                                  if (chiaviProcessate.contains(chiave)) {
                                    final idx = movimentiUnici.indexWhere((m) => m['chiave'] == chiave);
                                    if (idx != -1) {
                                      if (tx.isIncome) movimentiUnici[idx]['toAccountId'] = tx.accountId;
                                      else movimentiUnici[idx]['fromAccountId'] = tx.accountId;
                                    }
                                    continue;
                                  }
                                  chiaviProcessate.add(chiave);
                                  movimentiUnici.add({ 'chiave': chiave, 'tx': tx, 'fromAccountId': !tx.isIncome ? tx.accountId : null, 'toAccountId': tx.isIncome ? tx.accountId : null });
                                } else {
                                  movimentiUnici.add({ 'chiave': 'tx_$i', 'tx': tx, 'fromAccountId': tx.accountId, 'toAccountId': null });
                                }
                              }
                              return movimentiUnici.asMap().entries.map((entry) {
                                final txData = entry.value;
                                final isLast = entry.key == movimentiUnici.length - 1;
                                final tx = txData['tx'];

                                return Column(
                                  children: [
                                    Dismissible(
                                      key: Key('dismiss_${tx.id}_${entry.key}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444).withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                      ),
                                      confirmDismiss: (direction) async {
                                        _gestisciEliminazioneMovimento(context, tx);
                                        return false;
                                      },
                                      child: _buildTransactionRow(
                                        tx: tx,
                                        fromAccountId: txData['fromAccountId'],
                                        toAccountId: txData['toAccountId'],
                                      ),
                                    ),
                                    if (!isLast) Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 20, endIndent: 20),
                                  ],
                                );
                              }).toList();
                            })(),
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
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), 
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06), 
            borderRadius: radius,
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassBadge({required IconData icon, required Color color, required String value, bool isTasse = false, bool isProtetta = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassContainer(
        padding: const EdgeInsets.only(left: 6, right: 16, top: 6, bottom: 6),
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            if (isTasse) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isProtetta ? oceanCyan.withOpacity(0.3) : color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isProtetta
                    ? Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: oceanCyan, size: 10),
                          const SizedBox(width: 4),
                          Text('Protette', style: TextStyle(color: oceanCyan, fontSize: 9, fontWeight: FontWeight.w800)),
                        ],
                      )
                    : Text('Accantona', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildGlassMiniCard({required IconData icon, required String title, required String value, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, height: 1.2, fontWeight: FontWeight.w600), maxLines: 2),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRipartizioneSpeseGlass({
    required double spesoBisogni, required double spesoSvago, required double spesoRisparmio,
    required double totaleSpeseReali, required double targetBisogni, required double targetSvago,
    required double targetRisparmio, required double entrateRiferimento,
  }) {
    final bool sforatoBisogni = spesoBisogni > targetBisogni && targetBisogni > 0;
    final bool sforatoSvago = spesoSvago > targetSvago && targetSvago > 0;
    final double margineRisparmioReale = (entrateRiferimento - spesoBisogni - spesoSvago).clamp(0.0, entrateRiferimento);
    final bool risparmioEroso = margineRisparmioReale < targetRisparmio && entrateRiferimento > 0;
    final bool haSforamenti = sforatoBisogni || sforatoSvago || risparmioEroso;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isBussolaEspansa = !_isBussolaEspansa),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: purpleZen.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.explore_rounded, color: purpleZen, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Text('Bussola Spese (50/30/20)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: haSforamenti ? const Color(0xFFEF4444).withOpacity(0.2) : oceanCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(haSforamenti ? '⚠️ Fuori Target' : 'In Equilibrio', style: TextStyle(color: haSforamenti ? const Color(0xFFEF4444) : oceanCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            if (_isBussolaEspansa) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(onTap: () => _cambiaPeriodoRipartizione(-1), child: Icon(Icons.chevron_left_rounded, color: oceanCyan)),
                      const SizedBox(width: 8),
                      Text(_isVistaAnnuale ? '${_dataFiltroRipartizione.year}' : '${_nomiMesiBrevi[_dataFiltroRipartizione.month - 1]} ${_dataFiltroRipartizione.year}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      InkWell(onTap: () => _cambiaPeriodoRipartizione(1), child: Icon(Icons.chevron_right_rounded, color: oceanCyan)),
                      if (_dataFiltroRipartizione.year != DateTime.now().year || _dataFiltroRipartizione.month != DateTime.now().month) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _dataFiltroRipartizione = DateTime.now()),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: oceanCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: oceanCyan.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Oggi',
                              style: TextStyle(color: oceanCyan, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(onTap: () => setState(() => _isVistaAnnuale = false), child: Text('Mese', style: TextStyle(color: !_isVistaAnnuale ? oceanCyan : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
                      const SizedBox(width: 12),
                      GestureDetector(onTap: () => setState(() => _isVistaAnnuale = true), child: Text('Anno', style: TextStyle(color: _isVistaAnnuale ? oceanCyan : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 8,
                  color: Colors.white.withOpacity(0.1),
                  child: entrateRiferimento > 0 ? Row(
                    children: [
                      if (spesoBisogni > 0) Expanded(flex: (spesoBisogni / entrateRiferimento * 1000).toInt(), child: Container(color: oceanCyan)),
                      if (spesoSvago > 0) Expanded(flex: (spesoSvago / entrateRiferimento * 1000).toInt(), child: Container(color: goldAccent)),
                      if (margineRisparmioReale > 0) Expanded(flex: (margineRisparmioReale / entrateRiferimento * 1000).toInt(), child: Container(color: purpleZen)),
                    ],
                  ) : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildTargetRow('Spese Fisse', 50, spesoBisogni, targetBisogni, oceanCyan),
              const SizedBox(height: 12),
              _buildTargetRow('Spese Variabili', 30, spesoSvago, targetSvago, goldAccent),
              const SizedBox(height: 12),
              _buildTargetRow('Risparmio', 20, margineRisparmioReale, targetRisparmio, purpleZen, isRisparmio: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRow(String title, int pct, double real, double target, Color color, {bool isRisparmio = false}) {
    final bool inAllarme = isRisparmio ? (real < target && target > 0) : (real > target && target > 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('($pct%)', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ],
        ),
        Row(
          children: [
            Text(_formattaInt(real), style: TextStyle(color: inAllarme ? const Color(0xFFEF4444) : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text('/ ${_formattaInt(target)}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildAccountRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow({required dynamic tx, String? fromAccountId, String? toAccountId}) {
    final walletProvider = context.watch<WalletProvider>();
    String getNome(String? id) => id != null ? (walletProvider.accounts.firstWhere((a) => a.id == id, orElse: () => walletProvider.accounts.first).title) : '';

    String titleLower = tx.title.toLowerCase();
    IconData icon = Icons.receipt_long_rounded;
    Color color = tx.isIncome ? oceanCyan : const Color(0xFFF43F5E);
    String amountStr = (tx.isIncome ? '+' : '-') + _formattaValuta(tx.amount).replaceAll('+', '').replaceAll('-', '');
    String detail = tx.subtitle;

    if (titleLower.contains('accantonamento')) { icon = Icons.shield_rounded; color = taxBlue; detail = 'Verso Salvadanaio Tasse'; amountStr = _formattaValuta(tx.amount); }
    else if (titleLower.contains('sblocco')) { icon = Icons.shield_outlined; color = goldAccent; detail = 'Da Salvadanaio Tasse'; amountStr = _formattaValuta(tx.amount); }
    else if (titleLower.contains('giroconto')) { icon = Icons.sync_alt_rounded; color = Colors.white54; detail = 'Tra i tuoi conti'; amountStr = _formattaValuta(tx.amount); }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tx.title.replaceAll('⚠️', '').replaceAll('🛡️', '').trim(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tx.isRecurrent ?? false) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.sync_rounded, color: oceanCyan.withOpacity(0.8), size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(detail.split('-').first.trim(), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(amountStr, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }
}