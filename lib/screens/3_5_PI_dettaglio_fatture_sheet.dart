import 'dart:ui';
import 'package:flutter/material.dart';

class DettaglioFattureSheet extends StatefulWidget {
  final List<Map<String, dynamic>> fattureIncassate;
  final double coefficienteRedditivita;
  final double aliquotaImposta;
  final double aliquotaInps;

  const DettaglioFattureSheet({
    super.key,
    required this.fattureIncassate,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calcolo Totali Fiscai
    double lordoTotale = 0.0;
    double inpsYTotale = 0.0;
    double impostaYTotale = 0.0;
    double accontoInpsY1Totale = 0.0;
    double accontoImpostaY1Totale = 0.0;

    for (var f in widget.fattureIncassate) {
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

              // 3. CONTENUTO ARTICOLATO IN 2 RIQUADRI GLASS
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
                                  child: widget.fattureIncassate.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Nessuna fattura incassata salvata.',
                                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                          ),
                                        )
                                      : ListView.builder(
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: widget.fattureIncassate.length,
                                          itemBuilder: (context, index) {
                                            final f = widget.fattureIncassate[index];
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
                                                      Text(
                                                        '+${lordo.toStringAsFixed(2)} €',
                                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildRowDetail('INPS Saldo (Y):', '${inpsY.toStringAsFixed(2)} €', Colors.white70),
                                                  const SizedBox(height: 2),
                                                  _buildRowDetail('Imposta Saldo (Y):', '${impostaY.toStringAsFixed(2)} €', Colors.white70),
                                                  const SizedBox(height: 2),
                                                  _buildRowDetail('Totale Saldo (Y):', '${totaleTasseY.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                                                  Divider(color: Colors.white.withOpacity(0.12), height: 10),
                                                  _buildRowDetail('Acconto INPS (Y+1) [80%]:', '${accontoInpsY1.toStringAsFixed(2)} €', Colors.white70),
                                                  const SizedBox(height: 2),
                                                  _buildRowDetail('Acconto Imposta (Y+1) [100%]:', '${accontoImpostaY1.toStringAsFixed(2)} €', Colors.white70),
                                                  const SizedBox(height: 2),
                                                  _buildRowDetail('Totale Acconti (Y+1):', '${totaleAccontiY1.toStringAsFixed(2)} €', const Color(0xFFF97316)),
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
                    // 🔲 RIQUADRO 2: RIEPILOGO FISCALE ANNUO
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
                                children: const [
                                  Text(
                                    'RIEPILOGO FISCALE COMPLETO',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Icon(Icons.analytics_outlined, color: Color(0xFF2DD4BF), size: 15),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildRowDetail('Totale Incassato Lordo:', '${lordoTotale.toStringAsFixed(2)} €', Colors.white, isBold: true),
                              const SizedBox(height: 2),
                              _buildRowDetail('Totale Saldo (Y):', '${totaleTasseY.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                              const SizedBox(height: 2),
                              _buildRowDetail('Totale Acconti (Y+1):', '${totaleAccontiY1.toStringAsFixed(2)} €', const Color(0xFFF97316)),
                              Divider(color: Colors.white.withOpacity(0.2), height: 10),
                              _buildRowDetail('Totale Tasse da Accantonare:', '${grandTotaleAccantonare.toStringAsFixed(2)} €', const Color(0xFFEF4444), isBold: true),
                              const SizedBox(height: 2),
                              _buildRowDetail('Totale Netto Rimanente:', '${nettoTotaleRimanente.toStringAsFixed(2)} €', const Color(0xFF2DD4BF), isBold: true),
                            ],
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