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

class PianoSpesaSheet extends StatefulWidget {
  const PianoSpesaSheet({super.key});

  @override
  State<PianoSpesaSheet> createState() => _PianoSpesaSheetState();
}

class _PianoSpesaSheetState extends State<PianoSpesaSheet> {
  int _tabSelezionata = 0; // 0 = 🔄 Ricorrenze, 1 = 🎯 Pilotaggio & Regole

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

  void _mostraModalPRO(BuildContext context) {
    AppBottomSheet.mostra(
      context: context,
      child: const ProUpgradeSheet(funzionalita: 'pianificazione'),
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
          maxHeight: screenHeight * 0.55,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isPro)
              GestureDetector(
                onTap: () => _mostraModalPRO(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: goldAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, color: goldAccent, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anteprima Demo PRO • Tocca per attivare con i tuoi dati reali',
                          style: TextStyle(color: goldAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: goldAccent, size: 16),
                    ],
                  ),
                ),
              ),

            // 🔘 SELETTORE TAB
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

            const SizedBox(height: 16),

            Expanded(
              child: _tabSelezionata == 0
                  ? _buildTabRicorrenze(walletProvider)
                  : _buildTabPilotaggioERegole(walletProvider),
            ),

            if (!isPro) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenProfit,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text(
                    'Passa a PRO per la Pianificazione Reale',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => _mostraModalPRO(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: 🔄 RICORRENZE E CONTRATTI
  // ===========================================================================
  Widget _buildTabRicorrenze(WalletProvider provider) {
    final bool isPro = provider.isProUser;

    // 🎯 Unifichiamo le regole pianificate e i movimenti ricorrenti da 2.1
    final List<Map<String, dynamic>> vociPianificate = [];
    final Set<String> nomiProcessati = {};

    // 1. Regole da provider.vociPianificate
    for (var v in provider.vociPianificate) {
      final String nome = (v['nome'] ?? 'Ricorrenza').toString().toLowerCase().trim();
      if (nome.isNotEmpty) nomiProcessati.add(nome);
      vociPianificate.add(Map<String, dynamic>.from(v));
    }

    // 2. Movimenti ricorrenti reali da provider.transactions (inseriti da 2.1)
    final txsRicorrenti = provider.transactions.where((tx) => (tx.isRecurrent ?? false) == true).toList();
    for (var tx in txsRicorrenti) {
      final String nome = (tx.title ?? 'Ricorrenza').toString().toLowerCase().trim();
      if (!nomiProcessati.contains(nome)) {
        nomiProcessati.add(nome);

        int giornoAddebito = tx.date.day;
        if (tx.giornoRicorrenza != null) {
          giornoAddebito = int.tryParse(tx.giornoRicorrenza.toString()) ?? tx.date.day;
        }

        vociPianificate.add({
          'id': tx.id,
          'nome': tx.title,
          'previsto': tx.amount,
          'tipoMovimento': tx.isIncome ? 'entrata' : 'uscita',
          'sottocategoria': tx.category,
          'categoria': tx.category,
          'frequenza': tx.frequenza ?? 'Ogni mese',
          'giornoAddebito': giornoAddebito,
          'isTransaction': true,
          'dataFineRicorrenza': tx.dataFineRicorrenza?.toIso8601String(), // 👈 Aggiunto per tracciare la scadenza!
        });
      }
    }

    final double stipendioOnboarding = provider.entrataExtraMensile;
    final String etichettaLavoro = provider.hasDipendente ? 'Stipendio' : 'Pensione';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stipendioOnboarding > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: greenProfit.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: greenProfit.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: greenProfit, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Da Onboarding: $etichettaLavoro', style: TextStyle(color: greenProfit, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('${_formattaInt(stipendioOnboarding)} / mese previsti', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenProfit,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    if (!isPro) {
                      _mostraModalPRO(context);
                    } else {
                      _mostraFormRegolaAvanzata(provider, importoIniziale: stipendioOnboarding, nomeIniziale: etichettaLavoro, isEntrata: true);
                    }
                  },
                  child: const Text('Configura', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isPro ? 'REGOLE ATTIVE E STORICO PASSATO' : 'ESEMPIO REGOLE RICORRENTI',
              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            Row(
              children: [
                if (isPro && provider.vociArchiviate.isNotEmpty)
                  InkWell(
                    onTap: () => _mostraModalArchivio(context, provider),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: goldAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: goldAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: goldAccent, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Archivio (${provider.vociArchiviate.length})',
                            style: TextStyle(color: goldAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    if (!isPro) {
                      _mostraModalPRO(context);
                    } else {
                      _mostraFormRegolaAvanzata(provider);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: oceanCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: oceanCyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: oceanCyan, size: 14),
                        const SizedBox(width: 4),
                        Text('Nuova Regola', style: TextStyle(color: oceanCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        Expanded(
          child: vociPianificate.isEmpty
              ? Center(
                  child: Text(
                    'Nessuna spesa, entrata o giroconto pianificato.\nPremi "+ Nuova Regola" per iniziare.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: vociPianificate.length,
                  itemBuilder: (context, index) {
                    final voce = vociPianificate[index];
                    final double importo = (voce['previsto'] as num).toDouble();
                    final String nome = voce['nome'] ?? 'Regola Ricorrente';
                    final String tipoMov = voce['tipoMovimento'] ?? 'uscita';
                    final String cat = voce['sottocategoria'] ?? voce['categoria'] ?? 'Generale';
                    final String freq = voce['frequenza'] ?? 'Ogni mese';
                    final int giorno = voce['giornoAddebito'] ?? 1;

                    // 🎯 RECUPERA DATA FINE
                    DateTime? dataFine;
                    if (voce['dataFineRicorrenza'] != null) {
                      dataFine = voce['dataFineRicorrenza'] is DateTime 
                          ? voce['dataFineRicorrenza'] 
                          : DateTime.tryParse(voce['dataFineRicorrenza'].toString());
                    }
                    
                    // 🎯 CONTROLLA STATO (Terminata se la data è passata)
                    final bool isTerminata = dataFine != null && dataFine.isBefore(DateTime.now());

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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isTerminata ? Colors.white.withOpacity(0.01) : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isTerminata ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.08)),
                      ),
                      child: Opacity(
                        opacity: isTerminata ? 0.45 : 1.0, // 👈 Trasparenza attiva se terminata
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
                                        child: Text(nome, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // 🏷️ BADGE STATO REGOLA (Novità)
                                      if (isTerminata)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orangeAccent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            'Terminata ${dataFine!.day.toString().padLeft(2, '0')}/${dataFine.month.toString().padLeft(2, '0')}',
                                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: greenProfit.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: greenProfit.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            'Attiva',
                                            style: TextStyle(color: greenProfit, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$cat • $freq (gg $giorno)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(
                              tipoMov == 'uscita' ? '- ${_formattaValuta(importo)}' : '+ ${_formattaValuta(importo)}',
                              style: TextStyle(color: coloreIcona, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            if (isPro) ...[
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () => _mostraFormRegolaAvanzata(provider, voceEsistente: voce),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit_outlined, color: Colors.white70, size: 15),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _mostraGestioneEliminazioneRicorrenza(context, provider, voce),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 15),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: 🎯 PILOTAGGIO FATTURATO P.IVA & REGOLE BUSSOLA
  // ===========================================================================
  Widget _buildTabPilotaggioERegole(WalletProvider provider) {
    final bool isPro = provider.isProUser;
    final double targetAnnuo = provider.fatturatoStimato;
    final double totalePilotato = provider.totaleFatturatoPilotato;
    final double differenza = totalePilotato - targetAnnuo;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📊 PILOTAGGIO FATTURATO ANNUALE
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PREVISIONE vs TARGET ANNUO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    Text(
                      'Target: ${_formattaInt(targetAnnuo)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formattaInt(totalePilotato), style: TextStyle(color: greenProfit, fontSize: 20, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (differenza >= 0 ? greenProfit : const Color(0xFFEF4444)).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        differenza >= 0 ? '+${_formattaInt(differenza)} sopra target' : '${_formattaInt(differenza)} sotto target',
                        style: TextStyle(color: differenza >= 0 ? greenProfit : const Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('STIMA FATTURATO MESE PER MESE (€)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),

          // GRIGLIA MESI PILOTAGGIO
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final int meseIdx = index + 1;
              final String nomeMese = _nomiMesiBrevi[index];
              final double stimaCorrente = provider.pilotaggioFatturatoMesi[meseIdx] ?? 0.0;

              return InkWell(
                onTap: () {
                  if (!isPro) {
                    _mostraModalPRO(context);
                  } else {
                    _mostraDialogModificaMese(provider, meseIdx, nomeMese, stimaCorrente);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: stimaCorrente > 0 ? oceanCyan.withOpacity(0.3) : Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomeMese, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      FittedBox(
                        child: Text(
                          _formattaInt(stimaCorrente),
                          style: TextStyle(color: stimaCorrente > 0 ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text('PARAMETRIZZAZIONE BUSSOLA BUDGET', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),

          // REGOLATORE PERCENTUALI 50/30/20
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

                // 🚀 PREFERITI RAPIDI CHIPS
                if (tipoMovimentoSel != 'giroconto') ...[
                  const Text('PREFERITI RAPIDI', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: preferitiRapidi.map((pref) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setPopupState(() {
                                nomeCtrl.text = pref['nome'];
                                categoriaSel = pref['cat'];
                                bussolaSel = pref['bussola'];
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Row(
                                children: [
                                  Icon(pref['icon'] as IconData, size: 12, color: oceanCyan),
                                  const SizedBox(width: 5),
                                  Text(pref['nome'] as String, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
              ],
            ),
          );
        },
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
  void _mostraGestioneEliminazioneRicorrenza(
    BuildContext context,
    WalletProvider provider,
    Map<String, dynamic> voce,
  ) {
    if (voce.isEmpty) return;
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

              AppActionCard(
                icon: Icons.event_busy_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Elimina / Salta solo questo mese',
                subtitle: 'Cancella la registrazione di questo mese. La ricorrenza rimarrà attiva per i mesi futuri.',
                onTap: () {
                  if (isTransaction) {
                    provider.deleteButKeepRecurrence(id);
                  } else {
                    provider.skipPrediction(id, DateTime.now());
                  }
                  Navigator.pop(ctx);
                  AppNotifications.mostraInAlto(
                    context,
                    'Ricorrenza per "$nome" saltata questo mese',
                    type: NotificationType.warning,
                  );
                },
              ),
              const SizedBox(height: 10),

              AppActionCard(
                icon: Icons.block_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Interrompi da questo mese in poi',
                subtitle: 'Ferma i pagamenti futuri ma conserva intatto lo storico dei mesi passati.',
                onTap: () {
                  provider.stopRecurrenceFromDate(id, DateTime.now());
                  if (!isTransaction) {
                    provider.rimuoviSpesaPianificata(id);
                  }
                  Navigator.pop(ctx);
                  AppNotifications.mostraInAlto(
                    context,
                    'Ricorrenza "$nome" disdetta da questo mese in poi!',
                    type: NotificationType.warning,
                  );
                },
              ),
              const SizedBox(height: 10),

              AppActionCard(
                icon: Icons.edit_calendar_rounded,
                iconColor: const Color(0xFFC084FC),
                title: 'Scegli mese di termine...',
                subtitle: 'Imposta una data specifica entro cui fermare la regola.',
                onTap: () async {
                  final picked = await AppDatePicker.selezionaData(
                    context,
                    dataIniziale: DateTime.now(),
                  );
                  if (picked != null) {
                    provider.stopRecurrenceFromDate(id, picked);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      AppNotifications.mostraInAlto(
                        context,
                        'Ricorrenza "$nome" disdetta dal ${picked.month}/${picked.year}!',
                        type: NotificationType.warning,
                      );
                    }
                  }
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