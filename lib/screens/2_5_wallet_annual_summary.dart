import 'package:flutter/material.dart';


class AnnualSummarySheet extends StatefulWidget {
  const AnnualSummarySheet({super.key});

  @override
  State<AnnualSummarySheet> createState() => _AnnualSummarySheetState();
}

class _AnnualSummarySheetState extends State<AnnualSummarySheet> {
  final PageController _pageController = PageController(viewportFraction: 0.85, initialPage: 1);
  int _selectedYearIndex = 1; // 0: 2025, 1: 2026, 2: 2027

  final List<Map<String, dynamic>> _anniData = [
    {
      'anno': '2025',
      'risparmioNetto': 9840.00,
      'incassato': 33600.00,
      'speso': 23760.00,
      'bgImage': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800&auto=format&fit=crop',
      'storicoMesi': [
        {'mese': 'Gen', 'incassato': 2800.0, 'speso': 1900.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Feb', 'incassato': 2800.0, 'speso': 1850.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Mar', 'incassato': 2800.0, 'speso': 2100.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Apr', 'incassato': 2800.0, 'speso': 1780.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Mag', 'incassato': 2800.0, 'speso': 2300.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Giu', 'incassato': 3400.0, 'speso': 2150.0, 'pilotaggio': 2200.0, 'isPassato': true},
        {'mese': 'Lug', 'incassato': 2800.0, 'speso': 1950.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Ago', 'incassato': 2800.0, 'speso': 2600.0, 'pilotaggio': 2400.0, 'isPassato': true},
        {'mese': 'Set', 'incassato': 2800.0, 'speso': 1890.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Ott', 'incassato': 2800.0, 'speso': 1900.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Nov', 'incassato': 2800.0, 'speso': 2250.0, 'pilotaggio': 2100.0, 'isPassato': true},
        {'mese': 'Dic', 'incassato': 4200.0, 'speso': 3100.0, 'pilotaggio': 2800.0, 'isPassato': true},
      ],
    },
    {
      'anno': '2026',
      'risparmioNetto': 12450.00,
      'incassato': 37800.00,
      'speso': 25350.00,
      'bgImage': 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=800&auto=format&fit=crop',
      'storicoMesi': [
        {'mese': 'Gen', 'incassato': 2800.0, 'speso': 1850.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Feb', 'incassato': 2800.0, 'speso': 1920.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Mar', 'incassato': 3100.0, 'speso': 2500.0, 'pilotaggio': 2100.0, 'isPassato': true},
        {'mese': 'Apr', 'incassato': 2800.0, 'speso': 1600.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Mag', 'incassato': 2800.0, 'speso': 2400.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Giu', 'incassato': 3400.0, 'speso': 2150.0, 'pilotaggio': 2200.0, 'isPassato': true},
        {'mese': 'Lug', 'incassato': 2800.0, 'speso': 1950.0, 'pilotaggio': 2000.0, 'isPassato': true},
        {'mese': 'Ago', 'incassato': 2800.0, 'speso': 2400.0, 'pilotaggio': 2400.0, 'isPassato': false},
        {'mese': 'Set', 'incassato': 2800.0, 'speso': 2000.0, 'pilotaggio': 2000.0, 'isPassato': false},
        {'mese': 'Ott', 'incassato': 2800.0, 'speso': 2000.0, 'pilotaggio': 2000.0, 'isPassato': false},
        {'mese': 'Nov', 'incassato': 2800.0, 'speso': 2100.0, 'pilotaggio': 2100.0, 'isPassato': false},
        {'mese': 'Dic', 'incassato': 4200.0, 'speso': 2800.0, 'pilotaggio': 2800.0, 'isPassato': false},
      ],
    },
    {
      'anno': '2027 (Previsione)',
      'risparmioNetto': 14200.00,
      'incassato': 39000.00,
      'speso': 24800.00,
      'bgImage': 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?q=80&w=800&auto=format&fit=crop',
      'storicoMesi': [
        {'mese': 'Gen', 'incassato': 3200.0, 'speso': 2000.0, 'pilotaggio': 2100.0, 'isPassato': false},
        {'mese': 'Feb', 'incassato': 3200.0, 'speso': 1950.0, 'pilotaggio': 2100.0, 'isPassato': false},
      ],
    },
  ];

  void _mostraReportAnalitico(Map<String, dynamic> annoData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.analytics_rounded, color: Color(0xFF2DD4BF), size: 24),
            const SizedBox(width: 10),
            Text('Report ${annoData['anno']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SINTESI ANNUALE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildReportRow('Totale Entrate:', '+${annoData['incassato']} €', const Color(0xFF10B981)),
            const SizedBox(height: 6),
            _buildReportRow('Totale Spese:', '-${annoData['speso']} €', const Color(0xFFEF4444)),
            const SizedBox(height: 6),
            _buildReportRow('Risparmio Netto:', '+${annoData['risparmioNetto']} €', const Color(0xFF2DD4BF)),
            const Divider(color: Colors.white12, height: 24),

            const Text('TOP CATEGORIE SPESE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildReportCategory('Casa & Utenze', '8.400 €', '33%', const Color(0xFF2DD4BF)),
            const SizedBox(height: 6),
            _buildReportCategory('Svago & Viaggi', '5.200 €', '21%', const Color(0xFFF59E0B)),
            const SizedBox(height: 6),
            _buildReportCategory('Alimentari & Spesa', '4.100 €', '16%', const Color(0xFF3B82F6)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReportCategory(String name, String amount, String pct, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const Spacer(),
        Text('$amount ', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Text('($pct)', style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAnno = _anniData[_selectedYearIndex];
    final List<Map<String, dynamic>> storicoMesiInUso = List<Map<String, dynamic>>.from(currentAnno['storicoMesi']);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Il meglio per il tuo anno',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // 1. CAROSELLO HERO CARD
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _anniData.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedYearIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _anniData[index];
                  final bool isSelected = index == _selectedYearIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: isSelected ? 0 : 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      image: DecorationImage(
                        image: NetworkImage(item['bgImage']),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 10),

                          Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${item['risparmioNetto'].toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Risparmio Netto Accumulato', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  'Anno ${item['anno']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),

                          GestureDetector(
                            onTap: () => _mostraReportAnalitico(item),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C21).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 20),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Incassato', 
                                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '+${(item['incassato'] as double).toStringAsFixed(0)} €', 
                                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '-${(item['speso'] as double).toStringAsFixed(0)} €',
                                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white12, height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Visualizza report analitico',
                                        style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF2DD4BF), size: 12),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // 2. WIDGET GRAFICO DEDICATO CON LEGENDA E CURVA PILOTAGGIO GRIGIA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Questo anno hai speso...', 
                            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            _buildLegendaItem('Reale', const Color(0xFF2DD4BF)),
                            const SizedBox(width: 8),
                            _buildLegendaItem('Pilotaggio', Colors.white38),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(currentAnno['speso'] as double).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2DD4BF), size: 22),
                        Text('1.480 € vs target pilotaggio', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // GRAFICO CON PILOTAGGIO GRIGIO E REALE VERDE
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _FuturisticTrendPainter(datiMesi: storicoMesiInUso),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 3. STORICO MESI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'STORICO MESI (${currentAnno['anno']})',
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: storicoMesiInUso.length,
              itemBuilder: (context, index) {
                final m = storicoMesiInUso[index];
                final bool isPassato = m['isPassato'] == true;
                final double delta = m['pilotaggio'] - m['speso'];
                final bool isVirtuoso = delta >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPassato
                              ? (isVirtuoso ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12))
                              : Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPassato
                              ? (isVirtuoso ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded)
                              : Icons.schedule_rounded,
                          color: isPassato
                              ? (isVirtuoso ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                              : Colors.white38,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(m['mese'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                if (!isPassato) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Previsto', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPassato
                                  ? 'In: +${m['incassato'].toStringAsFixed(0)} € • Out: -${m['speso'].toStringAsFixed(0)} €'
                                  : 'Target Pilotaggio: ${m['pilotaggio'].toStringAsFixed(0)} €',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPassato
                            ? '${isVirtuoso ? '+' : ''}${delta.toStringAsFixed(0)} €'
                            : '${m['speso'].toStringAsFixed(0)} €',
                        style: TextStyle(
                          color: isPassato
                              ? (isVirtuoso ? const Color(0xFF2DD4BF) : const Color(0xFFEF4444))
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _FuturisticTrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> datiMesi;

  _FuturisticTrendPainter({required this.datiMesi});

  @override
  void paint(Canvas canvas, Size size) {
    if (datiMesi.isEmpty) return;

    final double heightGraph = size.height - 22;
    final double stepX = size.width / (datiMesi.length == 1 ? 1 : datiMesi.length - 1);

    List<Offset> puntiSpesoPassati = [];
    List<Offset> puntiPilotaggioTotali = [];
    List<Offset> puntiFuturi = [];

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < datiMesi.length; i++) {
      final double x = i * stepX;
      final double spesoVal = datiMesi[i]['speso'];
      final double pilotVal = datiMesi[i]['pilotaggio'];
      final bool isPassato = datiMesi[i]['isPassato'] == true;

      final double ySpeso = heightGraph - ((spesoVal / 3200.0) * heightGraph).clamp(0.0, heightGraph);
      final double yPilot = heightGraph - ((pilotVal / 3200.0) * heightGraph).clamp(0.0, heightGraph);

      final offsetSpeso = Offset(x, ySpeso);
      final offsetPilot = Offset(x, yPilot);

      puntiPilotaggioTotali.add(offsetPilot);

      if (isPassato) {
        puntiSpesoPassati.add(offsetSpeso);
      } else {
        if (puntiSpesoPassati.isNotEmpty && puntiFuturi.isEmpty) {
          puntiFuturi.add(puntiSpesoPassati.last);
        }
        puntiFuturi.add(offsetSpeso);
      }

      textPainter.text = TextSpan(
        text: datiMesi[i]['mese'],
        style: TextStyle(
          color: isPassato ? Colors.white70 : Colors.white24,
          fontSize: 9,
          fontWeight: isPassato ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2).clamp(0, x), heightGraph + 6));
    }

    // 1. CURVA PILOTAGGIO COMPLETA (GRIGIA E DISCRETA)
    if (puntiPilotaggioTotali.length >= 2) {
      final pathPilot = _creaPathMorbido(puntiPilotaggioTotali);
      final paintPilot = Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawPath(pathPilot, paintPilot);
    }

    // 2. CURVA REALE SPESA (VERDE SFUMATA PER I MESI PASSATI)
    if (puntiSpesoPassati.length >= 2) {
      final pathPassato = _creaPathMorbido(puntiSpesoPassati);

      final pathFillPassato = Path.from(pathPassato)
        ..lineTo(puntiSpesoPassati.last.dx, heightGraph)
        ..lineTo(puntiSpesoPassati.first.dx, heightGraph)
        ..close();

      final paintGradientPassato = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2DD4BF).withOpacity(0.4),
            const Color(0xFF2DD4BF).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, heightGraph));

      canvas.drawPath(pathFillPassato, paintGradientPassato);

      final paintLineaVerde = Paint()
        ..color = const Color(0xFF2DD4BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(pathPassato, paintLineaVerde);
    }

    // 3. CURVA FUTURA TRATTEGGIATA GRIGIA
    if (puntiFuturi.length >= 2) {
      final pathFuturo = _creaPathMorbido(puntiFuturi);

      final paintLineaFutura = Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      _disegnaLineaTratteggiata(canvas, pathFuturo, paintLineaFutura);
    }
  }

  Path _creaPathMorbido(List<Offset> punti) {
    final path = Path();
    if (punti.isEmpty) return path;

    path.moveTo(punti[0].dx, punti[0].dy);

    for (int i = 0; i < punti.length - 1; i++) {
      final p0 = punti[i];
      final p1 = punti[i + 1];

      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    return path;
  }

  void _disegnaLineaTratteggiata(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      const double dashWidth = 5.0;
      const double dashSpace = 4.0;

      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}