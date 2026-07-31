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

    final double tasseDaAccantonare = accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double tasseTotaliCalcolate = riservaGiaAccantonata + tasseDaAccantonare;
    final double importoMancanteReale = tasseDaAccantonare > 0.01 ? tasseDaAccantonare : 0.0;

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
            backgroundColor: cardColor,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.92),
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
              InkWell(
                onTap: () => _mostraDialogAccantonamentoTasse(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
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
  }
}