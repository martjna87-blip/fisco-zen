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

  // 🛡️ DIALOG RAPIDO CON GOAL TRACKER & FEEDBACK PERCENTUALE
  void _mostraDialogAccantonamentoTasse(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final accounts = walletProvider.accounts;

    if (accounts.length < 2) {
      AppNotifications.mostraInAlto(
        context, 
        'Devi avere almeno due conti per accantonare le tasse', 
        type: NotificationType.warning,
      );
      return;
    }

    final double riservaGiaAccantonata = accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    // 🎯 Tasse rimaste sul Conto Principale da spostare nel Salvadanaio
    final double tasseDaAccantonare = accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);

    // 🎯 Totale Tasse Dovute = Già in Salvadanaio + Ancora da accantonare
    final double tasseTotaliCalcolate = riservaGiaAccantonata + tasseDaAccantonare;

    // 🎯 Quanto manca per il 100% è esattamente l'importo rimasto sul conto!
    final double tasseScoperte = tasseDaAccantonare;
    final double importoMancanteReale = tasseScoperte > 0.01 ? tasseScoperte : 0.0;

    final TextEditingController importoController = TextEditingController(
      text: importoMancanteReale > 0 ? importoMancanteReale.toStringAsFixed(2) : '',
    );

    final contoConTasse = accounts.firstWhere(
      (a) => a.virtualTaxAmount > 0 && !a.title.toLowerCase().contains('salvadanaio'),
      orElse: () => accounts[0],
    );

    final salvadanaioTasse = accounts.firstWhere(
      (a) => a.title.toLowerCase().contains('salvadanaio tasse'),
      orElse: () => accounts.length > 1 ? accounts[1] : accounts[0],
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final double importoInserito = double.tryParse(importoController.text.replaceAll(',', '.')) ?? 0.0;
          final double nuovaRiservaTotale = riservaGiaAccantonata + importoInserito;
          
          final double percentualeText = tasseTotaliCalcolate > 0.01 
              ? (nuovaRiservaTotale / tasseTotaliCalcolate * 100) 
              : (nuovaRiservaTotale > 0 ? 100.0 : 0.0);
              
          final double percentualeBarra = tasseTotaliCalcolate > 0.01 
              ? (nuovaRiservaTotale / tasseTotaliCalcolate).clamp(0.0, 1.0) 
              : (nuovaRiservaTotale > 0 ? 1.0 : 0.0);
              
          final double extraCuscinetto = nuovaRiservaTotale > tasseTotaliCalcolate 
              ? nuovaRiservaTotale - tasseTotaliCalcolate 
              : 0.0;

          return AlertDialog(
            backgroundColor: coloreCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 22),
                SizedBox(width: 8),
                Text('Accantona Tasse', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Totale Tasse Dovute:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('${tasseTotaliCalcolate.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Già in Salvadanaio:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('${riservaGiaAccantonata.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Copertura Totale: ${percentualeText.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (extraCuscinetto > 0)
                            Text(
                              '+${extraCuscinetto.toStringAsFixed(0)} € Cuscinetto',
                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percentualeBarra,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: importoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Importo da aggiungere (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (importoInserito > 0) {
                    if (contoConTasse.amount < importoInserito) {
                      AppNotifications.mostraInAlto(
                        context,
                        'Saldo insufficiente su ${contoConTasse.title} per l\'accantonamento!',
                        type: NotificationType.error,
                      );
                      return;
                    }

                    walletProvider.eseguiGiroconto(
                      daAccountId: contoConTasse.id,
                      aAccountId: salvadanaioTasse.id,
                      importo: importoInserito,
                      isAccantonamentoTasse: true,
                    );
                    Navigator.pop(ctx);
                    AppNotifications.mostraInAlto(
                      context,
                      extraCuscinetto > 0
                          ? 'Messo al sicuro il 100% delle tasse + ${extraCuscinetto.toStringAsFixed(0)} € di cuscinetto! 🛡️'
                          : 'Hai messo al sicuro ${importoInserito.toStringAsFixed(2)} €! 🎉',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Metti al Sicuro', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

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

                // 5. CONTENUTO CENTRATO: SOLO LE METRICHE FINANZIARIE
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 💡 Etichetta discreta per chiarire la cifra
                      const Text(
                        'PATRIMONIO',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${patrimonioNetto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          
                          if (widget.isPiva) ...[
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 12),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${nettoReale.toStringAsFixed(0)} €',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 12),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${tasseTotaliCalcolate.toStringAsFixed(0)} €',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    if (!isTasseCoperte) 
                                      InkWell(
                                        onTap: () => _mostraDialogAccantonamentoTasse(context),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: coloreCard.withOpacity(0.92),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                                          ),
                                          child: const Text(
                                            'Accantona',
                                            style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    else
                                      InkWell(
                                        onTap: () => _mostraDialogAccantonamentoTasse(context),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: coloreCard.withOpacity(0.92),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                                              SizedBox(width: 3),
                                              Text(
                                                'Protette',
                                                style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
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

                  // 🛡️ 1. SERBATOIO RISERVA TASSE
                  if (mostraPiva) ...[
                    Builder(
                      builder: (context) {
                        final double riservaAccantonata = walletProvider.accounts
                            .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
                            .fold(0.0, (sum, acc) => sum + acc.amount);

                        final double percentuale = tasseTotaliCalcolate > 0.01 
                            ? (riservaAccantonata / tasseTotaliCalcolate).clamp(0.0, 1.0) 
                            : (riservaAccantonata > 0 ? 1.0 : 0.0);

                        final double percentualeText = tasseTotaliCalcolate > 0.01 
                            ? (riservaAccantonata / tasseTotaliCalcolate * 100) 
                            : (riservaAccantonata > 0 ? 100.0 : 0.0);

                        final double cuscinettoExtraVal = riservaAccantonata > tasseTotaliCalcolate 
                            ? (riservaAccantonata - tasseTotaliCalcolate) 
                            : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: coloreCard.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Serbatoio Riserva Tasse',
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: percentualeText >= 100 
                                          ? const Color(0xFF10B981).withOpacity(0.15) 
                                          : const Color(0xFFF59E0B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${percentualeText.toStringAsFixed(0)}% Coperto',
                                      style: TextStyle(
                                        color: percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percentuale,
                                  minHeight: 8,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 📊 RIGA VALORI (DOVUTO VS IN SALVADANAIO)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Dovuto Ateco: ${tasseTotaliCalcolate.toStringAsFixed(0)} €',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                  Text(
                                    'In Salvadanaio: ${riservaAccantonata.toStringAsFixed(0)} €',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),

                              // 🛡️ BADGE BLU: CUSCINETTO DI SICUREZZA EXTRA (Se presente)
                              if (cuscinettoExtraVal > 0) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 13),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Cuscinetto di sicurezza extra: +${cuscinettoExtraVal.toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // 2. 3 QUADRANTI AZIONE
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionSquareCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Movimenti',
                          value: 'Entrata / Uscita',
                          onTap: () {
                            // 🎯 PRIMA ERA: showModalBottomSheet(...)
                            AppPopupWrapper.mostra(
                              context: context,
                              child: const AddMovementSheet(initialTab: 'riepilogo'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionSquareCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Gestione\nConti',
                          value: '3 Attivi',
                          onTap: () {
                            // 🎯 PRIMA ERA: showModalBottomSheet(...)
                            AppPopupWrapper.mostra(
                              context: context,
                              child: ManageAccountsSheet(isPiva: widget.isPiva),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionSquareCard(
                          icon: Icons.pie_chart_outline_rounded,
                          title: 'Pilotaggio\nBudget',
                          value: 'Pianificazione',
                          onTap: () {
                            // 🎯 PRIMA ERA: showModalBottomSheet(...)
                            AppPopupWrapper.mostra(
                              context: context,
                              child: const BudgetPilotSheet(),
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

  Widget _buildActionSquareCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: coloreCard.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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