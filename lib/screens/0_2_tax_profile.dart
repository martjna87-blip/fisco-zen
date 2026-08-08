// 📍 INIZIO CODICE NUOVO FILE: lib/screens/0_2_tax_profile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/fluid_wave_painter.dart';

class TaxProfileScreen extends StatefulWidget {
  const TaxProfileScreen({super.key});

  @override
  State<TaxProfileScreen> createState() => _TaxProfileScreenState();
}

class _TaxProfileScreenState extends State<TaxProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _mostraCalcoloF24 = false;

  final Color coloreSfondo = const Color(0xFF080B0C);
  final Color coloreCard = const Color(0xFF101618);
  final Color coloreOttanio = const Color(0xFF2DD4BF);
  final Color coloreOro = const Color(0xFFF59E0B);
  final Color coloreBlu = const Color(0xFF3B82F6);

  // 📚 DATABASE ATECO INTEGRATO CON COEFFICIENTI FISSI
  static final List<Map<String, dynamic>> _databaseAteco = [
    {'codice': '85.52.09', 'descrizione': 'Formazione culturale e corsi', 'coef': 0.78},
    {'codice': '62.01.00', 'descrizione': 'Sviluppo software e programmazione', 'coef': 0.78},
    {'codice': '70.22.09', 'descrizione': 'Consulenza imprenditoriale e gestionale', 'coef': 0.78},
    {'codice': '73.11.02', 'descrizione': 'Marketing, Social Media e Advertising', 'coef': 0.78},
    {'codice': '74.10.21', 'descrizione': 'Graphic design, Web design, UI/UX', 'coef': 0.78},
    {'codice': '47.91.10', 'descrizione': 'Commercio al dettaglio (E-commerce)', 'coef': 0.67},
    {'codice': '56.10.11', 'descrizione': 'Ristoranti, Pizzerie, Bar', 'coef': 0.40},
    {'codice': '96.02.01', 'descrizione': 'Saloni di barbiere e parrucchiere', 'coef': 0.40},
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // 🛠️ FORMATTATORE VALUTA ITALIANO CON DECIMALICOERENTI IN TUTTA L'APP
  static String formattaEuro(double valore) {
    List<String> parti = valore.toStringAsFixed(2).split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String interiFormattati = parti[0].replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$interiFormattati,${parti[1]} €';
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final int annoCorrente = DateTime.now().year;

    final double fatturatoReale = walletProvider.fatturatoTotale;
    final double fatturatoStimato = walletProvider.fatturatoStimato;
    
    final double percReale = (fatturatoReale / 85000.0).clamp(0.0, 1.0);
    final double percStimata = (fatturatoStimato / 85000.0).clamp(0.0, 1.0);

    final int annoApertura = walletProvider.annoAperturaPiva ?? annoCorrente;
    final int anniTrascorsi = (annoCorrente - annoApertura) + 1;
    final int anniRimanenti5percento = (5 - anniTrascorsi).clamp(0, 5);
    final bool isAliquotaStartup = walletProvider.aliquotaImposta == 0.05;

    final double imponibileReale = fatturatoReale * walletProvider.coeffRedditivita;
    final double inpsReale = imponibileReale * walletProvider.aliquotaInps;
    final double impostaReale = imponibileReale * walletProvider.aliquotaImposta;
    final double tasseAnnoCorrenteReali = inpsReale + impostaReale;

    final double accontoAnnoSuccessivo = tasseAnnoCorrenteReali * 1.0;
    final double accontiGiaVersati = walletProvider.accontiVersati;
    final double totaleF24Stimato = (tasseAnnoCorrenteReali + accontoAnnoSuccessivo - accontiGiaVersati).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: coloreSfondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Centro Fiscale P.IVA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(painter: FluidWavePainter(animationValue: _waveController.value));
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 📋 PARAMETRI DI CALCOLO IN USO
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PARAMETRI DI CALCOLO IN USO', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        const SizedBox(height: 12),
                        _buildInfoRiga(Icons.work_outline_rounded, 'Codice ATECO', walletProvider.codiceAteco),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRiga(Icons.pie_chart_outline_rounded, 'Coeff. Redditività', '${(walletProvider.coeffRedditivita * 100).toInt()}% (Automatico)'),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRiga(Icons.badge_outlined, 'Lavoro Dipendente', _formattaDipendente(walletProvider.tipoLavoroDipendente)),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRiga(Icons.account_balance_rounded, 'Cassa / Previdenza', walletProvider.tipoLavoroDipendente == 'full' ? 'Esenzione INPS (Full-time)' : '26,07% Gestione Separata'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📊 SOGLIA FORFETTARIO (85.000,00 €)
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SOGLIA FORFETTARIO (${formattaEuro(85000)})', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: fatturatoReale > 85000 ? Colors.redAccent.withOpacity(0.15) : coloreOttanio.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                fatturatoReale > 85000 ? '⚠️ Fuori Soglia' : '✅ In Regola',
                                style: TextStyle(color: fatturatoReale > 85000 ? Colors.redAccent : coloreOttanio, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Incassato Reale (Fatture):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(formattaEuro(fatturatoReale), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percReale,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(coloreOttanio),
                            minHeight: 6,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Proiezione Stimata Anno:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(formattaEuro(fatturatoStimato), style: TextStyle(color: coloreOro, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percStimata,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(coloreOro.withOpacity(0.7)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🚀 CONTO ALLA ROVESCIA STARTUP
                  _buildCardWrapper(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAliquotaStartup ? coloreOro.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAliquotaStartup ? Icons.rocket_launch_rounded : Icons.history_rounded,
                            color: isAliquotaStartup ? coloreOro : Colors.white38,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAliquotaStartup ? 'Aliquota Startup 5%' : 'Aliquota Standard 15%',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAliquotaStartup && anniRimanenti5percento > 0
                                    ? 'P.IVA aperta nel $annoApertura. Ti rimangono ancora $anniRimanenti5percento anni al 5%!'
                                    : 'Aliquota ordinaria al 15% attiva o in passaggio.',
                                style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🏛️ CALCOLO F24 ON-DEMAND
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SITUAZIONE F24 SU FATTURE REALI', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: coloreBlu.withOpacity(0.15), shape: BoxShape.circle),
                              child: Icon(Icons.savings_rounded, color: coloreBlu, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(formattaEuro(accontiGiaVersati), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  const Text('Acconti già versati nell\'F24 dell\'anno scorso', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),

                        InkWell(
                          onTap: () => setState(() => _mostraCalcoloF24 = !_mostraCalcoloF24),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: coloreOttanio.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: coloreOttanio.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_mostraCalcoloF24 ? Icons.visibility_off_rounded : Icons.calculate_rounded, color: coloreOttanio, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      _mostraCalcoloF24 ? 'Nascondi Calcolo F24' : 'Simula F24 su Incassato Reale',
                                      style: TextStyle(color: coloreOttanio, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Icon(_mostraCalcoloF24 ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: coloreOttanio, size: 18),
                              ],
                            ),
                          ),
                        ),

                        if (_mostraCalcoloF24) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                _buildF24Riga('Tasse Reali (Fatture Incassate)', '+ ${formattaEuro(tasseAnnoCorrenteReali)}'),
                                const SizedBox(height: 6),
                                _buildF24Riga('Acconto Stimato Anno Successivo (100%)', '+ ${formattaEuro(accontoAnnoSuccessivo)}'),
                                const SizedBox(height: 6),
                                _buildF24Riga('Detrazione Acconti Anno Scorso', '- ${formattaEuro(accontiGiaVersati)}', isDetrazione: true),
                                const Divider(color: Colors.white24, height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('TOTALE F24 AD OGGI:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text(formattaEuro(totaleF24Stimato), style: TextStyle(color: coloreOttanio, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✏️ PULSANTE MODIFICA COMPLETA
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _apriModaleModificaCompleta(context, walletProvider),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Modifica Dati Fiscali P.IVA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coloreOttanio,
                        foregroundColor: coloreSfondo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _buildInfoRiga(IconData icona, String titolo, String valore) {
    return Row(
      children: [
        Icon(icona, color: Colors.white54, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(titolo, style: const TextStyle(color: Colors.white54, fontSize: 12))),
        Text(valore, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildF24Riga(String titolo, String valore, {bool isDetrazione = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(titolo, style: const TextStyle(color: Colors.white54, fontSize: 11))),
        Text(valore, style: TextStyle(color: isDetrazione ? Colors.redAccent : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formattaDipendente(String? tipo) {
    switch (tipo) {
      case 'full': return 'Sì (Full-time)';
      case 'part_over50': return 'Sì (Part-time > 50%)';
      case 'part_under50': return 'Sì (Part-time ≤ 50%)';
      default: return 'No (Solo P.IVA)';
    }
  }

  void _apriModaleModificaCompleta(BuildContext context, WalletProvider provider) {
    Map<String, dynamic> atecoSelezionato = _databaseAteco.firstWhere(
      (element) => provider.codiceAteco.startsWith(element['codice'].toString()),
      orElse: () => _databaseAteco.first,
    );

    final TextEditingController searchCtrl = TextEditingController();
    final TextEditingController accontiCtrl = TextEditingController(text: provider.accontiVersati.toStringAsFixed(0));
    final TextEditingController fatturatoCtrl = TextEditingController(text: provider.fatturatoStimato.toStringAsFixed(0));
    final TextEditingController annoCtrl = TextEditingController(text: (provider.annoAperturaPiva ?? DateTime.now().year).toString());

    double tempImposta = provider.aliquotaImposta;
    bool mostraListaAteco = false;
    String queryFiltro = '';

    AppPopupWrapper.mostra(
      context: context,
      child: Material(
        color: const Color(0xFF1F2428),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final listaFiltrata = _databaseAteco.where((item) {
                final q = queryFiltro.toLowerCase().replaceAll('.', '').trim();
                return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(q) ||
                       item['descrizione'].toString().toLowerCase().contains(q);
              }).toList();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📍 INIZIO MODIFICA: Tasto X sulla Sinistra
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aggiorna Dati Fiscali P.IVA',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Seleziona il tuo ATECO: il coefficiente verrà calcolato in automatico.',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                    _buildInputLabel('CODICE ATECO & MANSIONE PRINCIPALE'),
                    GestureDetector(
                      onTap: () => setModalState(() => mostraListaAteco = !mostraListaAteco),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: coloreOttanio.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.style_rounded, color: coloreOttanio, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${atecoSelezionato['codice']} - ${atecoSelezionato['descrizione']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('Coeff. Redditività: ${(atecoSelezionato['coef'] * 100).toInt()}%', style: TextStyle(color: coloreOttanio, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Icon(mostraListaAteco ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                    if (mostraListaAteco) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12181B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: searchCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              onChanged: (v) => setModalState(() => queryFiltro = v),
                              decoration: InputDecoration(
                                hintText: 'Cerca codice ATECO o mansione...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 180),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: listaFiltrata.length,
                                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                                itemBuilder: (context, idx) {
                                  final item = listaFiltrata[idx];
                                  final isSel = item['codice'] == atecoSelezionato['codice'];

                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    onTap: () {
                                      setModalState(() {
                                        atecoSelezionato = item;
                                        mostraListaAteco = false;
                                      });
                                    },
                                    title: Text('${item['codice']} - ${item['descrizione']}', style: TextStyle(color: isSel ? coloreOttanio : Colors.white70, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                    subtitle: Text('Coeff: ${(item['coef'] * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                    trailing: isSel ? Icon(Icons.check_circle_rounded, color: coloreOttanio, size: 18) : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('COEFF. REDDITIVITÀ (%)'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${(atecoSelezionato['coef'] * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('ANNO APERTURA P.IVA'),
                              _buildModalTextField(annoCtrl, '2024', isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    _buildInputLabel('ALIQUOTA IMPOSTA SOSTITUTIVA'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => tempImposta = 0.05),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tempImposta == 0.05 ? coloreOttanio.withOpacity(0.2) : Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tempImposta == 0.05 ? coloreOttanio : Colors.white10),
                              ),
                              child: Center(
                                child: Text('5% Startup', style: TextStyle(color: tempImposta == 0.05 ? coloreOttanio : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => tempImposta = 0.15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tempImposta == 0.15 ? coloreOttanio.withOpacity(0.2) : Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tempImposta == 0.15 ? coloreOttanio : Colors.white10),
                              ),
                              child: Center(
                                child: Text('15% Standard', style: TextStyle(color: tempImposta == 0.15 ? coloreOttanio : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    _buildInputLabel('ACCONTI F24 ANNO PRECEDENTE (€)'),
                    _buildModalTextField(accontiCtrl, '1.500', isNumber: true),

                    const SizedBox(height: 14),
                    _buildInputLabel('FATTURATO LORDO STIMATO ANNO CORRENTE (€)'),
                    _buildModalTextField(fatturatoCtrl, '35.000', isNumber: true),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final double coeff = (atecoSelezionato['coef'] as num).toDouble();
                          final double acconti = double.tryParse(accontiCtrl.text.replaceAll('.', '')) ?? 0.0;
                          final double fatturato = double.tryParse(fatturatoCtrl.text.replaceAll('.', '')) ?? 35000.0;
                          final int anno = int.tryParse(annoCtrl.text) ?? DateTime.now().year;

                          provider.salvaProfiloFiscale(
                            codiceAteco: '${atecoSelezionato['codice']} - ${atecoSelezionato['descrizione']}',
                            coeffRedditivitaVal: coeff,
                            aliquotaImpostaVal: tempImposta,
                            accontiVersati: acconti,
                            fatturatoStimato: fatturato,
                            annoAperturaPiva: anno,
                          );

                          Navigator.pop(context);
                          AppNotifications.mostraInAlto(
                            context,
                            'Dati e parametri fiscali aggiornati! ✅',
                            type: NotificationType.success,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: coloreOttanio,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Salva Parametri', style: TextStyle(color: Color(0xFF12181B), fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildModalTextField(TextEditingController controller, String hint, {bool isNumber = false, String? suffix}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}
// 📍 FINE CODICE NUOVO FILE: lib/screens/0_2_tax_profile.dart