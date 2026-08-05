import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';

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

  final List<String> _mesiStr = [
    'Anno', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giug',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
  ];

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
      if (f['mese'] != null && f['mese'] is int) {
        return f['mese'] == _meseSelezionato;
      }

      final rawData = f['data'];
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

    final listaTutteIncassate = walletProvider.fattureIncassate;
    final fattureFiltrate = _getFattureFiltrate(listaTutteIncassate);

    double lordoTotale = 0.0;
    double inpsYTotale = 0.0;
    double impostaYTotale = 0.0;
    double accontoInpsY1Totale = 0.0;
    double accontoImpostaY1Totale = 0.0;

    for (var f in fattureFiltrate) {
      final double lordo = (f['importo'] as num).toDouble();
      // 📌 LEGGIAMO L'ATECO SPECIFICO DI OGNI SINGOLA FATTURA
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
    final double nettoTotaleRimanente = lordoTotale - grandTotaleAccantonare;

    return AppPopupWrapper(
      title: 'Dettaglio Fiscale',
      badgeText: 'Fatture Incassate',
      badgeColor: const Color(0xFF2DD4BF),
      badgeTextColor: Colors.black,
      child: Column(
        children: [
          // 📌 SELETTORE MESI
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

          // 📌 LISTA FATTURE INCASSATE
          Expanded(
            child: fattureFiltrate.isEmpty
                ? Center(
                    child: Text(
                      _meseSelezionato == 0
                          ? 'Nessuna fattura incassata salvata.'
                          : 'Nessuna fattura presente per ${_mesiStr[_meseSelezionato]}.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: fattureFiltrate.length,
                    itemBuilder: (context, index) {
                      final f = fattureFiltrate[index];
                      final String fId = f['id']?.toString() ?? index.toString();
                      final bool isExpanded = _expandedFattureIds.contains(fId);

                      final double lordo = (f['importo'] as num).toDouble();
                      // 📌 LEGGIAMO L'ATECO SPECIFICO DI OGNI SINGOLA FATTURA ANCHE PER LA CARD
                      final double coefFattura = (f['coefAteco'] as num?)?.toDouble() ?? widget.coefficienteRedditivita;
                      final double imponibile = lordo * coefFattura;

                      final double inpsY = imponibile * widget.aliquotaInps;
                      final double impostaY = imponibile * widget.aliquotaImposta;
                      final double totaleTasseY = inpsY + impostaY;
                      
                      final double accontoInpsY1 = inpsY * 0.80;
                      final double accontoImpostaY1 = impostaY * 1.00;
                      final double totaleAccontiY1 = accontoInpsY1 + accontoImpostaY1;

                      final double totaleAccantonareCard = totaleTasseY + totaleAccontiY1;
                      final double nettoRimanenteCard = lordo - totaleAccantonareCard;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpanded
                                ? const Color(0xFF2DD4BF).withOpacity(0.4)
                                : Colors.white.withOpacity(0.1),
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
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '${f['cliente']} (${f['numero'] ?? 'Fattura'})',
                                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${(coefFattura * 100).toInt()}%',
                                                  style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_formattaGiornoMese(f['data']).isNotEmpty)
                                            Text(
                                              'Incassata il ${_formattaGiornoMese(f['data'])}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '+${lordo.toStringAsFixed(2)} €',
                                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white54,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Netto: +${nettoRimanenteCard.toStringAsFixed(2)} €',
                                        style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Tasse: -${totaleAccantonareCard.toStringAsFixed(2)} €',
                                        style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(height: 10),
                                  Divider(color: Colors.white.withOpacity(0.12), height: 1),
                                  const SizedBox(height: 8),
                                  _buildRowDetail('Saldo INPS', '${inpsY.toStringAsFixed(2)} €', Colors.white70),
                                  const SizedBox(height: 2),
                                  _buildRowDetail('Saldo Imposta', '${impostaY.toStringAsFixed(2)} €', Colors.white70),
                                  const SizedBox(height: 2),
                                  _buildRowDetail('Totale Saldo', '${totaleTasseY.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                                  Divider(color: Colors.white.withOpacity(0.12), height: 10),
                                  _buildRowDetail('Acconto INPS', '${accontoInpsY1.toStringAsFixed(2)} €', Colors.white70),
                                  const SizedBox(height: 2),
                                  _buildRowDetail('Acconto Imposta', '${accontoImpostaY1.toStringAsFixed(2)} €', Colors.white70),
                                  const SizedBox(height: 2),
                                  _buildRowDetail('Totale Acconto', '${totaleAccontiY1.toStringAsFixed(2)} €', const Color(0xFFF97316)),
                                  Divider(color: Colors.white.withOpacity(0.12), height: 10),
                                  _buildRowDetail('Totale Tasse da Accantonare:', '-${totaleAccantonareCard.toStringAsFixed(2)} €', const Color(0xFF3B82F6), isBold: true),
                                  const SizedBox(height: 2),
                                  _buildRowDetail('Netto Rimanente Reale:', '+${nettoRimanenteCard.toStringAsFixed(2)} €', const Color(0xFF2DD4BF), isBold: true),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: InkWell(
                                      onTap: () => _confermaEliminazione(context, f),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          ),

          const SizedBox(height: 10),

          // 📌 SCHEDA RIEPILOGO IN BASSO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _meseSelezionato == 0
                          ? 'RIEPILOGO FISCALE COMPLETO'
                          : 'RIEPILOGO FISCALE (${_mesiStr[_meseSelezionato].toUpperCase()})',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Icon(Icons.analytics_outlined, color: Color(0xFF2DD4BF), size: 15),
                  ],
                ),
                const SizedBox(height: 6),
                _buildRowDetail('Totale Incassato Lordo:', '${lordoTotale.toStringAsFixed(2)} €', Colors.white, isBold: true),
                const SizedBox(height: 2),
                _buildRowDetail('Totale Saldo:', '-${totaleTasseY.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                const SizedBox(height: 2),
                _buildRowDetail('Totale Acconto:', '-${totaleAccontiY1.toStringAsFixed(2)} €', const Color(0xFFF97316)),
                Divider(color: Colors.white.withOpacity(0.15), height: 10),
                _buildRowDetail('Totale Tasse da Accantonare:', '-${grandTotaleAccantonare.toStringAsFixed(2)} €', const Color(0xFF3B82F6), isBold: true),
                const SizedBox(height: 2),
                _buildRowDetail('Totale Netto Rimanente:', '+${nettoTotaleRimanente.toStringAsFixed(2)} €', const Color(0xFF2DD4BF), isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white60,
              fontSize: 10,
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
            fontSize: 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}