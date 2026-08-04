import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';

class SerbatoioTasseWidget extends StatelessWidget {
  final Color cardColor;

  const SerbatoioTasseWidget({
    super.key,
    this.cardColor = const Color(0xFF292524),
  });

  // 🚀 METODO STATICO E PUBBLICO: UNICA FONTE DI VERITÀ PER IL POPUP
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

    // 🎯 1. TOTALE TASSE DOVUTE REALI (Dalle fatture incassate ATECO)
    final double tasseTotaliCalcolate = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));

    // 🎯 2. RISERVA GIÀ IN SALVADANAIO
    final double riservaGiaAccantonata = accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    // 🎯 3. IMPORTO MANCANTE PER IL 100%
    final double mancanteReale = (tasseTotaliCalcolate - riservaGiaAccantonata).clamp(0.0, double.infinity);

    final contoPrincipale = accounts.firstWhere(
      (a) => !a.title.toLowerCase().contains('salvadanaio'),
      orElse: () => accounts[0],
    );

    final salvadanaioTasse = accounts.firstWhere(
      (a) => a.title.toLowerCase().contains('salvadanaio tasse'),
      orElse: () => accounts.length > 1 ? accounts[1] : accounts[0],
    );

    // 🎯 LISTA CONTI DISPONIBILI PER RICEVERE LO SBLOCCO (Tutti tranne il Salvadanaio Tasse)
    final contiDisponibiliSblocco = accounts
        .where((a) => a.id != salvadanaioTasse.id)
        .toList();

    String contoDestinazioneSbloccoId = contiDisponibiliSblocco.isNotEmpty
        ? contiDisponibiliSblocco[0].id
        : contoPrincipale.id;

    bool modalitaAccantona = true;

    final TextEditingController importoController = TextEditingController(
      text: mancanteReale > 0 ? mancanteReale.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final double importoInserito = double.tryParse(importoController.text.replaceAll(',', '.')) ?? 0.0;
          
          final double nuovaRiservaTotale = modalitaAccantona
              ? (riservaGiaAccantonata + importoInserito)
              : (riservaGiaAccantonata - importoInserito).clamp(0.0, double.infinity);
          
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
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      modalitaAccantona ? Icons.shield_rounded : Icons.lock_open_rounded, 
                      color: modalitaAccantona ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B), 
                      size: 22
                    ),
                    const SizedBox(width: 8),
                    Text(
                      modalitaAccantona ? 'Accantona Tasse' : 'Sblocca Fondi Tasse', 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 🎛️ TAB ACCANTONA / SBLOCCA
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
                              importoController.text = mancanteReale > 0 ? mancanteReale.toStringAsFixed(2) : '';
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

                  // BARRA AVANZAMENTO
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Copertura: ${percentualeText.toStringAsFixed(0)}%',
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

                  // 🏦 SELETTORE CONTO DESTINAZIONE (Visibile SOLO quando sei su "Sblocca")
                  if (!modalitaAccantona) ...[
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
                      items: contiDisponibiliSblocco.map((acc) {
                        return DropdownMenuItem<String>(
                          value: acc.id,
                          child: Text('${acc.title} (${acc.amount.toStringAsFixed(0)} €)'),
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
                        color: modalitaAccantona ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B), 
                        size: 20
                      ),
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
                  if (importoInserito <= 0) return;

                  if (modalitaAccantona) {
                    if (contoPrincipale.amount < importoInserito) {
                      AppNotifications.mostraInAlto(
                        context,
                        'Saldo insufficiente su ${contoPrincipale.title}!',
                        type: NotificationType.error,
                      );
                      return;
                    }

                    walletProvider.eseguiGiroconto(
                      daAccountId: contoPrincipale.id,
                      aAccountId: salvadanaioTasse.id,
                      importo: importoInserito,
                      isAccantonamentoTasse: true,
                    );
                    Navigator.pop(ctx);
                    AppNotifications.mostraInAlto(
                      context,
                      'Messo al sicuro il capitale per le tasse! 🛡️',
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
                      'Sbloccati ${importoInserito.toStringAsFixed(2)} € verso ${contoDestinazione.title}! 🔓',
                      type: NotificationType.warning,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: modalitaAccantona ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  modalitaAccantona ? 'Metti al Sicuro' : 'Sblocca Cifra', 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ],
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

    final double percentuale = tasseTotaliCalcolate > 0.01
        ? (riservaAccantonata / tasseTotaliCalcolate).clamp(0.0, 1.0)
        : (riservaAccantonata > 0 ? 1.0 : 0.0);

    final double percentualeText = tasseTotaliCalcolate > 0.01
        ? (riservaAccantonata / tasseTotaliCalcolate * 100)
        : (riservaAccantonata > 0 ? 100.0 : 0.0);

    final double cuscinettoExtraVal = riservaAccantonata > tasseTotaliCalcolate
        ? (riservaAccantonata - tasseTotaliCalcolate)
        : 0.0;

    final Color statusColor = percentualeText >= 100 
        ? const Color(0xFF10B981) 
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    '${percentualeText.toStringAsFixed(0)}% Coperto',
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

          const SizedBox(height: 18),

          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 9,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percentuale,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'IN SALVADANAIO',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${riservaAccantonata.toStringAsFixed(0)} €',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (cuscinettoExtraVal > 0) ...[
            const SizedBox(height: 16),
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
  }
}