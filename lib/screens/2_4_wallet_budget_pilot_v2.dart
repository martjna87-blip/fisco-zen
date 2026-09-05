import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '../widgets_shared/app_secondary_popup.dart';
import '0_1_pro_upgrade.dart';
import '../widgets_shared/app_datepicker.dart';
import '../widgets_shared/app_action_card.dart';
import '../screens/0_1_pro_upgrade.dart';

class PianoSpesaSheet extends StatefulWidget {
  const PianoSpesaSheet({super.key});

  @override
  State<PianoSpesaSheet> createState() => _PianoSpesaSheetState();
}

class _PianoSpesaSheetState extends State<PianoSpesaSheet> {
  int _tabSelezionata = 0; // 0 = 🔄 Ricorrenze, 1 = 🎯 Pilotaggio & Regole
  int _subTabRicorrenze = 0; // 👈 AGGIUNTO: 0 = Attive, 1 = Passate
  final Color oceanCyan   = const Color(0xFF38BDF8);
  final Color goldAccent  = const Color(0xFFFBBF24);
  final Color purpleZen   = const Color(0xFFC084FC);
  final Color greenProfit = const Color(0xFF10B981);

  final List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
  ];

  String _formattaInt(double importo) {
    final intVal = importo.round();
    final strVal = intVal.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$strVal €';
  }

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  // 🚀 APERTURA DEL NUOVO PAYWALL PREMIUM
  void _mostraModalPRO(BuildContext context) {
    AppBottomSheet.mostra(
      context: context,
      child: const ProUpgradeSheet(funzionalita: 'Pianificazione Strategica'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final walletProvider = context.watch<WalletProvider>();
    final bool isPro = walletProvider.isProUser;

    return AppBottomSheet(
      title: 'Pianificazione Strategica',
      badgeText: isPro ? 'PRO' : 'Demo',
      badgeColor: isPro ? greenProfit : goldAccent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.65,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔘 SELETTORE TAB MINIMALE
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabSelezionata = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tabSelezionata == 0 ? oceanCyan.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tabSelezionata == 0 ? oceanCyan : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sync_rounded, color: _tabSelezionata == 0 ? oceanCyan : Colors.white54, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Ricorrenze',
                              style: TextStyle(
                                color: _tabSelezionata == 0 ? Colors.white : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabSelezionata = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tabSelezionata == 1 ? purpleZen.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tabSelezionata == 1 ? purpleZen : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_graph_rounded, color: _tabSelezionata == 1 ? purpleZen : Colors.white54, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Pilotaggio & Regole',
                              style: TextStyle(
                                color: _tabSelezionata == 1 ? Colors.white : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: _tabSelezionata == 0
                  ? _buildTabRicorrenze(walletProvider)
                  : _buildTabPilotaggioERegole(walletProvider),
            ),
          ],
        ),
      ),
    );
  }

 // ===========================================================================
  // TAB 1: 🔄 RICORRENZE (CON TOGGLE ATTIVE / STORICO PASSATE)
  // ===========================================================================
  Widget _buildTabRicorrenze(WalletProvider provider) {
    final bool isPro = provider.isProUser;

    final List<Map<String, dynamic>> tutteLeVoci = [];
    final Set<String> nomiProcessati = {};

    for (var v in provider.vociPianificate) {
      final String nome = (v['nome'] ?? 'Ricorrenza').toString().toLowerCase().trim();
      if (nome.isNotEmpty) nomiProcessati.add(nome);
      tutteLeVoci.add(Map<String, dynamic>.from(v));
    }

    final txsRicorrenti = provider.transactions.where((tx) => (tx.isRecurrent ?? false) == true).toList();
    for (var tx in txsRicorrenti) {
      final String nome = (tx.title ?? 'Ricorrenza').toString().toLowerCase().trim();
      if (!nomiProcessati.contains(nome)) {
        nomiProcessati.add(nome);

        int giornoAddebito = tx.date.day;
        if (tx.giornoRicorrenza != null) {
          giornoAddebito = int.tryParse(tx.giornoRicorrenza.toString()) ?? tx.date.day;
        }

        tutteLeVoci.add({
          'id': tx.id,
          'nome': tx.title,
          'previsto': tx.amount,
          'tipoMovimento': tx.isIncome ? 'entrata' : 'uscita',
          'sottocategoria': tx.category,
          'categoria': tx.category,
          'frequenza': tx.frequenza ?? 'Ogni mese',
          'giornoAddebito': giornoAddebito,
          'isTransaction': true,
          'dataFineRicorrenza': tx.dataFineRicorrenza?.toIso8601String(),
        });
      }
    }

    // 🎯 SEPARAZIONE REGOLE ATTIVE E TERMINATE/PASSATE
    final List<Map<String, dynamic>> vociAttive = [];
    final List<Map<String, dynamic>> vociTerminate = [];

    for (var voce in tutteLeVoci) {
      DateTime? dataFine;
      if (voce['dataFineRicorrenza'] != null) {
        dataFine = voce['dataFineRicorrenza'] is DateTime 
            ? voce['dataFineRicorrenza'] 
            : DateTime.tryParse(voce['dataFineRicorrenza'].toString());
      }
      final bool isTerminata = dataFine != null && dataFine.isBefore(DateTime.now());

      if (isTerminata) {
        vociTerminate.add(voce);
      } else {
        vociAttive.add(voce);
      }
    }

    final List<Map<String, dynamic>> listaDaMostrare = _subTabRicorrenze == 0 ? vociAttive : vociTerminate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 INTESTAZIONE CON PULSANTE TOGGLE STORICO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _subTabRicorrenze == 0 
                  ? 'REGOLE ATTIVE (${vociAttive.length})' 
                  : 'REGOLE PASSATE (${vociTerminate.length})',
              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            Row(
              children: [
                if (isPro && provider.vociArchiviate.isNotEmpty)
                  GestureDetector(
                    onTap: () => _mostraModalArchivio(context, provider),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Text('Archivio (${provider.vociArchiviate.length})', style: TextStyle(color: oceanCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                GestureDetector(
                  onTap: () => setState(() => _subTabRicorrenze = _subTabRicorrenze == 0 ? 1 : 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _subTabRicorrenze == 0 ? Icons.history_rounded : Icons.check_circle_outline_rounded,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _subTabRicorrenze == 0 ? 'Storico' : 'Attive',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 📋 LISTA FLUIDA DELLE REGOLE
        Expanded(
          child: listaDaMostrare.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      _subTabRicorrenze == 0 
                          ? 'Nessuna regola attiva al momento.'
                          : 'Nessuna regola passata nello storico.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: listaDaMostrare.length,
                  itemBuilder: (context, index) {
                    final voce = listaDaMostrare[index];
                    return _buildCardRicorrenza(context, provider, voce, isTerminata: _subTabRicorrenze == 1);
                  },
                ),
        ),

        const SizedBox(height: 12),

        // 🔘 UNICO ED ESCLUSIVO BOTTONE D'AZIONE IN BASSO
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: oceanCyan,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: Icon(isPro ? Icons.add_rounded : Icons.bolt_rounded, size: 18, color: Colors.black),
            label: Text(
              isPro ? 'Aggiungi Regola Ricorrente' : 'Sblocca Pianificazione Reale',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
            ),
            onPressed: () {
              if (!isPro) {
                _mostraModalPRO(context);
              } else {
                _mostraFormRegolaAvanzata(provider);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardRicorrenza(
    BuildContext context,
    WalletProvider provider,
    Map<String, dynamic> voce, {
    required bool isTerminata,
  }) {
    final bool isPro = provider.isProUser;
    final double importo = (voce['previsto'] as num).toDouble();
    final String nome = voce['nome'] ?? 'Regola Ricorrente';
    final String tipoMov = voce['tipoMovimento'] ?? 'uscita';
    final String cat = voce['sottocategoria'] ?? voce['categoria'] ?? 'Generale';
    final String freq = voce['frequenza'] ?? 'Ogni mese';
    final int giorno = voce['giornoAddebito'] ?? 1;

    DateTime? dataFine;
    if (voce['dataFineRicorrenza'] != null) {
      dataFine = voce['dataFineRicorrenza'] is DateTime 
          ? voce['dataFineRicorrenza'] 
          : DateTime.tryParse(voce['dataFineRicorrenza'].toString());
    }

    Color coloreIcona = oceanCyan;
    IconData iconaMov = Icons.sync_rounded;

    if (tipoMov == 'uscita') {
      coloreIcona = const Color(0xFFEF4444);
      iconaMov = Icons.arrow_downward_rounded;
    } else if (tipoMov == 'entrata') {
      coloreIcona = greenProfit;
      iconaMov = Icons.arrow_upward_rounded;
    } else if (tipoMov == 'giroconto') {
      coloreIcona = oceanCyan;
      iconaMov = Icons.swap_horiz_rounded;
    }

    return Dismissible(
      key: Key('dismiss_ricorrenza_${voce['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Gestisci',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (!isPro) {
          _mostraModalPRO(context);
          return false;
        }

        if (isTerminata) {
          _mostraGestioneTerminata(context, provider, voce);
        } else {
          _mostraGestioneEliminazioneRicorrenza(context, provider, voce);
        }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isTerminata ? Colors.white.withOpacity(0.01) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isTerminata ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.08)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (!isPro) {
                _mostraModalPRO(context);
                return;
              }

              if (isTerminata) {
                _mostraGestioneTerminata(context, provider, voce);
              } else {
                _mostraFormRegolaAvanzata(provider, voceEsistente: voce);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Opacity(
                opacity: isTerminata ? 0.45 : 1.0,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: coloreIcona.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconaMov, color: coloreIcona, size: 16),
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
                                  nome,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isTerminata)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    'Terminata ${dataFine != null ? "${dataFine.day.toString().padLeft(2, '0')}/${dataFine.month.toString().padLeft(2, '0')}" : ""}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPro ? greenProfit.withOpacity(0.15) : oceanCyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isPro ? greenProfit.withOpacity(0.3) : oceanCyan.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    isPro ? 'Attiva' : 'Simulata',
                                    style: TextStyle(color: isPro ? greenProfit : oceanCyan, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$cat • $freq (gg $giorno)',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tipoMov == 'uscita' ? '- ${_formattaValuta(importo)}' : '+ ${_formattaValuta(importo)}',
                      style: TextStyle(color: coloreIcona, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isPro ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                      color: isPro ? Colors.white24 : oceanCyan.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: 🎯 PILOTAGGIO STRATEGICO (HUMAN-IN-THE-LOOP + PLANCIA DI COMANDO)
  // ===========================================================================
  Widget _buildTabPilotaggioERegole(WalletProvider provider) {
    final bool isPro = provider.isProUser;
    final double targetAnnuoPivaLordo = provider.fatturatoStimato;

    // ⚡ RECUPERO MATRICE CENTRALIZZATA DAL PROVIDER
    final List<Map<String, dynamic>> matriceMesi = provider.calcolaMatriceProiezioneAnnuale();

    // 1. Dichiariamo prima i totali parziali della matrice
    final double totalePivaNettaAnnuo = matriceMesi.fold(0.0, (sum, m) => sum + (m['entrataPivaNetta'] as double));
    final double totaleStipendioAnnuo = matriceMesi.fold(0.0, (sum, m) => sum + (m['entrataStipendio'] as double));
    final double totaleSpeseAnnuo = matriceMesi.fold(0.0, (sum, m) => sum + (m['speseMese'] as double));

    // 2. Dichiariamo i totali derivati (esatti senza doppi conteggi)
    final double totaleNettoAnnuo = totalePivaNettaAnnuo + totaleStipendioAnnuo;
    final double totaleRisparmioAnnuo = totaleNettoAnnuo - totaleSpeseAnnuo;

    final double totaleGiaFissatoManualmenteLordo = provider.pilotaggioFatturatoMesi.values.fold(0.0, (sum, v) => sum + v) +
        provider.pilotaggioStipendioMesi.values.fold(0.0, (sum, v) => sum + v);

    final double totaleEntratePerBarra = (totalePivaNettaAnnuo + totaleStipendioAnnuo) > 0 ? (totalePivaNettaAnnuo + totaleStipendioAnnuo) : 1.0;
    final int flexPiva = ((totalePivaNettaAnnuo / totaleEntratePerBarra) * 100).round().clamp(1, 100);
    final int flexStipendio = (100 - flexPiva).clamp(0, 99);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📊 KPI HERO CARD MINIMALE: NETTO & RISPARMIO CON POPUP SU TAP SINGOLO
          GestureDetector(
            onTap: () => _mostraPopupDettaglioSintesi(
              context,
              provider,
              targetAnnuoPivaLordo,
              totalePivaNettaAnnuo,
              totaleStipendioAnnuo,
              totaleSpeseAnnuo,
              totaleNettoAnnuo,
              totaleRisparmioAnnuo,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NETTO REALE ANNUO', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formattaInt(totaleNettoAnnuo),
                            style: TextStyle(color: greenProfit, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: Colors.white10,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RISPARMIO ANNUO', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formattaInt(totaleRisparmioAnnuo),
                            style: TextStyle(
                              color: totaleRisparmioAnnuo >= 0 ? purpleZen : const Color(0xFFEF4444),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline_rounded, color: Colors.white38, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 🤖 SMART AI INSIGHT BANNER CON PULSANTE RESET
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: oceanCyan.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: oceanCyan.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_rounded, color: oceanCyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    totaleGiaFissatoManualmenteLordo > 0
                        ? 'I tuoi interventi manuali hanno la priorità. L\'AI ricalcola il residuo sui mesi liberi.'
                        : 'Algoritmo AI attivo: Ripartizione dinamica P.IVA sui mesi ON con tasse e stipendi calcolati.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    // Chiama il reset ufficiale sul Provider
                    provider.resetPilotaggio();
                    AppNotifications.mostraInAlto(context, 'Reset AI effettuato: Algoritmo ripristinato! 🎯');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: oceanCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: oceanCyan.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, color: oceanCyan, size: 12),
                        const SizedBox(width: 4),
                        Text('Reset AI', style: TextStyle(color: oceanCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text('PIANIFICAZIONE MESE PER MESE (NETTO (€))', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),

          // 🗓️ GRIGLIA 12 MESI INTERATTIVA CON BADGE E ANOMALIE
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.55,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final m = matriceMesi[index];
              final Color coloreStato = m['coloreStato'] as Color;
              final bool isCorrente = m['isCorrente'] as bool;
              final bool isPassato = m['isPassato'] as bool;
              final bool isMeseOFF = !(m['isMeseON'] as bool);
              final bool haAnomalia = m['haAnomalia'] as bool;
              final bool isManual = m['isManualOverride'] as bool;

              final Color coloreDot = isPassato ? Colors.grey : (isCorrente ? oceanCyan : coloreStato);

              return InkWell(
                onTap: () {
                  if (!isPro) {
                    _mostraModalPRO(context);
                  } else {
                    _mostraPlanciaComandoMese(context, provider, m);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrente 
                        ? oceanCyan.withOpacity(0.12) 
                        : (isMeseOFF ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrente 
                          ? oceanCyan 
                          : (isPassato ? greenProfit.withOpacity(0.4) : Colors.white10),
                      width: isCorrente ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: coloreDot, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(m['nomeMese'] as String, style: TextStyle(color: isCorrente ? oceanCyan : Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (haAnomalia)
                            Icon(Icons.warning_amber_rounded, color: goldAccent, size: 12)
                          else if (isMeseOFF)
                            const Text('🏖️', style: TextStyle(fontSize: 8))
                          else if (isManual)
                            Icon(Icons.edit_rounded, color: oceanCyan, size: 10)
                          else if (isPassato)
                            const Text('🔒', style: TextStyle(fontSize: 8))
                          else
                            Icon(Icons.auto_awesome_rounded, color: purpleZen, size: 10),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          _formattaInt(m['entrataTotaleNetta'] as double),
                          style: TextStyle(
                            color: isMeseOFF ? Colors.white24 : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isMeseOFF && provider.isPartitaIVA)
                        Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            '🏖️ da Cuscinetto',
                            style: TextStyle(color: purpleZen, fontSize: 8, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(height: 2),
                      // ✅ ORA LEGGE IL BILANCIO NETTO REALE DALLA MATRICE
                      FittedBox(
                        child: Text(
                          'Risparmio: ${_formattaInt((m['bilancioNetto'] as double? ?? 0.0) - (m['quotaCuscinetto'] as double? ?? 0.0))}',
                          style: TextStyle(
                            color: ((m['bilancioNetto'] as double? ?? 0.0) - (m['quotaCuscinetto'] as double? ?? 0.0)) >= 0 ? greenProfit : const Color(0xFFEF4444),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          const Text('PARAMETRIZZAZIONE BUSSOLA BUDGET', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),

          // 🎛️ REGOLATORE BUSSOLA 50/30/20
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSliderRegola('Spese Fisse (Bisogni)', provider.percentBisogni, oceanCyan, (val) {
                  if (isPro) provider.salvaRegolaBudget(val, provider.percentSvago, 100 - val - provider.percentSvago);
                  else _mostraModalPRO(context);
                }),
                const SizedBox(height: 10),
                _buildSliderRegola('Svago & Tempo Libero', provider.percentSvago, goldAccent, (val) {
                  if (isPro) provider.salvaRegolaBudget(provider.percentBisogni, val, 100 - provider.percentBisogni - val);
                  else _mostraModalPRO(context);
                }),
                const SizedBox(height: 10),
                _buildSliderRegola('Risparmi & Futuro', provider.percentRisparmio, purpleZen, (val) {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎛️ PLANCIA DI COMANDO DEL MESE (GRAFICA PULITA E UNIFORMATA)
  void _mostraPlanciaComandoMese(BuildContext context, WalletProvider provider, Map<String, dynamic> m) {
    final int meseIdx = m['meseIdx'] as int;
    final String nomeMese = m['nomeMese'] as String;
    final bool isPassato = m['isPassato'] as bool;
    final bool isMeseOFF = m['isMeseOFF'] as bool? ?? false;
    final bool isManualPiva = m['isManualOverride'] as bool;
    final bool isManualStipendio = provider.pilotaggioStipendioMesi.containsKey(meseIdx) && provider.pilotaggioStipendioMesi[meseIdx]! > 0;
    final bool haAnomalia = m['haAnomalia'] as bool;

    final double stipendioTarget = m['entrataStipendio'] as double? ?? 0.0;
    final double pivaLordaTarget = m['entrataPivaLorda'] as double? ?? 0.0;
    final double pivaNettaTarget = m['entrataPivaNetta'] as double? ?? 0.0;
    final double spesePianificateTotali = m['speseMese'] as double? ?? 0.0;
    final double quotaCuscinetto = m['quotaCuscinetto'] as double? ?? 0.0;

    final bool isCorrente = m['isCorrente'] as bool? ?? false;
    final int annoCorrente = DateTime.now().year;

    // 🎯 CALCOLO REALTIME PER IL MESE CORRENTE
    double stipendioReale = 0.0;
    double pivaLordaReale = 0.0;
    double speseRealiSostenute = 0.0;

    if (isCorrente) {
      stipendioReale = provider.transactions.where((tx) => tx.isIncome && tx.date.year == annoCorrente && tx.date.month == meseIdx && (tx.category == 'Stipendio' || tx.category == 'Pensione' || tx.title.toLowerCase().contains('stipendio'))).fold(0.0, (sum, tx) => sum + tx.amount);

      final lordoFatture = provider.fattureIncassate.where((f) {
        final dataStr = f['dataIncasso'] as String? ?? f['data'] as String? ?? '';
        return dataStr.contains('$annoCorrente') && (dataStr.contains('/$meseIdx/') || dataStr.contains('-0$meseIdx-') || dataStr.contains('-$meseIdx-'));
      }).fold(0.0, (sum, f) => sum + ((f['importo'] as num?)?.toDouble() ?? 0.0));

      final lordoTx = provider.transactions.where((tx) => tx.isIncome && tx.date.year == annoCorrente && tx.date.month == meseIdx && (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso'))).fold(0.0, (sum, tx) => sum + tx.amount);
      
      pivaLordaReale = lordoFatture > lordoTx ? lordoFatture : lordoTx;

      speseRealiSostenute = provider.transactions.where((tx) => !tx.isIncome && tx.date.year == annoCorrente && tx.date.month == meseIdx && tx.category != 'Giroconto' && !tx.title.toLowerCase().contains('giroconto')).fold(0.0, (sum, tx) => sum + tx.amount);
    }

    final double pivaNettaReale = pivaLordaReale * (1 - provider.aliquotaFiscaleReale);

    final double entratePureTarget = isMeseOFF ? stipendioTarget : (stipendioTarget + pivaNettaTarget);
    final double entratePureReali = isMeseOFF ? stipendioReale : (stipendioReale + pivaNettaReale);

    // 🛡️ ANTI-DUPLICAZIONE SPESE: Sostenute Reali + Pianificate Rimanenti
    final double spesePianificateRimanenti = (spesePianificateTotali - speseRealiSostenute).clamp(0.0, double.infinity);
    final double speseTotaliProiettateMese = isCorrente ? (speseRealiSostenute + spesePianificateRimanenti) : spesePianificateTotali;

    // Risparmio netto effettivo
    final double risparmioNettoMese = isMeseOFF
        ? ((isCorrente ? stipendioReale : stipendioTarget) + quotaCuscinetto - speseTotaliProiettateMese)
        : ((isCorrente ? entratePureReali : entratePureTarget) - quotaCuscinetto - speseTotaliProiettateMese);

    // 🔒 GESTIONE ESATTA DEL SEGNO PER EVITARE DOPPIO -
    final String strRisparmioNetto = risparmioNettoMese < 0
        ? '- ${_formattaInt(risparmioNettoMese.abs())}'
        : _formattaInt(risparmioNettoMese);

    final TextEditingController overridePivaCtrl = TextEditingController(
      text: pivaLordaTarget > 0 ? pivaLordaTarget.toStringAsFixed(0) : '',
    );

    final TextEditingController overrideStipendioCtrl = TextEditingController(
      text: stipendioTarget > 0 ? stipendioTarget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: isPassato ? Icons.history_rounded : Icons.tune_rounded,
        iconColor: oceanCyan,
        titolo: 'Plancia Mese: $nomeMese',
        testoAnnulla: '',
        testoConferma: isPassato ? null : 'Salva & Ricalcola AI',
        onConferma: isPassato ? null : () {
          final nuovoValoreLordoPiva = double.tryParse(overridePivaCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
          final nuovoValoreNettoStipendio = double.tryParse(overrideStipendioCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

          provider.impostaFatturatoMese(meseIdx, nuovoValoreLordoPiva);
          provider.impostaStipendioMese(meseIdx, nuovoValoreNettoStipendio);

          AppNotifications.mostraInAlto(context, 'Stime per $nomeMese aggiornate. Algoritmo ricalibrato! 🎯');
          Navigator.pop(ctx);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ BADGE ORIGINE DATO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPassato 
                    ? greenProfit.withOpacity(0.15) 
                    : ((isManualPiva || isManualStipendio) ? oceanCyan.withOpacity(0.15) : purpleZen.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPassato 
                    ? '🔒 Consolidato Reale' 
                    : ((isManualPiva || isManualStipendio) ? '✏️ Fissato da te (Override)' : '🤖 Pilotato da AI'),
                style: TextStyle(
                  color: isPassato ? greenProfit : ((isManualPiva || isManualStipendio) ? oceanCyan : purpleZen),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (haAnomalia) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: goldAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: goldAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: goldAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Suggerimento AI: L\'importo inserito è molto sotto la media necessaria per raggiungere il Target Annuo.',
                        style: TextStyle(color: goldAccent, fontSize: 10, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 💵 COMPOSIZIONE ENTRATE
            const Text('COMPOSIZIONE ENTRATE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 6),

            if (isCorrente) ...[
              // 🔴 BLOCCO REAL TIME & TARGET (MESE CORRENTE)
              if (provider.hasDipendente || provider.hasPensione || provider.entrataExtraMensile > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Stipendio / Pensione (Netto):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('${_formattaInt(stipendioReale)} / ${_formattaInt(stipendioTarget)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (provider.isPartitaIVA && !isMeseOFF) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fatturato P.IVA (Lordo):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('${_formattaInt(pivaLordaReale)} / ${_formattaInt(pivaLordaTarget)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fatturato P.IVA (Netto post-tasse):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('${_formattaInt(pivaNettaReale)} / ${_formattaInt(pivaNettaTarget)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: greenProfit.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: greenProfit.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTALE ENTRATE NETTE (Real / Target):', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(
                      '${_formattaInt(entratePureReali)} / ${_formattaInt(entratePureTarget)}',
                      style: TextStyle(color: greenProfit, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 🔮 BLOCCO PREVISIONE / CONSOLIDATO (MESI FUTURI O PASSATI)
              if (provider.hasDipendente || provider.hasPensione || provider.entrataExtraMensile > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Stipendio / Pensione (Netto):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(_formattaInt(stipendioTarget), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (provider.isPartitaIVA && !isMeseOFF) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fatturato P.IVA (Lordo):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(_formattaInt(pivaLordaTarget), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fatturato P.IVA (Netto post-tasse):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(_formattaInt(pivaNettaTarget), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: greenProfit.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: greenProfit.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTALE ENTRATE NETTE:', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      _formattaInt(entratePureTarget),
                      style: TextStyle(color: greenProfit, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            // 📉 BILANCIO & BUSSOLA BUDGET
            const Text('BILANCIO & BUSSOLA BUDGET', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 6),

            if (isCorrente) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Uscite Reali Sostenute:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('- ${_formattaInt(speseRealiSostenute.abs())}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Spese Pianificate Rimanenti:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('- ${_formattaInt(spesePianificateRimanenti.abs())}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Uscite / Spese Pianificate:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('- ${_formattaInt(spesePianificateTotali.abs())}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],

            // 🏖️ CUSCINETTO FERIE SOTTO IL BILANCIO
            if (provider.isPartitaIVA && provider.mesiAttivi < 12) ...[
              const SizedBox(height: 4),
              if (isMeseOFF) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Integrazione Cuscinetto Ferie:', style: TextStyle(color: purpleZen, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('+ ${_formattaInt(quotaCuscinetto.abs())}', style: TextStyle(color: purpleZen, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ] else if (quotaCuscinetto > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Accantonamento Cuscinetto Ferie:', style: TextStyle(color: purpleZen, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('- ${_formattaInt(quotaCuscinetto.abs())}', style: TextStyle(color: purpleZen, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 8),

            // 🛡️ RISPARMIO NETTO MESE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (risparmioNettoMese >= 0 ? greenProfit : const Color(0xFFEF4444)).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (risparmioNettoMese >= 0 ? greenProfit : const Color(0xFFEF4444)).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Risparmio Netto Mese:', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    strRisparmioNetto,
                    style: TextStyle(
                      color: risparmioNettoMese >= 0 ? greenProfit : const Color(0xFFEF4444),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            if (!isPassato) ...[
              if (provider.hasDipendente || provider.hasPensione || provider.entrataExtraMensile > 0) ...[
                const SizedBox(height: 14),
                Text('MODIFICA MANUALE STIPENDIO / PENSIONE (NETTO)', style: TextStyle(color: oceanCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: overrideStipendioCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixText: '€ Netti',
                    suffixStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
              if (provider.isPartitaIVA) ...[
                const SizedBox(height: 10),
                Text('MODIFICA MANUALE FATTURATO P.IVA (LORDO)', style: TextStyle(color: oceanCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: overridePivaCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixText: '€ Lordi',
                    suffixStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _mostraPopupDettaglioSintesi(
    BuildContext context,
    WalletProvider provider,
    double targetAnnuoPivaLordo,
    double totalePivaNettaAnnuo,
    double totaleStipendioAnnuo,
    double totaleSpeseAnnuo,
    double totaleNettoAnnuo,
    double totaleRisparmioAnnuo,
  ) {
    HapticFeedback.mediumImpact();

    final bool haStipendioOPensione = provider.hasDipendente || provider.hasPensione || provider.entrataExtraMensile > 0;
    final double targetStipendioNettoAnnuo = haStipendioOPensione
        ? (provider.entrataExtraMensile * (provider.hasDipendente ? 13 : 12))
        : 0.0;
    final double aliquotaTasse = provider.aliquotaFiscaleReale;
    final double stimaPivaLordaAnnuo = (aliquotaTasse < 1.0)
        ? (totalePivaNettaAnnuo / (1 - aliquotaTasse))
        : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: oceanCyan.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.analytics_rounded, color: oceanCyan, size: 28),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Dettaglio Sintesi Annuale',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // 🎯 TARGET ANNUALE (OBIETTIVI) - VALORI IN GRIGIO
              const Text(
                'TARGET ANNUALE (OBIETTIVI)',
                style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              if (provider.isPartitaIVA)
                _buildRigaDettaglioPopup('Target Fatturato P.IVA (Lordo):', _formattaInt(targetAnnuoPivaLordo), Colors.white70),
              if (haStipendioOPensione && targetStipendioNettoAnnuo > 0) ...[
                const SizedBox(height: 4),
                _buildRigaDettaglioPopup('Target Stipendio / Pensione (Netto):', _formattaInt(targetStipendioNettoAnnuo), Colors.white70),
              ],

              const SizedBox(height: 14),

              // 📈 PREVISIONE ANNUALE (PROIEZIONI) - VALORI IN VERDE E PURPLE
              const Text(
                'PREVISIONE ANNUALE (PROIEZIONI)',
                style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              if (provider.isPartitaIVA) ...[
                _buildRigaDettaglioPopup('Previsione P.IVA (Lordo):', _formattaInt(stimaPivaLordaAnnuo), greenProfit),
                const SizedBox(height: 4),
                _buildRigaDettaglioPopup('Previsione P.IVA (Netto):', _formattaInt(totalePivaNettaAnnuo), greenProfit),
                const SizedBox(height: 4),
              ],
              if (haStipendioOPensione && totaleStipendioAnnuo > 0) ...[
                _buildRigaDettaglioPopup('Previsione Stipendio / Pensione (Netto):', _formattaInt(totaleStipendioAnnuo), greenProfit),
                const SizedBox(height: 4),
              ],
              if (provider.isPartitaIVA && provider.mesiAttivi < 12) ...[
                _buildRigaDettaglioPopup(
                  'Fondo Cuscinetto Mesi OFF (${12 - provider.mesiAttivi} mesi):',
                  // ✅ CALCOLO ESATTO DEL FABBISOGNO ANNUO MASSIMO
                  '${_formattaInt((provider.nettoTargetMensile - provider.entrataExtraMensile).clamp(0.0, double.infinity) * (12 - provider.mesiAttivi))} (Bilanciato)',
                  purpleZen,
                ),
                const SizedBox(height: 4),
              ],

              const Divider(color: Colors.white10, height: 18),

              // 💰 SINTESI RISPARMIO E BILANCIO
              _buildRigaDettaglioPopup('TOTALE ENTRATE NETTE:', _formattaInt(totaleNettoAnnuo), greenProfit, isBold: true),
              const SizedBox(height: 6),
              _buildRigaDettaglioPopup('Uscite / Spese Pianificate:', '- ${_formattaInt(totaleSpeseAnnuo)}', const Color(0xFFEF4444)),
              const Divider(color: Colors.white10, height: 18),
              _buildRigaDettaglioPopup('RISPARMIO NETTO ANNUO:', _formattaInt(totaleRisparmioAnnuo), totaleRisparmioAnnuo >= 0 ? purpleZen : const Color(0xFFEF4444), isBold: true),

              const SizedBox(height: 20),

              // 🔘 BOTTONE "HO CAPITO" FULL-WIDTH
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Ho Capito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRigaDettaglioPopup(String etichetta, String valore, Color coloreValore, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etichetta,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white70,
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          valore,
          style: TextStyle(
            color: coloreValore,
            fontSize: isBold ? 13 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRegola(String etichetta, double valore, Color colore, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(etichetta, style: TextStyle(color: colore, fontSize: 11, fontWeight: FontWeight.bold)),
            Text('${valore.round()}%', style: TextStyle(color: colore, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: valore.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: colore,
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

void _mostraDialogNuovoPreferitoRegola(BuildContext context, Function(Map<String, dynamic>) onAggiunto) {
    final TextEditingController nameController = TextEditingController();
    IconData iconaNuova = Icons.shopping_bag_outlined;
    String categoriaNuova = 'Supermercato';
    String bussolaNuova = 'Bisogni (50%)';

    final List<IconData> icone = [
      Icons.shopping_bag_outlined, Icons.shopping_cart_outlined, Icons.home_outlined,
      Icons.bolt_outlined, Icons.restaurant_outlined, Icons.local_gas_station_outlined,
      Icons.fitness_center_outlined, Icons.pets_outlined, Icons.directions_bus_outlined,
      Icons.medical_services_outlined, Icons.subscriptions_outlined, Icons.wifi_rounded,
      Icons.flight_takeoff_rounded, Icons.build_outlined, Icons.work_outline,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppSecondaryPopup(
            backgroundColor: const Color(0xFF18181B),
            icon: Icons.add_circle_outline_rounded,
            iconColor: const Color(0xFF38BDF8),
            titolo: 'Crea Preferito Rapido',
            testoConferma: 'Aggiungi',
            onConferma: () {
              if (nameController.text.trim().isNotEmpty) {
                onAggiunto({
                  'nome': nameController.text.trim(),
                  'cat': categoriaNuova,
                  'bussola': bussolaNuova,
                  'icon': iconaNuova,
                });
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(context, 'Preferito aggiunto! ✨');
              }
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome Preferito (es. Palestra)',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryDropdown<String>(
                    label: 'Categoria Specifica',
                    accentColor: const Color(0xFF38BDF8),
                    selectedValue: categoriaNuova,
                    items: const [
                      AppDropdownItem(value: 'Supermercato', label: 'Supermercato', icon: Icons.shopping_cart_outlined),
                      AppDropdownItem(value: 'Casa/Affitto', label: 'Casa/Affitto', icon: Icons.home_outlined),
                      AppDropdownItem(value: 'Mutuo', label: 'Mutuo', icon: Icons.account_balance_outlined),
                      AppDropdownItem(value: 'Canoni/Bollette', label: 'Canoni/Bollette', icon: Icons.bolt_outlined),
                      AppDropdownItem(value: 'Ristoranti & Bar', label: 'Ristoranti & Bar', icon: Icons.restaurant_outlined),
                      AppDropdownItem(value: 'Divertimento & Hobby', label: 'Divertimento & Hobby', icon: Icons.sports_esports_outlined),
                      AppDropdownItem(value: 'Altro', label: 'Altro', icon: Icons.more_horiz_outlined),
                    ],
                    onSelect: (val) => setDialogState(() => categoriaNuova = val),
                  ),
                  const SizedBox(height: 10),
                  AppSecondaryDropdown<String>(
                    label: 'Bussola Spese',
                    accentColor: const Color(0xFF38BDF8),
                    selectedValue: bussolaNuova,
                    items: const [
                      AppDropdownItem(value: 'Bisogni (50%)', label: '50% Spese Fisse', icon: Icons.pie_chart_outline),
                      AppDropdownItem(value: 'Svago (30%)', label: '30% Svago', icon: Icons.attractions_outlined),
                      AppDropdownItem(value: 'Risparmio (20%)', label: '20% Risparmi', icon: Icons.savings_outlined),
                    ],
                    onSelect: (val) => setDialogState(() => bussolaNuova = val),
                  ),
                  const SizedBox(height: 14),
                  const Text('SCEGLI PITTOGRAMMA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: icone.map((icon) {
                      final isSelected = iconaNuova == icon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => iconaNuova = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostraGestionePreferitoRegolaModal(BuildContext context, Map<String, dynamic> pref, Function(Map<String, dynamic>?, bool) onConcluso) {
    final TextEditingController nameController = TextEditingController(text: pref['nome']);
    IconData iconaTemp = pref['icon'] as IconData;
    String catTemp = pref['cat'] ?? 'Supermercato';
    String bussolaTemp = pref['bussola'] ?? 'Bisogni (50%)';

    final List<IconData> icone = [
      Icons.shopping_bag_outlined, Icons.shopping_cart_outlined, Icons.home_outlined,
      Icons.bolt_outlined, Icons.restaurant_outlined, Icons.local_gas_station_outlined,
      Icons.fitness_center_outlined, Icons.pets_outlined, Icons.directions_bus_outlined,
      Icons.medical_services_outlined, Icons.subscriptions_outlined, Icons.wifi_rounded,
      Icons.flight_takeoff_rounded, Icons.build_outlined, Icons.work_outline,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppSecondaryPopup(
            backgroundColor: const Color(0xFF18181B),
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF38BDF8),
            titolo: 'Gestisci Preferito',
            testoAnnulla: 'Chiudi',
            testoConferma: 'Salva Modifiche',
            onConferma: () {
              if (nameController.text.trim().isNotEmpty) {
                onConcluso({
                  'nome': nameController.text.trim(),
                  'cat': catTemp,
                  'bussola': bussolaTemp,
                  'icon': iconaTemp,
                }, false);
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(context, 'Preferito aggiornato! ✨');
              }
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome Preferito',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryDropdown<String>(
                    label: 'Categoria Specifica',
                    accentColor: const Color(0xFF38BDF8),
                    selectedValue: catTemp,
                    items: const [
                      AppDropdownItem(value: 'Supermercato', label: 'Supermercato', icon: Icons.shopping_cart_outlined),
                      AppDropdownItem(value: 'Casa/Affitto', label: 'Casa/Affitto', icon: Icons.home_outlined),
                      AppDropdownItem(value: 'Mutuo', label: 'Mutuo', icon: Icons.account_balance_outlined),
                      AppDropdownItem(value: 'Canoni/Bollette', label: 'Canoni/Bollette', icon: Icons.bolt_outlined),
                      AppDropdownItem(value: 'Ristoranti & Bar', label: 'Ristoranti & Bar', icon: Icons.restaurant_outlined),
                      AppDropdownItem(value: 'Divertimento & Hobby', label: 'Divertimento & Hobby', icon: Icons.sports_esports_outlined),
                      AppDropdownItem(value: 'Altro', label: 'Altro', icon: Icons.more_horiz_outlined),
                    ],
                    onSelect: (val) => setDialogState(() => catTemp = val),
                  ),
                  const SizedBox(height: 10),
                  AppSecondaryDropdown<String>(
                    label: 'Bussola Spese',
                    accentColor: const Color(0xFF38BDF8),
                    selectedValue: bussolaTemp,
                    items: const [
                      AppDropdownItem(value: 'Bisogni (50%)', label: '50% Spese Fisse', icon: Icons.pie_chart_outline),
                      AppDropdownItem(value: 'Svago (30%)', label: '30% Svago', icon: Icons.attractions_outlined),
                      AppDropdownItem(value: 'Risparmio (20%)', label: '20% Risparmi', icon: Icons.savings_outlined),
                    ],
                    onSelect: (val) => setDialogState(() => bussolaTemp = val),
                  ),
                  const SizedBox(height: 14),
                  const Text('SCEGLI PITTOGRAMMA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: icone.map((icon) {
                      final isSelected = iconaTemp == icon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => iconaTemp = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 18),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Elimina Questo Preferito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () {
                        onConcluso(null, true);
                        Navigator.pop(ctx);
                        AppNotifications.mostraInAlto(context, 'Preferito eliminato', type: NotificationType.error);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }  

 void _mostraFormRegolaAvanzata(
    WalletProvider provider, {
    Map<String, dynamic>? voceEsistente,
    double? importoIniziale,
    String? nomeIniziale,
    bool isEntrata = false,
  }) {
    final bool isEdit = voceEsistente != null;

    String tipoMovimentoSel = isEdit
        ? (voceEsistente['tipoMovimento'] ?? (voceEsistente['isGiroconto'] == true ? 'giroconto' : (isEntrata ? 'entrata' : 'uscita')))
        : (isEntrata ? 'entrata' : 'uscita');

    final TextEditingController nomeCtrl = TextEditingController(
      text: isEdit ? voceEsistente['nome'] : (nomeIniziale ?? ''),
    );
    final TextEditingController importoCtrl = TextEditingController(
      text: isEdit
          ? (voceEsistente['previsto'] as num).toStringAsFixed(0)
          : (importoIniziale?.toStringAsFixed(0) ?? ''),
    );

    final listaConti = provider.accounts;
    String contoSel = isEdit
        ? (voceEsistente['accountId'] ?? (listaConti.isNotEmpty ? listaConti.first.id : 'main_account'))
        : (listaConti.isNotEmpty ? listaConti.first.id : 'main_account');

    String daContoSel = isEdit ? (voceEsistente['daAccountId'] ?? contoSel) : contoSel;
    String aContoSel = isEdit
        ? (voceEsistente['aAccountId'] ?? (listaConti.length > 1 ? listaConti[1].id : contoSel))
        : (listaConti.length > 1 ? listaConti[1].id : contoSel);

    String categoriaSel = isEdit ? (voceEsistente['sottocategoria'] ?? 'Supermercato') : 'Supermercato';
    String bussolaSel = isEdit ? (voceEsistente['categoria'] ?? 'Bisogni (50%)') : 'Bisogni (50%)';

    String frequenzaSel = isEdit ? (voceEsistente['frequenza'] ?? 'Ogni mese') : 'Ogni mese';
    int giornoAddebitoSel = isEdit ? (voceEsistente['giornoAddebito'] ?? 1) : 1;
    
    // 🎯 Controller per la digitazione diretta del giorno
    final TextEditingController giornoAddebitoCtrl = TextEditingController(
      text: giornoAddebitoSel.toString(),
    );

    DateTime dataInizioSel = isEdit && voceEsistente['dataInizio'] != null
        ? (voceEsistente['dataInizio'] is DateTime
            ? voceEsistente['dataInizio']
            : DateTime.tryParse(voceEsistente['dataInizio'].toString()) ?? DateTime.now())
        : DateTime.now();

    DateTime? dataFineSel = isEdit && voceEsistente['dataFineRicorrenza'] != null
        ? (voceEsistente['dataFineRicorrenza'] is DateTime
            ? voceEsistente['dataFineRicorrenza']
            : DateTime.tryParse(voceEsistente['dataFineRicorrenza'].toString()))
        : null;

    String termineRicorrenzaSel = dataFineSel != null
        ? 'Fino al ${dataFineSel.day.toString().padLeft(2, '0')}/${dataFineSel.month.toString().padLeft(2, '0')}/${dataFineSel.year}'
        : (isEdit ? (voceEsistente['termineRicorrenza'] ?? 'Senza fine (default)') : 'Senza fine (default)');

    final List<Map<String, dynamic>> preferitiRapidi = [
      {'nome': 'Supermercato', 'cat': 'Supermercato', 'bussola': 'Bisogni (50%)', 'icon': Icons.shopping_cart_outlined},
      {'nome': 'Affitto', 'cat': 'Casa/Affitto', 'bussola': 'Bisogni (50%)', 'icon': Icons.home_outlined},
      {'nome': 'Mutuo', 'cat': 'Mutuo', 'bussola': 'Bisogni (50%)', 'icon': Icons.account_balance_outlined},
      {'nome': 'Bollette', 'cat': 'Canoni/Bollette', 'bussola': 'Bisogni (50%)', 'icon': Icons.bolt_outlined},
      {'nome': 'Ristoranti', 'cat': 'Ristoranti & Bar', 'bussola': 'Svago (30%)', 'icon': Icons.restaurant_outlined},
    ];

    final List<AppDropdownItem<String>> opzioniCategorieItems = const [
      AppDropdownItem(value: 'Supermercato', label: 'Supermercato', icon: Icons.shopping_cart_outlined),
      AppDropdownItem(value: 'Casa/Affitto', label: 'Casa/Affitto', icon: Icons.home_outlined),
      AppDropdownItem(value: 'Mutuo', label: 'Mutuo', icon: Icons.account_balance_outlined),
      AppDropdownItem(value: 'Canoni/Bollette', label: 'Canoni/Bollette', icon: Icons.bolt_outlined),
      AppDropdownItem(value: 'Auto & Trasporti', label: 'Auto & Trasporti', icon: Icons.directions_car_outlined),
      AppDropdownItem(value: 'Salute & Benessere', label: 'Salute & Benessere', icon: Icons.favorite_outline),
      AppDropdownItem(value: 'Ristoranti & Bar', label: 'Ristoranti & Bar', icon: Icons.restaurant_outlined),
      AppDropdownItem(value: 'Divertimento & Hobby', label: 'Divertimento & Hobby', icon: Icons.sports_esports_outlined),
      AppDropdownItem(value: 'Acquisti & Shopping', label: 'Acquisti & Shopping', icon: Icons.shopping_bag_outlined),
      AppDropdownItem(value: 'Viaggi & Vacanze', label: 'Viaggi & Vacanze', icon: Icons.flight_outlined),
      AppDropdownItem(value: 'Stipendio', label: 'Stipendio', icon: Icons.payments_outlined),
      AppDropdownItem(value: 'Altro', label: 'Altro', icon: Icons.more_horiz_outlined),
    ];

    final List<AppDropdownItem<String>> opzioniBussolaItems = const [
      AppDropdownItem(value: 'Bisogni (50%)', label: '50% Spese Fisse', icon: Icons.pie_chart_outline),
      AppDropdownItem(value: 'Svago (30%)', label: '30% Svago', icon: Icons.attractions_outlined),
      AppDropdownItem(value: 'Risparmio (20%)', label: '20% Risparmi', icon: Icons.savings_outlined),
    ];

    final List<String> opzioniFrequenza = [
      'Ogni settimana',
      'Ogni mese',
      'Ogni 2 mesi',
      'Trimestrale (3 mesi)',
      'Semestrale (6 mesi)',
      'Annuale',
    ];

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.sync_rounded,
      iconColor: oceanCyan,
      titolo: isEdit ? 'Modifica Regola Ricorrente' : 'Nuova Regola Ricorrente',
      testoConferma: 'Salva Regola',
      onConferma: () {
        final nome = nomeCtrl.text.trim();
        final importo = double.tryParse(importoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
        final giornoDigitato = int.tryParse(giornoAddebitoCtrl.text) ?? 1;

        if ((tipoMovimentoSel != 'giroconto' && nome.isEmpty) || importo <= 0) {
          AppNotifications.mostraInAlto(context, 'Inserisci un nome e un importo valido', type: NotificationType.warning);
          return;
        }

        final dati = {
          'id': isEdit ? voceEsistente['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
          'tipoMovimento': tipoMovimentoSel,
          'nome': tipoMovimentoSel == 'giroconto' ? 'Giroconto Ricorrente' : nome,
          'previsto': importo,
          'accountId': contoSel,
          'daAccountId': daContoSel,
          'aAccountId': aContoSel,
          'sottocategoria': categoriaSel,
          'categoria': bussolaSel,
          'frequenza': frequenzaSel,
          'giornoAddebito': giornoDigitato.clamp(1, 31),
          'dataInizio': dataInizioSel.toIso8601String(),
          'dataFineRicorrenza': dataFineSel?.toIso8601String(),
          'termineRicorrenza': termineRicorrenzaSel,
          'tipo': 'mensile',
          'isArchived': false,
        };

        if (isEdit) {
          // Se stiamo modificando una regola esistente
          provider.deleteTransaction(voceEsistente['id'].toString());
        }

        // Salva direttamente nel registro centrale delle transazioni
        provider.addTransaction(
          title: tipoMovimentoSel == 'giroconto' ? 'Giroconto Ricorrente' : nome,
          amount: importo,
          isIncome: tipoMovimentoSel == 'entrata',
          category: categoriaSel,
          accountId: contoSel,
          date: dataInizioSel,
          isRecurrent: true,
          frequenza: frequenzaSel,
          giornoRicorrenza: giornoDigitato.clamp(1, 31).toString(),
          dataInizio: dataInizioSel,
          dataFineRicorrenza: dataFineSel,
        );

        Navigator.pop(context);
        AppNotifications.mostraInAlto(context, 'Regola ricorrente salvata con successo! 🔄');
      },
      child: StatefulBuilder(
        builder: (context, setPopupState) {
          final List<AppDropdownItem<String>> opzioniTermine = [
            const AppDropdownItem(value: 'Senza fine (default)', label: 'Senza fine (default)', icon: Icons.all_inclusive_rounded),
            const AppDropdownItem(value: '1 anno', label: '1 Anno (12 rate)', icon: Icons.event_repeat_rounded),
            const AppDropdownItem(value: '2 anni', label: '2 Anni (24 rate)', icon: Icons.event_repeat_rounded),
            if (termineRicorrenzaSel.startsWith('Fino al '))
              AppDropdownItem(value: termineRicorrenzaSel, label: termineRicorrenzaSel, icon: Icons.calendar_today_rounded),
            const AppDropdownItem(value: 'data_custom', label: '📅 Data specifica...', icon: Icons.edit_calendar_rounded),
          ];

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔘 SELETTORE TAB MOVIMENTO
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setPopupState(() => tipoMovimentoSel = 'uscita'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tipoMovimentoSel == 'uscita' ? const Color(0xFFEF4444).withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tipoMovimentoSel == 'uscita' ? const Color(0xFFEF4444) : Colors.transparent),
                            ),
                            child: const Center(
                              child: Text('Uscita', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setPopupState(() => tipoMovimentoSel = 'entrata'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tipoMovimentoSel == 'entrata' ? greenProfit.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tipoMovimentoSel == 'entrata' ? greenProfit : Colors.transparent),
                            ),
                            child: const Center(
                              child: Text('Entrata', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setPopupState(() => tipoMovimentoSel = 'giroconto'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tipoMovimentoSel == 'giroconto' ? oceanCyan.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tipoMovimentoSel == 'giroconto' ? oceanCyan : Colors.transparent),
                            ),
                            child: const Center(
                              child: Text('Giroconto', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 🚀 PREFERITI RAPIDI CHIPS (CON PULSANTE + E GESTIONE)
                if (tipoMovimentoSel != 'giroconto') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PREFERITI RAPIDI', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const Text('Tieni premuto per gestire/modificare', style: TextStyle(color: Colors.white38, fontSize: 8, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: preferitiRapidi.length + 1,
                      itemBuilder: (context, index) {
                        // 🟢 TASTO + PER NUOVO PREFERITO
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: InkWell(
                              onTap: () {
                                _mostraDialogNuovoPreferitoRegola(context, (nuovoPref) {
                                  setPopupState(() {
                                    preferitiRapidi.add(nuovoPref);
                                    nomeCtrl.text = nuovoPref['nome'];
                                    categoriaSel = nuovoPref['cat'];
                                    bussolaSel = nuovoPref['bussola'];
                                  });
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: oceanCyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: oceanCyan.withOpacity(0.4)),
                                ),
                                child: Icon(Icons.add, size: 16, color: oceanCyan),
                              ),
                            ),
                          );
                        }

                        final item = preferitiRapidi[index - 1];
                        final bool isSelected = nomeCtrl.text == item['nome'];

                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: GestureDetector(
                            onLongPress: () {
                              _mostraGestionePreferitoRegolaModal(context, item, (modificato, eliminato) {
                                setPopupState(() {
                                  if (eliminato) {
                                    preferitiRapidi.removeAt(index - 1);
                                  } else if (modificato != null) {
                                    preferitiRapidi[index - 1] = modificato;
                                  }
                                });
                              });
                            },
                            child: FilterChip(
                              showCheckmark: false,
                              selected: isSelected,
                              avatar: Icon(item['icon'] as IconData, size: 14, color: isSelected ? Colors.white : oceanCyan),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['nome'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_outlined, size: 10, color: isSelected ? Colors.white60 : Colors.white24),
                                ],
                              ),
                              backgroundColor: Colors.black.withOpacity(0.35),
                              selectedColor: oceanCyan.withOpacity(0.4),
                              side: BorderSide(color: isSelected ? oceanCyan : Colors.white.withOpacity(0.1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (_) {
                                setPopupState(() {
                                  nomeCtrl.text = item['nome'];
                                  categoriaSel = item['cat'];
                                  bussolaSel = item['bussola'];
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 📌 CAMPI GIROCONTO
                if (tipoMovimentoSel == 'giroconto') ...[
                  AppSecondaryDropdown<String>(
                    label: 'Da Conto (Addebito)',
                    accentColor: oceanCyan,
                    selectedValue: daContoSel,
                    items: listaConti.map((c) => AppDropdownItem(value: c.id, label: c.title, icon: Icons.account_balance_wallet_outlined)).toList(),
                    onSelect: (val) => setPopupState(() => daContoSel = val),
                  ),
                  const SizedBox(height: 10),
                  AppSecondaryDropdown<String>(
                    label: 'A Conto (Accredito)',
                    accentColor: oceanCyan,
                    selectedValue: aContoSel,
                    items: listaConti.map((c) => AppDropdownItem(value: c.id, label: c.title, icon: Icons.account_balance_wallet_outlined)).toList(),
                    onSelect: (val) => setPopupState(() => aContoSel = val),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: importoCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Importo Trasferimento (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixText: '€',
                      prefixIcon: const Icon(Icons.sync_alt_rounded, color: Colors.white38, size: 18),
                    ),
                  ),
                ] else ...[
                  // 📌 CAMPI USCITA / ENTRATA
                  TextField(
                    controller: nomeCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Nome Regola / Descrizione',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.white38, size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: importoCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Importo (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixText: '€',
                      prefixIcon: Icon(
                        tipoMovimentoSel == 'uscita' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: tipoMovimentoSel == 'uscita' ? const Color(0xFFEF4444) : greenProfit,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppSecondaryDropdown<String>(
                    label: 'Conto',
                    accentColor: oceanCyan,
                    selectedValue: contoSel,
                    items: listaConti.map((c) => AppDropdownItem(value: c.id, label: c.title, icon: Icons.account_balance_wallet_outlined)).toList(),
                    onSelect: (val) => setPopupState(() => contoSel = val),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryDropdown<String>(
                          label: 'Categoria Specifica',
                          accentColor: oceanCyan,
                          selectedValue: opzioniCategorieItems.any((i) => i.value == categoriaSel) ? categoriaSel : opzioniCategorieItems.first.value,
                          items: opzioniCategorieItems,
                          onSelect: (val) => setPopupState(() => categoriaSel = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppSecondaryDropdown<String>(
                          label: 'Bussola Spese',
                          accentColor: oceanCyan,
                          selectedValue: opzioniBussolaItems.any((i) => i.value == bussolaSel) ? bussolaSel : opzioniBussolaItems.first.value,
                          items: opzioniBussolaItems,
                          onSelect: (val) => setPopupState(() => bussolaSel = val),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // 🛡️ IMPOSTAZIONI RICORRENZA CON DATA INIZIO
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: oceanCyan.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sync_rounded, color: oceanCyan, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'IMPOSTAZIONI RICORRENZA',
                            style: TextStyle(color: oceanCyan, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // 📅 RIGA 1: DATA INIZIO & FREQUENZA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DATA INIZIO',
                                  style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await AppDatePicker.selezionaData(
                                      context,
                                      dataIniziale: dataInizioSel,
                                    );
                                    if (picked != null) {
                                      setPopupState(() {
                                        dataInizioSel = picked;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_month_rounded, color: oceanCyan, size: 15),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${dataInizioSel.day.toString().padLeft(2, '0')}/${dataInizioSel.month.toString().padLeft(2, '0')}/${dataInizioSel.year}',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppSecondaryDropdown<String>(
                              label: 'Frequenza',
                              accentColor: oceanCyan,
                              selectedValue: opzioniFrequenza.contains(frequenzaSel) ? frequenzaSel : opzioniFrequenza[1],
                              items: opzioniFrequenza.map((f) => AppDropdownItem(value: f, label: f, icon: Icons.repeat_rounded)).toList(),
                              onSelect: (val) => setPopupState(() => frequenzaSel = val),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 📅 RIGA 2: GIORNO ADDEBITO & TERMINE RICORRENZA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GIORNO ADDEBITO',
                                  style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
                                  ),
                                  child: TextField(
                                    controller: giornoAddebitoCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2),
                                    ],
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '1',
                                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                      prefixIcon: Icon(Icons.calendar_today_rounded, color: oceanCyan, size: 15),
                                      prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 0),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppSecondaryDropdown<String>(
                              label: 'Termine Ricorrenza',
                              accentColor: oceanCyan,
                              selectedValue: opzioniTermine.any((item) => item.value == termineRicorrenzaSel) ? termineRicorrenzaSel : opzioniTermine.first.value,
                              items: opzioniTermine,
                              onSelect: (val) async {
                                if (val == 'data_custom') {
                                  final picked = await AppDatePicker.selezionaData(
                                    context,
                                    dataIniziale: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    final dataFormatted = 'Fino al ${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                    setPopupState(() {
                                      dataFineSel = picked;
                                      termineRicorrenzaSel = dataFormatted;
                                    });
                                  }
                                } else {
                                  setPopupState(() {
                                    if (val == '1 anno') {
                                      dataFineSel = DateTime.now().add(const Duration(days: 365));
                                    } else if (val == '2 anni') {
                                      dataFineSel = DateTime.now().add(const Duration(days: 730));
                                    } else {
                                      dataFineSel = null;
                                    }
                                    termineRicorrenzaSel = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isEdit) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        foregroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.event_busy_rounded, size: 16),
                      label: const Text('Opzioni Eliminazione / Interruzione', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () {
                        Navigator.pop(context);
                        _mostraGestioneEliminazioneRicorrenza(context, provider, voceEsistente);
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  void _mostraAlertEliminazioneTotale(BuildContext context, WalletProvider provider, String id, String nome) {
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
          'Sei sicuro di voler eliminare TUTTI i movimenti di "$nome"?\n\n🚨 Verrà cancellato anche lo STORICO PASSATO e i saldi dei conti verranno riaccreditati. L\'operazione è irreversibile.',
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
              provider.rimuoviSpesaPianificata(id);
              provider.deleteTransaction(id);
              Navigator.pop(ctxAlert);
              AppNotifications.mostraInAlto(
                context,
                'Intera serie di "$nome" eliminata e saldi riaccreditati!',
                type: NotificationType.error,
              );
            },
            child: const Text('SÌ, ELIMINA TUTTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _mostraDialogModificaMese(WalletProvider provider, int meseIdx, String nomeMese, double stimaCorrente) {
    final TextEditingController importoCtrl = TextEditingController(text: stimaCorrente > 0 ? stimaCorrente.toStringAsFixed(0) : '');

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.edit_calendar_rounded,
      iconColor: oceanCyan,
      titolo: 'Previsione $nomeMese',
      testoConferma: 'Salva Previsione',
      onConferma: () {
        final nuovoImporto = double.tryParse(importoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
        provider.impostaFatturatoMese(meseIdx, nuovoImporto);
        Navigator.pop(context);
        AppNotifications.mostraInAlto(context, 'Previsione $nomeMese aggiornata a ${_formattaInt(nuovoImporto)}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inserisci il fatturato P.IVA stimato per $nomeMese:', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 10),
          TextField(
            controller: importoCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Importo Stima (€)',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixText: '€',
            ),
          ),
        ],
      ),
    );
  }
  void _mostraGestioneTerminata(
    BuildContext context,
    WalletProvider provider,
    Map<String, dynamic> voce,
  ) {
    if (voce.isEmpty) return;
    final String id = voce['id'].toString();
    final String nome = voce['nome'] ?? 'Ricorrenza';

    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.history_toggle_off_rounded,
        iconColor: Colors.white54,
        titolo: 'Ricorrenza Conclusa',
        testoAnnulla: 'Chiudi',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La spesa "$nome" risulta già terminata nel passato. Cosa desideri fare?',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // 1️⃣ DUPLICA / RIATTIVA
              AppActionCard(
                icon: Icons.control_point_duplicate_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Duplica / Riattiva regola',
                subtitle: 'Crea una nuova regola attiva riutilizzando nome, importo e categoria di questa spesa.',
                onTap: () {
                  Navigator.pop(ctx);
                  _mostraFormRegolaAvanzata(provider, importoIniziale: (voce['previsto'] as num?)?.toDouble(), nomeIniziale: nome);
                },
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 12),

              // 2️⃣ ELIMINA DEFINITIVAMENTE
              AppActionCard(
                icon: Icons.delete_forever_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Elimina definitivamente dallo storico',
                subtitle: 'Rimuove del tutto la traccia di questa regola terminata. Irreversibile.',
                isDanger: true,
                onTap: () {
                  provider.deleteTransaction(id);
                  provider.rimuoviSpesaPianificata(id);
                  Navigator.pop(ctx);
                  AppNotifications.mostraInAlto(
                    context,
                    'Regola "$nome" eliminata definitivamente dallo storico',
                    type: NotificationType.error,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _mostraGestioneEliminazioneRicorrenza(
    BuildContext context,
    WalletProvider provider,
    Map<String, dynamic> voce,
  ) {
    if (voce.isEmpty) return;

    // 🔒 SE L'UTENTE NON È PRO, APRE IL PAYWALL E CHIUDE IL DIALOG
    if (!provider.isProUser) {
      _mostraModalPRO(context);
      return;
    }

    final String id = voce['id'].toString();
    final String nome = voce['nome'] ?? 'Ricorrenza';
    final bool isTransaction = voce['isTransaction'] == true;

    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.event_repeat_rounded,
        iconColor: const Color(0xFF38BDF8),
        titolo: 'Gestisci Ricorrenza',
        testoAnnulla: 'Chiudi',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scegli come modificare la regola per "$nome":',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // 1️⃣ POPUP CUSTOM SOLO MESI CON INDICAZIONE VISIVA DI PRESENZA SPESA
              AppActionCard(
                icon: Icons.calendar_view_month_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Scegli ultimo mese di validità...',
                subtitle: 'Seleziona solo il mese: la regola si fermerà dal mese successivo.',
                onTap: () {
                  int annoSelezionato = DateTime.now().year;

                  // Recupera le date di inizio e fine dell'evento
                  DateTime? inizio;
                  if (voce['dataInizio'] != null) {
                    inizio = voce['dataInizio'] is DateTime
                        ? voce['dataInizio']
                        : DateTime.tryParse(voce['dataInizio'].toString());
                  }

                  DateTime? fine;
                  if (voce['dataFineRicorrenza'] != null) {
                    fine = voce['dataFineRicorrenza'] is DateTime
                        ? voce['dataFineRicorrenza']
                        : DateTime.tryParse(voce['dataFineRicorrenza'].toString());
                  }

                  showDialog(
                    context: context,
                    builder: (dialogCtx) => StatefulBuilder(
                      builder: (context, setPickerState) => AlertDialog(
                        backgroundColor: const Color(0xFF18181B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ultimo Mese Attivo', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF38BDF8)),
                                  onPressed: () => setPickerState(() => annoSelezionato--),
                                ),
                                Text('$annoSelezionato', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF38BDF8)),
                                  onPressed: () => setPickerState(() => annoSelezionato++),
                                ),
                              ],
                            ),
                          ],
                        ),
                        content: SizedBox(
                          width: 300,
                          child: GridView.builder(
                            shrinkWrap: true,
                            itemCount: 12,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (context, index) {
                              final meseIdx = index + 1;
                              final nomeMese = _nomiMesiBrevi[index];

                              final primoGiornoMese = DateTime(annoSelezionato, meseIdx, 1);
                              final ultimoGiornoMese = DateTime(annoSelezionato, meseIdx + 1, 0);

                              // 🔍 VERIFICA SE LA SPESA È ATTIVA E CADE IN QUESTO MESE IN BASE ALLA FREQUENZA
                              bool isSpesaPresente = true;
                              if (inizio != null) {
                                final startMese = DateTime(inizio.year, inizio.month, 1);
                                if (primoGiornoMese.isBefore(startMese)) {
                                  isSpesaPresente = false;
                                } else {
                                  final diffMesi = (annoSelezionato - inizio.year) * 12 + (meseIdx - inizio.month);
                                  final freqStr = (voce['frequenza'] ?? 'Ogni mese').toString().toLowerCase();

                                  if (freqStr.contains('2 mesi') && diffMesi % 2 != 0) {
                                    isSpesaPresente = false;
                                  } else if (freqStr.contains('trimestrale') && diffMesi % 3 != 0) {
                                    isSpesaPresente = false;
                                  } else if (freqStr.contains('semestrale') && diffMesi % 6 != 0) {
                                    isSpesaPresente = false;
                                  } else if (freqStr.contains('annuale') && diffMesi % 12 != 0) {
                                    isSpesaPresente = false;
                                  }
                                }
                              }
                              if (fine != null && ultimoGiornoMese.isAfter(fine)) {
                                isSpesaPresente = false;
                              }

                              return InkWell(
                                onTap: () {
                                  final limiteData = DateTime(annoSelezionato, meseIdx + 1, 0, 23, 59, 59);

                                  // 🛡️ CHECK 1: SE IL MESE È ANTECEDENTE ALL'INIZIO -> ELIMINAZIONE TOTALE
                                  if (inizio != null && limiteData.isBefore(DateTime(inizio.year, inizio.month, 1))) {
                                    Navigator.pop(dialogCtx);
                                    Navigator.pop(ctx);
                                    _mostraAlertEliminazioneTotale(context, provider, id, nome);
                                    return;
                                  }

                                  // 🛡️ CHECK 2: TERMINE SU MESI GIÀ CONTABILIZZATI O ANTECEDENTI A OGGI
                                  final now = DateTime.now();
                                  final bool tagliaStoricoGiaPagato = limiteData.isBefore(now);

                                  if (tagliaStoricoGiaPagato) {
                                    Navigator.pop(dialogCtx);
                                    showDialog(
                                      context: context,
                                      builder: (ctxTaglio) => AlertDialog(
                                        backgroundColor: const Color(0xFF18181B),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: const Row(
                                          children: [
                                            Icon(Icons.history_rounded, color: Color(0xFFF59E0B), size: 22),
                                            SizedBox(width: 8),
                                            Text('Storno Movimenti Passati', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        content: Text(
                                          'Impostando la fine a $nomeMese $annoSelezionato, i pagamenti registrati dopo questa data verranno cancellati e i relativi soldi saranno RIACCREDITATI sul tuo conto.\n\nVuoi procedere?',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctxTaglio),
                                            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFF59E0B),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              // 🎯 Chiamata unica al Provider per aggiornare la data di fine e ricalcolare i saldi
                                              provider.stopRecurrenceFromDate(id, limiteData);
                                              
                                              Navigator.pop(ctxTaglio);
                                              Navigator.pop(ctx);
                                              AppNotifications.mostraInAlto(
                                                context,
                                                'Regola "$nome" fermata a $nomeMese $annoSelezionato. Saldi e storico aggiornati!',
                                                type: NotificationType.warning,
                                              );
                                            },
                                            child: const Text('SÌ, STORNA E FERMA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    provider.stopRecurrenceFromDate(id, limiteData);
                                    Navigator.pop(dialogCtx);
                                    Navigator.pop(ctx);
                                    AppNotifications.mostraInAlto(
                                      context,
                                      'Regola "$nome" valida fino a $nomeMese $annoSelezionato!',
                                      type: NotificationType.warning,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSpesaPresente 
                                        ? const Color(0xFF38BDF8).withOpacity(0.2) 
                                        : Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSpesaPresente 
                                          ? const Color(0xFF38BDF8) 
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isSpesaPresente) ...[
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 10),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        nomeMese,
                                        style: TextStyle(
                                          color: isSpesaPresente ? Colors.white : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: isSpesaPresente ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 14),

              AppActionCard(
                icon: Icons.delete_forever_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Elimina l\'intera serie',
                subtitle: 'Cancella definitivamente la regola e lo storico passato. Irreversibile.',
                isDanger: true,
                onTap: () {
                  provider.rimuoviSpesaPianificata(id);
                  provider.deleteTransaction(id);
                  Navigator.pop(ctx);
                  AppNotifications.mostraInAlto(
                    context,
                    'Intera serie di "$nome" eliminata!',
                    type: NotificationType.error,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _mostraModalArchivio(BuildContext context, WalletProvider provider) {
    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.inventory_2_outlined,
      iconColor: goldAccent,
      titolo: 'Archivio Ricorrenze',
      testoAnnulla: 'Chiudi',
      child: Consumer<WalletProvider>(
        builder: (context, prov, _) {
          final archiviate = prov.vociArchiviate;
          if (archiviate.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Nessuna regola salvata in archivio.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: archiviate.map((item) {
              final String id = item['id'].toString();
              final String nome = item['nome'] ?? 'Ricorrenza';
              final double importo = (item['previsto'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, color: goldAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nome, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(_formattaValuta(importo), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oceanCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.restore_rounded, size: 14),
                      label: const Text('Ripristina', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        prov.ripristinaRicorrenzaArchiviata(id);
                        AppNotifications.mostraInAlto(context, 'Regola "$nome" ripristinata dall\'archivio! 🎉');
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 18),
                      onPressed: () {
                        prov.deleteTransaction(id);
                        AppNotifications.mostraInAlto(context, 'Regola eliminata definitivamente', type: NotificationType.error);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}