import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_secondary_popup.dart';

class SerbatoioTasseWidget extends StatelessWidget {
  final Color cardColor;

  const SerbatoioTasseWidget({
    super.key,
    this.cardColor = const Color(0xFF292524),
  });

  // 🇮🇹 HELPER PER CIFRE INTERE CON PUNTO MIGLIAIA (es. 1.116 €)
  static String _formattaInt(double importo) {
    final int intVal = importo.round();
    return intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // 🇮🇹 HELPER VALUTA DECIMALE ITALIANA (es. 1.115,75 €)
  static String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  // 🛡️ HELPER PARSING SICURO (Riconosce 11.2 come 11,20 € ed evita che diventi 112 €!)
  static double _parseImportoSicuro(String text) {
    if (text.trim().isEmpty) return 0.0;
    String pulito = text.trim().replaceAll(' ', '').replaceAll('€', '');
    
    // 1. Se contiene SIA punto che virgola (es. 1.000,50 o 1,000.50)
    if (pulito.contains('.') && pulito.contains(',')) {
      if (pulito.lastIndexOf(',') > pulito.lastIndexOf('.')) {
        // Standard italiano: 1.000,50 -> rimuovi punto, virgola diventa punto decimale
        pulito = pulito.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Standard anglosassone (es. 1,000.50) -> rimuovi virgola
        pulito = pulito.replaceAll(',', '');
      }
    } 
    // 2. Se contiene SOLO il punto (es. 11.2 o 11.25 o 1.000)
    else if (pulito.contains('.')) {
      final parti = pulito.split('.');
      // Se dopo l'ultimo punto ci sono 1 o 2 cifre (es. 11.2 o 11.25), l'utente intende un decimale!
      if (parti.last.length == 1 || parti.last.length == 2) {
        final dec = parti.removeLast();
        pulito = '${parti.join('')}.$dec';
      } else {
        // Se ci sono 3 cifre (es. 1.000 o 15.000), è un separatore di migliaia
        pulito = pulito.replaceAll('.', '');
      }
    } 
    // 3. Se contiene SOLO la virgola (es. 11,2 o 1000,50)
    else {
      pulito = pulito.replaceAll(',', '.');
    }

    return double.tryParse(pulito) ?? 0.0;
  }

  // 🎨 WIDGET BARRA AVANZAMENTO PROPORZIONALE REALE PER IL POP-UP
  static Widget _buildBarraAvanzamentoSmart(int percentualeInt) {
    if (percentualeInt < 100) {
      final int flexRiempito = percentualeInt.clamp(0, 100);
      final int flexVuoto = 100 - flexRiempito;

      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 8,
          color: Colors.white10,
          child: Row(
            children: [
              if (flexRiempito > 0)
                Expanded(
                  flex: flexRiempito,
                  child: Container(color: const Color(0xFFF59E0B)), // 🟠 Arancione
                ),
              if (flexVuoto > 0)
                Expanded(
                  flex: flexVuoto,
                  child: const SizedBox(),
                ),
            ],
          ),
        ),
      );
    }

    const int flexVerde = 100;
    final int flexCiano = percentualeInt - 100;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 8,
        color: Colors.white10,
        child: Row(
          children: [
            Expanded(
              flex: flexVerde,
              child: Container(color: const Color(0xFF10B981)), // 🟢 Verde 100%
            ),
            if (flexCiano > 0)
              Expanded(
                flex: flexCiano,
                child: Container(color: const Color(0xFF06B6D4)), // 🩵 Ciano Cuscinetto Extra
              ),
          ],
        ),
      ),
    );
  }

  // 🚀 UNICA FONTE DI VERITÀ UTILIZZANDO IL DESIGN SYSTEM STANDARDIZZATO
  static void mostraDialog(BuildContext context, {Color cardColor = const Color(0xFF292524)}) {
    final walletProvider = context.read<WalletProvider>();
    final accounts = walletProvider.accounts;

    if (accounts.length < 2) {
      AppNotifications.mostraInAlto(
        context, 
        'Devi avere almeno due conti per gestire le tasse', 
        type: NotificationType.warning,
      );
      return;
    }

    final double tasseTotaliCalcolate = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));

    final double riservaGiaAccantonata = accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double mancanteReale = (tasseTotaliCalcolate - riservaGiaAccantonata).clamp(0.0, double.infinity);

    final contoPrincipale = accounts.firstWhere(
      (a) => !a.title.toLowerCase().contains('salvadanaio'),
      orElse: () => accounts[0],
    );

    final salvadanaioTasse = accounts.firstWhere(
      (a) => a.title.toLowerCase().contains('salvadanaio tasse'),
      orElse: () => accounts.length > 1 ? accounts[1] : accounts[0],
    );

    // 🏦 CONTI SELEZIONABILI (Tutti tranne il Salvadanaio Tasse stesso)
    final contiDisponibili = accounts
        .where((a) => a.id != salvadanaioTasse.id)
        .toList();

    String contoSorgenteAccantonaId = contiDisponibili.isNotEmpty
        ? contiDisponibili[0].id
        : contoPrincipale.id;

    String contoDestinazioneSbloccoId = contiDisponibili.isNotEmpty
        ? contiDisponibili[0].id
        : contoPrincipale.id;

    bool modalitaAccantona = true;

    // 🇮🇹 Inizializza il campo con la virgola italiana
    final TextEditingController importoController = TextEditingController(
      text: mancanteReale > 0 ? mancanteReale.toStringAsFixed(2).replaceAll('.', ',') : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 🛡️ UTILIZZA IL PARSER SICURO PER LEGGERE IL CAMPO TESTO
          final double importoInserito = _parseImportoSicuro(importoController.text);
          
          final double nuovaRiservaTotale = modalitaAccantona
              ? (riservaGiaAccantonata + importoInserito)
              : (riservaGiaAccantonata - importoInserito).clamp(0.0, double.infinity);

          final double calcoloPercentualeGreggio = tasseTotaliCalcolate > 0.01 
              ? (nuovaRiservaTotale / tasseTotaliCalcolate * 100) 
              : (nuovaRiservaTotale > 0 ? 100.0 : 0.0);
              
          final int percentualeInt = (calcoloPercentualeGreggio - 100).abs() < 0.1 
              ? 100 
              : calcoloPercentualeGreggio.round();
              
          final double extraCuscinetto = nuovaRiservaTotale > tasseTotaliCalcolate 
              ? nuovaRiservaTotale - tasseTotaliCalcolate 
              : 0.0;

          final Color coloreAttuale = modalitaAccantona ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);

          return AppSecondaryPopup(
            backgroundColor: cardColor,
            icon: modalitaAccantona ? Icons.shield_rounded : Icons.lock_open_rounded,
            iconColor: coloreAttuale,
            titolo: modalitaAccantona ? 'Accantona Tasse' : 'Sblocca Fondi Tasse',
            testoConferma: modalitaAccantona ? 'Metti al Sicuro' : 'Sblocca Cifra',
            onConferma: () {
              // 🚨 ALERT SE IMPORTO NON VALIDO, VUOTO O ZERO
              if (importoInserito <= 0) {
                AppNotifications.mostraInAlto(
                  context,
                  'Importo non valido! Inserisci una cifra corretta (es. 100 o 11,50).',
                  type: NotificationType.warning,
                );
                return;
              }

              if (modalitaAccantona) {
                final contoSorgente = accounts.firstWhere((a) => a.id == contoSorgenteAccantonaId);

                if (contoSorgente.amount < importoInserito) {
                  AppNotifications.mostraInAlto(
                    context,
                    'Saldo insufficiente su ${contoSorgente.title}!',
                    type: NotificationType.error,
                  );
                  return;
                }

                walletProvider.eseguiGiroconto(
                  daAccountId: contoSorgenteAccantonaId,
                  aAccountId: salvadanaioTasse.id,
                  importo: importoInserito,
                  isAccantonamentoTasse: true,
                );
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(
                  context,
                  'Messo al sicuro il capitale per le tasse da ${contoSorgente.title}! 🛡️',
                  type: NotificationType.success,
                );
              } else {
                if (salvadanaioTasse.amount < importoInserito) {
                  AppNotifications.mostraInAlto(
                    context,
                    'Fondi insufficienti nel Salvadanaio Tasse!',
                    type: NotificationType.error,
                  );
                  return;
                }

                final contoDestinazione = accounts.firstWhere((a) => a.id == contoDestinazioneSbloccoId);

                walletProvider.eseguiGiroconto(
                  daAccountId: salvadanaioTasse.id,
                  aAccountId: contoDestinazioneSbloccoId,
                  importo: importoInserito,
                  isAccantonamentoTasse: false,
                );
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(
                  context,
                  'Sbloccati ${_formattaValuta(importoInserito)} verso ${contoDestinazione.title}! 🔓',
                  type: NotificationType.warning,
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TAB SELETTORE ACCANTONA / SBLOCCA
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              modalitaAccantona = true;
                              importoController.text = mancanteReale > 0 ? mancanteReale.toStringAsFixed(2).replaceAll('.', ',') : '';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: modalitaAccantona ? const Color(0xFF3B82F6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                '🛡️ Accantona',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              modalitaAccantona = false;
                              importoController.text = '';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !modalitaAccantona ? const Color(0xFFF59E0B) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                '🔓 Sblocca',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Totale Tasse Dovute:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(_formattaValuta(tasseTotaliCalcolate), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Già in Salvadanaio:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(_formattaValuta(riservaGiaAccantonata), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          'Copertura: $percentualeInt%',
                          style: TextStyle(
                            color: percentualeInt >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (extraCuscinetto > 0)
                          Text(
                            '+${_formattaInt(extraCuscinetto)} € Cuscinetto',
                            style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold), // 🩵 Ciano
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildBarraAvanzamentoSmart(percentualeInt),
                  ],
                ),

                const SizedBox(height: 16),

                // 🏦 MENU TENDINA CONTO SORGENTE / DESTINAZIONE SIMMETRICO
                if (modalitaAccantona) ...[
                  DropdownButtonFormField<String>(
                    value: contoSorgenteAccantonaId,
                    dropdownColor: cardColor,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Preleva la cifra da:',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3B82F6), size: 18),
                    ),
                    items: contiDisponibili.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text('${acc.title} (${_formattaInt(acc.amount)} €)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          contoSorgenteAccantonaId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: contoDestinazioneSbloccoId,
                    dropdownColor: cardColor,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Versa la cifra su:',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFF59E0B), size: 18),
                    ),
                    items: contiDisponibili.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text('${acc.title} (${_formattaInt(acc.amount)} €)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          contoDestinazioneSbloccoId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: importoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: modalitaAccantona ? 'Importo da spostare nel Salvadanaio (€)' : 'Importo da prelevare dal Salvadanaio (€)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: Icon(
                      modalitaAccantona ? Icons.savings_rounded : Icons.payments_rounded, 
                      color: coloreAttuale, 
                      size: 20
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    final double riservaAccantonata = walletProvider.accounts
        .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, acc) => sum + acc.amount);

    final double mancanteReale = (tasseTotaliCalcolate - riservaAccantonata).clamp(0.0, double.infinity);

    final double percentuale = tasseTotaliCalcolate > 0.01
        ? (riservaAccantonata / tasseTotaliCalcolate).clamp(0.0, 1.0)
        : (riservaAccantonata > 0 ? 1.0 : 0.0);

    final double calcoloPercentualeGreggio = tasseTotaliCalcolate > 0.01 
        ? (riservaAccantonata / tasseTotaliCalcolate * 100) 
        : (riservaAccantonata > 0 ? 100.0 : 0.0);

    final int percentualeTextInt = (calcoloPercentualeGreggio - 100).abs() < 0.1 
        ? 100 
        : calcoloPercentualeGreggio.round();

    final double cuscinettoExtraVal = riservaAccantonata > tasseTotaliCalcolate
        ? (riservaAccantonata - tasseTotaliCalcolate)
        : 0.0;

    final Color statusColor = percentualeTextInt >= 100 
        ? const Color(0xFF10B981) 
        : const Color(0xFFF59E0B);

    final double avanzamentoBluExtra = percentualeTextInt > 100
        ? ((percentualeTextInt - 100) / 100).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 📌 1. HEADER
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
              InkWell(
                onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: cardColor),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$percentualeTextInt% Coperto',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 📌 2. CERCHIO DI PROGRESSO
          Center(
            child: SizedBox(
              width: 114,
              height: 114,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 108,
                    height: 108,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.08)),
                    ),
                  ),

                  SizedBox(
                    width: 108,
                    height: 108,
                    child: CircularProgressIndicator(
                      value: percentuale,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),

                  if (avanzamentoBluExtra > 0)
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: avanzamentoBluExtra,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)), // 🩵 Ciano Cuscinetto Extra
                      ),
                    ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'IN SALVADANAIO',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${_formattaInt(riservaAccantonata)} €',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'su ${_formattaInt(tasseTotaliCalcolate)} €',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 📌 3. SUGGERIMENTO CONVERSAZIONALE INFERIORE
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                mancanteReale > 0 ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                color: mancanteReale > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mancanteReale > 0
                      ? 'Consiglio: accantona i ${_formattaInt(mancanteReale)} € mancanti per metterti al sicuro.'
                      : (cuscinettoExtraVal > 0
                          ? 'Ottimo! Hai +${_formattaInt(cuscinettoExtraVal)} € di cuscinetto extra protetto.'
                          : 'Ottimo! Hai accantonato tutta la stima fiscale dovuta.'),
                  style: TextStyle(
                    color: mancanteReale > 0 ? const Color(0xFFF59E0B) : Colors.white70,
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
}