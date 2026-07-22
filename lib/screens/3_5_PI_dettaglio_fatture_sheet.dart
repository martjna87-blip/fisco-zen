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
  String _meseSelezionato = 'Anno';

  final List<String> _mesi = [
    'Anno', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
  ];

  bool _isFatturaNelMese(Map<String, dynamic> f, String mese) {
    if (mese == 'Anno') return true;
    final dataStr = (f['data'] as String).toLowerCase();
    final mapMesi = {
      'Gen': ['gen', '/01/'], 'Feb': ['feb', '/02/'], 'Mar': ['mar', '/03/'],
      'Apr': ['apr', '/04/'], 'Mag': ['mag', '/05/'], 'Giu': ['giu', '/06/'],
      'Lug': ['lug', '/07/'], 'Ago': ['ago', '/08/'], 'Set': ['set', '/09/'],
      'Ott': ['ott', '/10/'], 'Nov': ['nov', '/11/'], 'Dic': ['dic', '/12/'],
    };
    final chiavi = mapMesi[mese] ?? [];
    for (var k in chiavi) {
      if (dataStr.contains(k)) return true;
    }
    if (dataStr.contains('oggi') && mese == 'Lug') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final fattureFiltrate = widget.fattureIncassate.where((f) => _isFatturaNelMese(f, _meseSelezionato)).toList();

    double totaleLordoPeriodo = 0;
    double totaleInpsPeriodo = 0;
    double totaleImpostaPeriodo = 0;

    for (var f in fattureFiltrate) {
      final double lordo = (f['importo'] as double);
      final double imponibile = lordo * widget.coefficienteRedditivita;
      totaleLordoPeriodo += lordo;
      totaleInpsPeriodo += imponibile * widget.aliquotaInps;
      totaleImpostaPeriodo += imponibile * widget.aliquotaImposta;
    }

    final double totaleTassePeriodo = totaleInpsPeriodo + totaleImpostaPeriodo;
    final double totaleNettoPeriodo = totaleLordoPeriodo - totaleTassePeriodo;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: screenHeight * 0.82,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=1000&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.40), Colors.black.withOpacity(0.85)],
                  ),
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 18),
              child: Container(
                height: screenHeight * 0.78,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417).withOpacity(0.72),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Text('Dettaglio Fiscale Fatture', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4BF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                          ),
                          child: Text('Coeff. ${(widget.coefficienteRedditivita * 100).toInt()}%', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _mesi.length,
                        itemBuilder: (context, index) {
                          final m = _mesi[index];
                          final bool isSelected = m == _meseSelezionato;
                          return GestureDetector(
                            onTap: () => setState(() => _meseSelezionato = m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2DD4BF) : Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white12),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: fattureFiltrate.isEmpty
                          ? Center(
                              child: Text(_meseSelezionato == 'Anno' ? 'Nessuna fattura incassata.' : 'Nessun incasso a $_meseSelezionato.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: fattureFiltrate.length,
                              itemBuilder: (context, index) {
                                final f = fattureFiltrate[index];
                                final double lordo = (f['importo'] as double);
                                final double imponibile = lordo * widget.coefficienteRedditivita;
                                final double inpsY = imponibile * widget.aliquotaInps;
                                final double impostaY = imponibile * widget.aliquotaImposta;
                                final double totaleTasseY = inpsY + impostaY;
                                final double netto = lordo - totaleTasseY;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${f['cliente']} (${f['numero']})', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                          Text('+${lordo.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      _row('INPS (Y)', '${inpsY.toStringAsFixed(2)} €'),
                                      _row('Imposta (Y)', '${impostaY.toStringAsFixed(2)} €'),
                                      const Divider(color: Colors.white12, height: 10),
                                      _row('Totale Tasse:', '${totaleTasseY.toStringAsFixed(2)} €', color: const Color(0xFFF59E0B), isBold: true),
                                      _row('Netto Rimanente:', '${netto.toStringAsFixed(2)} €', color: const Color(0xFF10B981), isBold: true),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_meseSelezionato == 'Anno' ? 'RIEPILOGO ANNUO' : 'RIEPILOGO MESE DI $_meseSelezionato'.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              const Icon(Icons.analytics_outlined, color: Color(0xFF2DD4BF), size: 16),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _row('Totale Incassato Lordo:', '${totaleLordoPeriodo.toStringAsFixed(2)} €', isBold: true),
                          _row('Totale Tasse:', '${totaleTassePeriodo.toStringAsFixed(2)} €', color: const Color(0xFFF59E0B)),
                          const Divider(color: Colors.white24, height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Totale Netto Rimanente:', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('${totaleNettoPeriodo.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(color: isBold ? Colors.white70 : Colors.white54, fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(v, style: TextStyle(color: color ?? (isBold ? Colors.white : Colors.white.withOpacity(0.8)), fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}