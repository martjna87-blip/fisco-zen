import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../screens/0_1_pro_upgrade.dart';

class AnnualSummarySheet extends StatefulWidget {
  const AnnualSummarySheet({super.key});

  @override
  State<AnnualSummarySheet> createState() => _AnnualSummarySheetState();
}

class _AnnualSummarySheetState extends State<AnnualSummarySheet> {
  final PageController _pageController = PageController(viewportFraction: 0.85, initialPage: 1);
  int _selectedYearIndex = 1; // 0: 2025, 1: 2026, 2: 2027

  // 🖼️ DATI DEMO ASPIRAZIONALI (VISIBILI SOLO AGLI UTENTI NON PRO)
  final List<Map<String, dynamic>> _anniDemoData = [
    {
      'anno': '2025',
      'risparmioNetto': 9840.00,
      'incassato': 33600.00,
      'speso': 23760.00,
      'bgImage': 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?q=80&w=800&auto=format&fit=crop',
      'storicoMesi': [
        {'mese': 'Gen', 'incassato': 2800.0, 'speso': 1900.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Feb', 'incassato': 2800.0, 'speso': 1850.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Mar', 'incassato': 2800.0, 'speso': 2100.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Apr', 'incassato': 2800.0, 'speso': 1780.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Mag', 'incassato': 2800.0, 'speso': 2300.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Giu', 'incassato': 3400.0, 'speso': 2150.0, 'budget': 2200.0, 'isPassato': true},
        {'mese': 'Lug', 'incassato': 2800.0, 'speso': 1950.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Ago', 'incassato': 2800.0, 'speso': 2600.0, 'budget': 2400.0, 'isPassato': true},
        {'mese': 'Set', 'incassato': 2800.0, 'speso': 1890.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Ott', 'incassato': 2800.0, 'speso': 1900.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Nov', 'incassato': 2800.0, 'speso': 2250.0, 'budget': 2100.0, 'isPassato': true},
        {'mese': 'Dic', 'incassato': 4200.0, 'speso': 3100.0, 'budget': 2800.0, 'isPassato': true},
      ],
    },
    {
      'anno': '2026',
      'risparmioNetto': 12450.00,
      'incassato': 37800.00,
      'speso': 25350.00,
      'bgImage': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
      'storicoMesi': [
        {'mese': 'Gen', 'incassato': 2800.0, 'speso': 1850.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Feb', 'incassato': 2800.0, 'speso': 1920.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Mar', 'incassato': 3100.0, 'speso': 2500.0, 'budget': 2100.0, 'isPassato': true},
        {'mese': 'Apr', 'incassato': 2800.0, 'speso': 1600.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Mag', 'incassato': 2800.0, 'speso': 2400.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Giu', 'incassato': 3400.0, 'speso': 2150.0, 'budget': 2200.0, 'isPassato': true},
        {'mese': 'Lug', 'incassato': 2800.0, 'speso': 1950.0, 'budget': 2000.0, 'isPassato': true},
        {'mese': 'Ago', 'incassato': 2800.0, 'speso': 2400.0, 'budget': 2400.0, 'isPassato': false},
        {'mese': 'Set', 'incassato': 2800.0, 'speso': 2000.0, 'budget': 2000.0, 'isPassato': false},
        {'mese': 'Ott', 'incassato': 2800.0, 'speso': 2000.0, 'budget': 2000.0, 'isPassato': false},
        {'mese': 'Nov', 'incassato': 2800.0, 'speso': 2100.0, 'budget': 2100.0, 'isPassato': false},
        {'mese': 'Dic', 'incassato': 4200.0, 'speso': 2800.0, 'budget': 2800.0, 'isPassato': false},
      ],
    },
    {
      'anno': '2027 (Previsione)',
      'risparmioNetto': 14200.00,
      'incassato': 39000.00,
      'speso': 24800.00,
      'bgImage': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=800&auto=format&fit=crop',
      'storicoMesi': [
        {'mese': 'Gen', 'incassato': 3200.0, 'speso': 2000.0, 'budget': 2100.0, 'isPassato': false},
        {'mese': 'Feb', 'incassato': 3200.0, 'speso': 1950.0, 'budget': 2100.0, 'isPassato': false},
      ],
    },
  ];

  // ⚡ CALCOLATORE DINAMICO DATI REALI (COLLEGATO A SPESE REALI + PIANIFICAZIONE SPESE)
  List<Map<String, dynamic>> _calcolaDatiReali(WalletProvider wallet) {
    final List<String> nomiMesiBrevi = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
    final DateTime ora = DateTime.now();

    final List<int> anni = [ora.year - 1, ora.year, ora.year + 1];
    final List<String> immagini = [
      'https://images.unsplash.com/photo-1499750310107-5fef28a66643?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=800&auto=format&fit=crop',
    ];

    return anni.asMap().entries.map((entry) {
      final int i = entry.key;
      final int anno = entry.value;

      double totIncassato = 0.0;
      double totSpeso = 0.0;

      final List<Map<String, dynamic>> storicoMesi = List.generate(12, (mIdx) {
        final int meseNum = mIdx + 1;
        final DateTime dtMese = DateTime(anno, meseNum);
        final bool isPassato = (anno < ora.year) || (anno == ora.year && meseNum <= ora.month);

        // 1. Transazioni reali registrate nel mese
        final txMese = wallet.transactions.where((t) => t.date.year == anno && t.date.month == meseNum);

        final double incassatoMese = txMese.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
        final double spesoMese = txMese.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

        // 2. Budget Obiettivo recuperato dalla Pianificazione Spese / Movimenti Previsti
        final previstiMese = wallet.getMovimentiPrevisti(dtMese);
        final double budgetObiettivoMese = previstiMese.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

        totIncassato += incassatoMese;
        totSpeso += spesoMese;

        return {
          'mese': nomiMesiBrevi[mIdx],
          'incassato': incassatoMese,
          'speso': spesoMese,
          // Se non ci sono spese previste, usiamo uno standard basato sullo speso
          'budget': budgetObiettivoMese > 0 ? budgetObiettivoMese : (spesoMese > 0 ? spesoMese * 1.05 : 2000.0),
          'isPassato': isPassato,
        };
      });

      final double risparmioNetto = totIncassato - totSpeso;

      return {
        'anno': anno == ora.year + 1 ? '$anno (Previsione)' : '$anno',
        'risparmioNetto': risparmioNetto,
        'incassato': totIncassato,
        'speso': totSpeso,
        'bgImage': immagini[i % immagini.length],
        'storicoMesi': storicoMesi,
      };
    }).toList();
  }

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(0).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${importo < 0 ? '-' : ''}$intPart €';
  }

  void _apriUpgradePro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProUpgradeSheet(
          funzionalita: 'Panoramica Annuale e Previsioni',
        ),
      ),
    );
  }

  void _mostraReportAnalitico(Map<String, dynamic> annoData) {
    final List<Map<String, dynamic>> mesi = List<Map<String, dynamic>>.from(annoData['storicoMesi']);
    final int mesiVirtuosi = mesi.where((m) => (m['isPassato'] == true) && ((m['budget'] as double) >= (m['speso'] as double))).length;
    final double mediaRisparmioMese = (annoData['risparmioNetto'] as double) / 12;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFF2DD4BF), size: 24),
            const SizedBox(width: 10),
            Text('Sintesi ${annoData['anno']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFF2DD4BF), size: 16),
                      const SizedBox(width: 8),
                      Text('Media Risparmiata: ${_formattaValuta(mediaRisparmioMese)}/mese', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 8),
                      Text('$mesiVirtuosi mesi sotto il budget previsto! 👏', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('BILANCIO ANNUALE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            _buildReportRow('Totale Incassato:', '+${_formattaValuta(annoData['incassato'])}', const Color(0xFF10B981)),
            const SizedBox(height: 6),
            _buildReportRow('Totale Speso:', '-${_formattaValuta(annoData['speso'])}', const Color(0xFFEF4444)),
            const SizedBox(height: 6),
            _buildReportRow('Risparmio Netto:', '+${_formattaValuta(annoData['risparmioNetto'])}', const Color(0xFF2DD4BF)),
            const Divider(color: Colors.white12, height: 24),

            const Text('SINTESI ANNUALE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            _buildReportCategory('Spese Totali', '${_formattaValuta(annoData['speso'])}', '100%', const Color(0xFF2DD4BF)),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
    final walletProvider = context.watch<WalletProvider>();
    final bool isUserPro = walletProvider.isPro; // 🔒 VERIFICA SE L'UTENTE È PRO

    // ⚡ SE L'UTENTE È PRO USA I DATI REALI AL 100%, ALTRIMENTI MOSTRA LA DEMO
    final List<Map<String, dynamic>> anniInUso = isUserPro 
        ? _calcolaDatiReali(walletProvider) 
        : _anniDemoData;

    final currentAnno = anniInUso[_selectedYearIndex.clamp(0, anniInUso.length - 1)];
    final List<Map<String, dynamic>> storicoMesiInUso = List<Map<String, dynamic>>.from(currentAnno['storicoMesi']);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Panoramica Annuale',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 BANNER SOLO PER UTENTI NON PRO
            if (!isUserPro) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: InkWell(
                  onTap: () => _apriUpgradePro(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B).withOpacity(0.2),
                          const Color(0xFF2DD4BF).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Anteprima Demo PRO • Tocca per attivare con i tuoi dati reali',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFF59E0B), size: 12),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // 1. CAROSELLO HERO CARD
            SizedBox(
              height: 410,
              child: PageView.builder(
                controller: _pageController,
                itemCount: anniInUso.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedYearIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = anniInUso[index];
                  final bool isSelected = index == _selectedYearIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: isSelected ? 0 : 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
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
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 6),

                          Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formattaValuta(item['risparmioNetto']),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Risparmio Netto Accumulato', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  'Anno ${item['anno']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),

                          GestureDetector(
                            onTap: () {
                              if (!isUserPro) {
                                _apriUpgradePro(context);
                              } else {
                                _mostraReportAnalitico(item);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C21).withOpacity(0.88),
                                borderRadius: BorderRadius.circular(20),
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
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 18),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Incassato', 
                                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '+${_formattaValuta(item['incassato'])}', 
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
                                        '-${_formattaValuta(item['speso'])}',
                                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isUserPro ? 'Vedi dettagli dell\'anno' : '🔒 Mostra i tuoi dati reali',
                                        style: TextStyle(
                                          color: isUserPro ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: isUserPro ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B),
                                        size: 11,
                                      ),
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

            const SizedBox(height: 16),

            // 🚀 PULSANTE DI UPGRADE PRO (VISIBILE SOLO SE NON È PRO)
            if (!isUserPro) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _apriUpgradePro(context),
                    icon: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 20),
                    label: const Text(
                      'Passa a PRO per Calcoli Reali',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 2. GRAFICO DEL BUDGET OBIETTIVO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(22),
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
                            'Uscite Totali dell\'Anno', 
                            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            _buildLegendaItem('Reale', const Color(0xFF2DD4BF)),
                            const SizedBox(width: 8),
                            _buildLegendaItem('Budget', Colors.white38),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattaValuta(currentAnno['speso']),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2DD4BF), size: 16),
                        SizedBox(width: 6),
                        Text('Analisi uscite calcolata 🎉', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _FuturisticTrendPainter(datiMesi: storicoMesiInUso),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. STORICO MESI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'STORICO MESE PER MESE (${currentAnno['anno']})',
                style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: storicoMesiInUso.length,
              itemBuilder: (context, index) {
                final m = storicoMesiInUso[index];
                final bool isPassato = m['isPassato'] == true;
                final double delta = (m['budget'] as double) - (m['speso'] as double);
                final bool isVirtuoso = delta >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(m['mese'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                if (!isPassato) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Previsto', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPassato
                                  ? 'In: +${_formattaValuta(m['incassato'])} • Out: -${_formattaValuta(m['speso'])}'
                                  : 'Budget Stimato: ${_formattaValuta(m['budget'])}',
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
                            ? '${isVirtuoso ? '+' : ''}${_formattaValuta(delta)}'
                            : _formattaValuta(m['speso']),
                        style: TextStyle(
                          color: isPassato
                              ? (isVirtuoso ? const Color(0xFF2DD4BF) : const Color(0xFFEF4444))
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
    List<Offset> puntiBudgetTotali = [];
    List<Offset> puntiFuturi = [];

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < datiMesi.length; i++) {
      final double x = i * stepX;
      final double spesoVal = datiMesi[i]['speso'];
      final double budgetVal = datiMesi[i]['budget'];
      final bool isPassato = datiMesi[i]['isPassato'] == true;

      final double ySpeso = heightGraph - ((spesoVal / 3200.0) * heightGraph).clamp(0.0, heightGraph);
      final double yBudget = heightGraph - ((budgetVal / 3200.0) * heightGraph).clamp(0.0, heightGraph);

      final offsetSpeso = Offset(x, ySpeso);
      final offsetBudget = Offset(x, yBudget);

      puntiBudgetTotali.add(offsetBudget);

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

    if (puntiBudgetTotali.length >= 2) {
      final pathBudget = _creaPathMorbido(puntiBudgetTotali);
      final paintBudget = Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawPath(pathBudget, paintBudget);
    }

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
            const Color(0xFF2DD4BF).withOpacity(0.35),
            const Color(0xFF2DD4BF).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, heightGraph));

      canvas.drawPath(pathFillPassato, paintGradientPassato);

      final paintLineaVerde = Paint()
        ..color = const Color(0xFF2DD4BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(pathPassato, paintLineaVerde);
    }

    if (puntiFuturi.length >= 2) {
      final pathFuturo = _creaPathMorbido(puntiFuturi);

      final paintLineaFutura = Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

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