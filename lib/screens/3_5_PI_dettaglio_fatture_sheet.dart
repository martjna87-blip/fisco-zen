import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

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
  int _meseSelezionato = 0; // 0 = Anno Intero, 1 = Gen, 2 = Feb, ecc.

  final List<String> _mesiStr = [
    'Anno', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giug',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
  ];

  // METODO PER MOSTRARE IL DIALOGO DI CONFERMA ED ELIMINARE ISTANTANEAMENTE
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
                // 1. Rimuovi dal Provider globale
                Provider.of<WalletProvider>(context, listen: false).eliminaFatturaPiva(id);
              }

              // 2. Chiudi modale di conferma
              Navigator.pop(ctx);

              // 3. Forza il refresh immediato del widget
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fattura di "${fattura['cliente']}" eliminata.'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // METODO FILTRO INTELLIGENTE PER I MESI
  List<Map<String, dynamic>> _getFattureFiltrate(List<Map<String, dynamic>> sorgenteFatture) {
    if (_meseSelezionato == 0) {
      return sorgenteFatture;
    }

    return sorgenteFatture.where((f) {
      // 1. Controlla se esiste un valore numerico 'mese'
      if (f['mese'] != null && f['mese'] is int) {
        return f['mese'] == _meseSelezionato;
      }

      // 2. Controlla il campo 'data'
      final rawData = f['data'];
      if (rawData != null) {
        if (rawData is DateTime) {
          return rawData.month == _meseSelezionato;
        }

        if (rawData is String) {
          // Prova ISO (es. "2026-05-18")
          final parsedIso = DateTime.tryParse(rawData);
          if (parsedIso != null) {
            return parsedIso.month == _meseSelezionato;
          }

          // Prova formato IT (es. "18/05/2026")
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final walletProvider = Provider.of<WalletProvider>(context);

    // LEGGI DIRETTAMENTE DAL PROVIDER PER AVERE AGGIORNAMENTI REALI IN TEMPO REALE
    final listaTutteIncassate = walletProvider.fattureIncassate;
    final fattureFiltrate = _getFattureFiltrate(listaTutteIncassate);

    // Calcolo Totali Fiscale sulla LISTA FILTRATA
    double lordoTotale = 0.0;
    double inpsYTotale = 0.0;
    double impostaYTotale = 0.0;
    double accontoInpsY1Totale = 0.0;
    double accontoImpostaY1Totale = 0.0;

    for (var f in fattureFiltrate) {
      final double lordo = (f['importo'] as num).toDouble();
      final double imponibile = lordo * widget.coefficienteRedditivita;
      
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: double.infinity,
          height: screenSize.height * 0.86,
          child: Stack(
            children: [
              // 1. IMMAGINE DI SFONDO ATMOSFERICA
              Positioned.fill(
                child: Image.network(
                  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),

              // 2. OVERLAY SCURO
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                ),
              ),

              // 3. CONTENUTO GLASS
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // --- HEADER & TITOLO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Dettaglio Fiscale',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4BF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.5)),
                          ),
                          child: Text(
                            'Coeff. ${(widget.coefficienteRedditivita * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF2DD4BF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // 🔲 RIQUADRO 1: LISTA FATTURE CON FILTRI
                    // ==========================================
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B).withOpacity(0.60),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Column(
                              children: [
                                // FILTRI MESI HORIZONTAL
                                SizedBox(
                                  height: 32,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
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

                                // LISTA FATTURE
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
                                            final double lordo = (f['importo'] as num).toDouble();
                                            final double imponibile = lordo * widget.coefficienteRedditivita;

                                            final double inpsY = imponibile * widget.aliquotaInps;
                                            final double impostaY = imponibile * widget.aliquotaImposta;
                                            final double totaleTasseY = inpsY + impostaY;
                                            
                                            final double accontoInpsY1 = inpsY * 0.80;
                                            final double accontoImpostaY1 = impostaY * 1.00;
                                            final double totaleAccontiY1 = accontoInpsY1 + accontoImpostaY1;

                                            final double totaleAccantonareCard = totaleTasseY + totaleAccontiY1;
                                            final double nettoRimanenteCard = lordo - totaleAccantonareCard;

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 10),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.4),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '${f['cliente']} (${f['numero'] ?? 'Fattura'})',
                                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '+${lordo.toStringAsFixed(2)} €',
                                                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                                                          ),
                                                          const SizedBox(width: 8),

                                                          // 🗑️ CESTINO CANCELLAZIONE ISTANTANEA
                                                          InkWell(
                                                            onTap: () => _confermaEliminazione(context, f),
                                                            borderRadius: BorderRadius.circular(8),
                                                            child: Container(
                                                              padding: const EdgeInsets.all(5),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFFEF4444).withOpacity(0.15),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
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
                                                  _buildRowDetail('Totale Tasse da Accantonare:', '${totaleAccantonareCard.toStringAsFixed(2)} €', const Color(0xFFEF4444), isBold: true),
                                                  const SizedBox(height: 2),
                                                  _buildRowDetail('Netto Rimanente Reale:', '${nettoRimanenteCard.toStringAsFixed(2)} €', const Color(0xFF2DD4BF), isBold: true),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // 🔲 RIQUADRO 2: RIEPILOGO FISCALE (FILTRATO)
                    // ==========================================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B).withOpacity(0.65),
                            borderRadius: BorderRadius.circular(22),
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
                              _buildRowDetail('Totale Saldo', '${totaleTasseY.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                              const SizedBox(height: 2),
                              _buildRowDetail('Totale Acconto', '${totaleAccontiY1.toStringAsFixed(2)} €', const Color(0xFFF97316)),
                              Divider(color: Colors.white.withOpacity(0.2), height: 10),
                              _buildRowDetail('Totale Tasse da Accantonare:', '${grandTotaleAccantonare.toStringAsFixed(2)} €', const Color(0xFFEF4444), isBold: true),
                              const SizedBox(height: 2),
                              _buildRowDetail('Totale Netto Rimanente:', '${nettoTotaleRimanente.toStringAsFixed(2)} €', const Color(0xFF2DD4BF), isBold: true),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // 🔲 RIQUADRO 3: TASTO CHIUDI BOTTOM GLASS
                    // ==========================================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B).withOpacity(0.65),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Annulla e Chiudi',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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