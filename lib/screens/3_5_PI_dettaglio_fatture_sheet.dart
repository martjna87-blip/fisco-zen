import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_bottom_sheet.dart';

class DettaglioFattureSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? fattureIncassate;
  final double coefficienteRedditivita;
  final double aliquotaImposta;
  final double aliquotaInps;

  const DettaglioFattureSheet({
    super.key,
    this.fattureIncassate,
    required this.coefficienteRedditivita,
    required this.aliquotaImposta,
    required this.aliquotaInps,
  });

  @override
  State<DettaglioFattureSheet> createState() => _DettaglioFattureSheetState();
}

class _DettaglioFattureSheetState extends State<DettaglioFattureSheet> {
  int _meseSelezionato = 0; 
  final Set<String> _expandedFattureIds = {}; 
  bool _isSospesoEspanso = false;

  final List<String> _mesiStr = [
    'Anno', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giug',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
  ];

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  void _confermaEliminazione(BuildContext context, Map<String, dynamic> fattura) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Elimina Fattura', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Sei sicuro di voler eliminare la fattura "${fattura['cliente']}" (${fattura['numero'] ?? 'Fattura'})?\nQuesta azione la rimuoverà dal registro, dal bilancio e dai calcoli fiscali.',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
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
              final String? id = fattura['id'] as String?;
              if (id != null) {
                Provider.of<WalletProvider>(context, listen: false).eliminaFatturaPiva(id);
              }

              Navigator.pop(ctx);
              setState(() {});
              AppNotifications.mostraInAlto(
                context, 
                'Fattura di "${fattura['cliente']}" eliminata 🎉',
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFattureFiltrate(List<Map<String, dynamic>> sorgenteFatture) {
    if (_meseSelezionato == 0) {
      return sorgenteFatture;
    }

    return sorgenteFatture.where((f) {
      final rawData = f['dataIncasso'] ?? f['data'];
      if (rawData != null) {
        if (rawData is DateTime) {
          return rawData.month == _meseSelezionato;
        }

        if (rawData is String) {
          final parsedIso = DateTime.tryParse(rawData);
          if (parsedIso != null) {
            return parsedIso.month == _meseSelezionato;
          }

          final parti = rawData.split(RegExp(r'[/.-]'));
          if (parti.length >= 2) {
            final meseParsed = int.tryParse(parti[1]);
            if (meseParsed != null) {
              return meseParsed == _meseSelezionato;
            }
          }
        }
      }

      return false;
    }).toList();
  }

  String _formattaGiornoMese(dynamic rawData) {
    if (rawData == null) return '';
    if (rawData is DateTime) {
      final g = rawData.day.toString().padLeft(2, '0');
      final m = rawData.month.toString().padLeft(2, '0');
      return '$g/$m';
    }
    if (rawData is String) {
      final parti = rawData.split(RegExp(r'[/.-]'));
      if (parti.length >= 2) {
        if (parti[0].length <= 2) {
          final g = parti[0].padLeft(2, '0');
          final m = parti[1].padLeft(2, '0');
          return '$g/$m';
        } 
        else if (parti[0].length == 4 && parti.length >= 3) {
          final m = parti[1].padLeft(2, '0');
          final g = parti[2].padLeft(2, '0');
          return '$g/$m';
        }
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    final listaTutteIncassate = widget.fattureIncassate ?? walletProvider.fattureIncassate;
    final fattureFiltrate = _getFattureFiltrate(listaTutteIncassate);
    final fattureInSospeso = walletProvider.fattureDaIncassare;

    final int mesiLavorati = walletProvider.mesiAttivi > 0 ? walletProvider.mesiAttivi : 10;
    final double percentualeFondoFerie = (12 - mesiLavorati) / 12;

    double lordoTotale = 0.0;
    double inpsYTotale = 0.0;
    double impostaYTotale = 0.0;
    double accontoInpsY1Totale = 0.0;
    double accontoImpostaY1Totale = 0.0;

    for (var f in fattureFiltrate) {
      final double lordo = (f['importo'] as num).toDouble();
      final double coefFattura = (f['coefAteco'] as num?)?.toDouble() ?? widget.coefficienteRedditivita;
      final double imponibile = lordo * coefFattura;
      
      final double inpsY = imponibile * widget.aliquotaInps;
      final double impostaY = imponibile * widget.aliquotaImposta;
      
      final double accontoInpsY1 = inpsY * 0.80;
      final double accontoImpostaY1 = impostaY * 1.00;

      lordoTotale += lordo;
      inpsYTotale += inpsY;
      impostaYTotale += impostaY;
      accontoInpsY1Totale += accontoInpsY1;
      accontoImpostaY1Totale += accontoImpostaY1;
    }

    final double totaleTasseY = inpsYTotale + impostaYTotale;
    final double totaleAccontiY1 = accontoInpsY1Totale + accontoImpostaY1Totale;
    final double grandTotaleAccantonare = totaleTasseY + totaleAccontiY1;

    final double grandNettoDopoTasse = lordoTotale - grandTotaleAccantonare;
    final double grandQuotaFondoFerie = grandNettoDopoTasse * percentualeFondoFerie;
    final double nettoTotaleSpendibile = grandNettoDopoTasse - grandQuotaFondoFerie;

    double lordoSospeso = 0.0;
    double imponibileSospeso = 0.0;
    double inpsSospeso = 0.0;
    double impostaSospeso = 0.0;

    for (var f in fattureInSospeso) {
      final double importo = (f['importo'] as num?)?.toDouble() ?? 0.0;
      final double coef = (f['coefAteco'] as num?)?.toDouble() ?? widget.coefficienteRedditivita;
      
      final double imponibile = importo * coef;
      lordoSospeso += importo;
      imponibileSospeso += imponibile;
      inpsSospeso += (imponibile * widget.aliquotaInps);
      impostaSospeso += (imponibile * widget.aliquotaImposta);
    }

    final double saldoSospeso = inpsSospeso + impostaSospeso;
    final double accontiSospeso = (inpsSospeso * 0.80) + (impostaSospeso * 1.00);
    final double totaleF24Sospeso = saldoSospeso + accontiSospeso;

    final int annoCorrente = DateTime.now().year;
    final int annoProssimo = annoCorrente + 1;

    return AppBottomSheet(
      title: 'Dettaglio Fiscale',
      badgeText: 'P.IVA',
      badgeColor: const Color(0xFF2DD4BF),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _mesiStr.length,
              itemBuilder: (context, idx) {
                final isSelected = _meseSelezionato == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(_mesiStr[idx]),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: const Color(0xFF2DD4BF),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.12),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _meseSelezionato = idx;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (fattureFiltrate.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          _meseSelezionato == 0
                              ? 'Nessuna fattura incassata salvata.'
                              : 'Nessuna fattura presente per ${_mesiStr[_meseSelezionato]}.',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...fattureFiltrate.asMap().entries.map((entry) {
                      final f = entry.value;
                      final String fId = f['id']?.toString() ?? entry.key.toString();
                      final bool isExpanded = _expandedFattureIds.contains(fId);

                      final double lordo = (f['importo'] as num).toDouble();
                      final double coefFattura = (f['coefAteco'] as num?)?.toDouble() ?? widget.coefficienteRedditivita;
                      final double imponibile = lordo * coefFattura;

                      final double inpsY = imponibile * widget.aliquotaInps;
                      final double impostaY = imponibile * widget.aliquotaImposta;
                      final double totaleTasseYCard = inpsY + impostaY;
                      
                      final double accontoInpsY1Card = inpsY * 0.80;
                      final double accontoImpostaY1Card = impostaY * 1.00;
                      final double totaleAccontiY1Card = accontoInpsY1Card + accontoImpostaY1Card;

                      final double totaleTasseAccantonare = totaleTasseYCard + totaleAccontiY1Card;

                      final double nettoDopoTasseCard = lordo - totaleTasseAccantonare;
                      final double quotaFondoFerieCard = nettoDopoTasseCard * percentualeFondoFerie;
                      final double nettoSpendibileCard = nettoDopoTasseCard - quotaFondoFerieCard;

                      final String dataIncassoStr = _formattaGiornoMese(f['dataIncasso'] ?? f['data']);
                      final String dataEmissioneStr = _formattaGiornoMese(f['data'] ?? f['dataIncasso']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpanded
                                ? const Color(0xFF2DD4BF).withOpacity(0.5)
                                : const Color(0xFF2DD4BF).withOpacity(0.2),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedFattureIds.remove(fId);
                              } else {
                                _expandedFattureIds.add(fId);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${f['cliente']} (#${f['numero'] ?? ''})',
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // ✨ BADGE ATECO AGGIORNATO
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.verified_rounded, color: Color(0xFF2DD4BF), size: 10),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'ATECO ${(coefFattura * 100).toInt()}%',
                                                  style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '+${_formattaValuta(lordo)}',
                                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: const Color(0xFF2DD4BF),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 11),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Registrazione: $dataEmissioneStr',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 11),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Incasso: $dataIncassoStr',
                                      style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(height: 12),
                                  Divider(color: Colors.white.withOpacity(0.12), height: 1),
                                  const SizedBox(height: 12),
                                  _buildSalvaDanaioRow(
                                    icon: Icons.add_circle_outline_rounded,
                                    color: const Color(0xFF10B981),
                                    title: 'Incasso Lordo:',
                                    value: '+${_formattaValuta(lordo)}',
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildSalvaDanaioRow(
                                    icon: Icons.account_balance_wallet_rounded,
                                    color: const Color(0xFF2DD4BF),
                                    title: 'Netto Spendibile:',
                                    value: '+${_formattaValuta(nettoSpendibileCard)}',
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildSalvaDanaioRow(
                                    icon: Icons.shield_rounded,
                                    color: const Color(0xFF3B82F6),
                                    title: 'Tasse (Saldo + Acconto):',
                                    value: '-${_formattaValuta(totaleTasseAccantonare)}',
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildSalvaDanaioRow(
                                    icon: Icons.beach_access_rounded,
                                    color: const Color(0xFF8B5CF6),
                                    title: 'Cuscinetto mesi No-Lavoro ($mesiLavorati Mesi):',
                                    value: '-${_formattaValuta(quotaFondoFerieCard)}',
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(color: Colors.white.withOpacity(0.12), height: 1),
                                  const SizedBox(height: 8),
                                  _buildSimpleRow('Saldo INPS', _formattaValuta(inpsY), Colors.white70),
                                  _buildSimpleRow('Saldo Imposta', _formattaValuta(impostaY), Colors.white70),
                                  _buildSimpleRow('Totale Saldo', _formattaValuta(totaleTasseYCard), const Color(0xFFF59E0B), isBold: true),
                                  const SizedBox(height: 8),
                                  Divider(color: Colors.white.withOpacity(0.12), height: 1),
                                  const SizedBox(height: 8),
                                  _buildSimpleRow('Acconto INPS', _formattaValuta(accontoInpsY1Card), Colors.white70),
                                  _buildSimpleRow('Acconto Imposta', _formattaValuta(accontoImpostaY1Card), Colors.white70),
                                  _buildSimpleRow('Totale Acconto', _formattaValuta(totaleAccontiY1Card), const Color(0xFFF97316), isBold: true),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: InkWell(
                                      onTap: () => _confermaEliminazione(context, f),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 14),
                                            SizedBox(width: 4),
                                            Text('Elimina Fattura', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _meseSelezionato == 0
                                  ? 'RIEPILOGO FISCALE COMPLETO'
                                  : 'RIEPILOGO FISCALE (${_mesiStr[_meseSelezionato].toUpperCase()})',
                              style: const TextStyle(
                                color: Color(0xFF2DD4BF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Icon(Icons.analytics_outlined, color: Color(0xFF2DD4BF), size: 16),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSalvaDanaioRow(
                          icon: Icons.add_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Incasso Lordo:',
                          value: '+${_formattaValuta(lordoTotale)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 6),
                        _buildSalvaDanaioRow(
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF2DD4BF),
                          title: 'Netto Spendibile:',
                          value: '+${_formattaValuta(nettoTotaleSpendibile)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 6),
                        _buildSalvaDanaioRow(
                          icon: Icons.shield_rounded,
                          color: const Color(0xFF3B82F6),
                          title: 'Totale Tasse (Saldo + Acconto):',
                          value: '-${_formattaValuta(grandTotaleAccantonare)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 6),
                        _buildSalvaDanaioRow(
                          icon: Icons.beach_access_rounded,
                          color: const Color(0xFF8B5CF6),
                          title: 'Cuscinetto mesi No-Lavoro ($mesiLavorati Mesi):',
                          value: '-${_formattaValuta(grandQuotaFondoFerie)}',
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.white.withOpacity(0.12), height: 1),
                        const SizedBox(height: 8),
                        _buildSalvaDanaioRow(
                          icon: Icons.remove_circle_outline,
                          color: const Color(0xFFF59E0B),
                          title: 'Totale Saldo (Anno $annoCorrente):',
                          value: '-${_formattaValuta(totaleTasseY)}',
                        ),
                        const SizedBox(height: 6),
                        _buildSalvaDanaioRow(
                          icon: Icons.history_toggle_off_rounded,
                          color: const Color(0xFFF97316),
                          title: 'Totale Acconto (Anno $annoProssimo):',
                          value: '-${_formattaValuta(totaleAccontiY1)}',
                        ),
                      ],
                    ),
                  ),

                  if (lordoSospeso > 0) ...[
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _isSospesoEspanso = !_isSospesoEspanso),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B), size: 18),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'FATTURE EMESSE IN SOSPESO',
                                            style: TextStyle(
                                              color: Color(0xFFF59E0B),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${fattureInSospeso.length} fattur${fattureInSospeso.length == 1 ? "a" : "e"} per ${_formattaValuta(lordoSospeso)}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _isSospesoEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isSospesoEspanso) ...[
                            const Divider(color: Colors.white12, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRow('Lordo non incassato:', '+${_formattaValuta(lordoSospeso)}', color: Colors.white),
                                  _buildRow('Imponibile Fiscale Stimato:', _formattaValuta(imponibileSospeso)),
                                  _buildRow('Saldo Tasse Stimato (Anno $annoCorrente):', '-${_formattaValuta(saldoSospeso)}', color: const Color(0xFFF59E0B)),
                                  _buildRow('Acconti Stimati (Anno $annoProssimo):', '-${_formattaValuta(accontiSospeso)}', color: const Color(0xFFF97316)),
                                  Divider(color: Colors.white.withOpacity(0.12), height: 10),
                                  _buildRow('Totale Tasse Stimato in Sospeso:', '-${_formattaValuta(totaleF24Sospeso)}', color: const Color(0xFFEF4444), isBold: true),
                                  
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.35),
                                              children: [
                                                const TextSpan(
                                                  text: 'Regola del Criterio di Cassa: ',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                                ),
                                                const TextSpan(text: 'Se queste fatture non vengono incassate entro il '),
                                                const TextSpan(
                                                  text: '31 Dicembre',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                                const TextSpan(text: ', la relativa quota tasse slitterà automaticamente alla dichiarazione dei redditi dell\'anno prossimo!'),
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
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color ?? (isBold ? Colors.white : Colors.white.withOpacity(0.9)),
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalvaDanaioRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ✨ MODIFICATO: Più contrasto e respiro verticale
  Widget _buildSimpleRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}