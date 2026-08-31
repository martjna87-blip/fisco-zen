import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/fluid_wave_painter.dart';
import '../widgets_shared/f24_facsimile_sheet.dart';
import '../widgets_shared/app_bottom_sheet.dart';

class TaxProfileScreen extends StatefulWidget {
  const TaxProfileScreen({super.key});

  static String formattaEuro(double valore) {
    List<String> parti = valore.toStringAsFixed(2).split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String interiFormattati = parti[0].replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$interiFormattati,${parti[1]} €';
  }

  @override
  State<TaxProfileScreen> createState() => _TaxProfileScreenState();
}

class _TaxProfileScreenState extends State<TaxProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _mostraCalcoloF24 = false;

  final Color coloreSfondo  = const Color(0xFF080B0C);
  final Color coloreCard    = const Color(0xFF101618);
  final Color coloreOttanio = const Color(0xFF2DD4BF);
  final Color coloreOro     = const Color(0xFFF59E0B);
  final Color coloreBlu     = const Color(0xFF38BDF8);

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

  static final List<String> _nomiMesi = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  static String _formattaInt(num valore) {
    final int val = valore.round().abs();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return val.toString().replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

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

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final int annoCorrente = DateTime.now().year;

    final double fatturatoReale = walletProvider.fatturatoTotale;
    final double fatturatoStimato = walletProvider.fatturatoStimato;
    final double sogliaLimiteReale = walletProvider.sogliaForfettarioReale;

    final double percReale = (fatturatoReale / sogliaLimiteReale).clamp(0.0, 1.0);
    final double percStimata = (fatturatoStimato / sogliaLimiteReale).clamp(0.0, 1.0);

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

    final bool isNuovaApertura = annoApertura == annoCorrente;

    return Scaffold(
      backgroundColor: coloreSfondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Centro Fiscale & Obiettivi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  
                  // ✏️ AZIONE RAPIDA IN ALTO: SCHEDA MODIFICA PROFILO & OBIETTIVI
                  _buildCardWrapper(
                    child: InkWell(
                      onTap: () => _apriModaleModificaCompleta(context, walletProvider),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: coloreOttanio.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: coloreOttanio.withOpacity(0.4)),
                            ),
                            child: Icon(Icons.tune_rounded, color: coloreOttanio, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Modifica Profilo & Obiettivi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.edit_note_rounded, color: coloreOttanio, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ricalibra target netto, fatturato P.IVA e mesi di lavoro',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🎯 OBIETTIVI UTENTE & RISORSE (TARGET "VOGLIO" + EXTRA)
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OBIETTIVO PERSONALE & ENTRATE EXTRA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        const SizedBox(height: 12),
                        _buildInfoRiga(Icons.track_changes_rounded, 'Target Netto ("Voglio")', '${TaxProfileScreen.formattaEuro(walletProvider.nettoTargetMensile)} / mese'),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRiga(
                          Icons.badge_outlined, 
                          'Lavoro Dipendente / Pensione', 
                          walletProvider.hasDipendente 
                              ? '${TaxProfileScreen.formattaEuro(walletProvider.entrataExtraMensile)}/mese (${walletProvider.numeroMensilitaExtra} mensilità)' 
                              : (walletProvider.hasPensione ? 'Pensione Attiva' : 'No (Solo P.IVA)')
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📋 PARAMETRI DI CALCOLO P.IVA IN USO
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DATI FISCALI P.IVA IN USO', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        const SizedBox(height: 12),
                        _buildInfoRiga(Icons.work_outline_rounded, 'Codice ATECO', walletProvider.codiceAteco),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRiga(Icons.pie_chart_outline_rounded, 'Coeff. Redditività', '${(walletProvider.coeffRedditivita * 100).toInt()}%'),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRiga(
                          Icons.calendar_today_rounded, 
                          'Anno Apertura / Mesi ON', 
                          '$annoApertura • ${walletProvider.mesiAttivi} Mesi Lavorativi Attivi'
                        ),
                        const Divider(color: Colors.white10, height: 20),
                        _buildInfoRiga(
                          Icons.account_balance_rounded, 
                          'Cassa / Previdenza', 
                          walletProvider.hasDipendente ? '24,00% INPS (Aliquota Ridotta Dipendenti)' : '26,07% Gestione Separata INPS'
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📊 SOGLIA FORFETTARIO RAGGUAGLIATA CON BADGE CLICCABILE
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'SOGLIA FORFETTARIO (${TaxProfileScreen.formattaEuro(sogliaLimiteReale)})',
                                style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _mostraSpiegazioneSoglia(context, fatturatoReale, sogliaLimiteReale),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: fatturatoReale > sogliaLimiteReale ? Colors.redAccent.withOpacity(0.15) : coloreOttanio.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: fatturatoReale > sogliaLimiteReale ? Colors.redAccent.withOpacity(0.4) : coloreOttanio.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      fatturatoReale > sogliaLimiteReale ? '⚠️ Fuori Soglia' : '✅ In Regola',
                                      style: TextStyle(color: fatturatoReale > sogliaLimiteReale ? Colors.redAccent : coloreOttanio, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.info_outline_rounded, color: fatturatoReale > sogliaLimiteReale ? Colors.redAccent : coloreOttanio, size: 12),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isNuovaApertura) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Soglia calcolata in proporzione ai mesi attivi (${_nomiMesi[(walletProvider.meseAperturaPiva ?? 1) - 1]} - Dicembre)',
                            style: TextStyle(color: coloreOttanio, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Incassato Reale (Fatture):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(TaxProfileScreen.formattaEuro(fatturatoReale), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
                            Text(TaxProfileScreen.formattaEuro(fatturatoStimato), style: TextStyle(color: coloreOro, fontSize: 13, fontWeight: FontWeight.bold)),
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
                                  Text(TaxProfileScreen.formattaEuro(accontiGiaVersati), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                          onTap: () {
                            AppBottomSheet.mostra(
                              context: context,
                              child: const F24FacsimileSheet(),
                            );
                          },
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
                                _buildF24Riga('Tasse Reali (Fatture Incassate)', '+ ${TaxProfileScreen.formattaEuro(tasseAnnoCorrenteReali)}'),
                                const SizedBox(height: 6),
                                _buildF24Riga('Acconto Stimato Anno Successivo (100%)', '+ ${TaxProfileScreen.formattaEuro(accontoAnnoSuccessivo)}'),
                                const SizedBox(height: 6),
                                _buildF24Riga('Detrazione Acconti Anno Scorso', '- ${TaxProfileScreen.formattaEuro(accontiGiaVersati)}', isDetrazione: true),
                                const Divider(color: Colors.white24, height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('TOTALE F24 AD OGGI:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text(TaxProfileScreen.formattaEuro(totaleF24Stimato), style: TextStyle(color: coloreOttanio, fontSize: 16, fontWeight: FontWeight.bold)),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icona, color: Colors.white54, size: 16),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Text(
            titolo,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            valore,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildF24Riga(String titolo, String valore, {bool isDetrazione = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(titolo, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            valore,
            textAlign: TextAlign.end,
            style: TextStyle(color: isDetrazione ? Colors.redAccent : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _mostraSpiegazioneSoglia(BuildContext context, double incassato, double soglia) {
    final bool superato = incassato > soglia;

    AppPopupWrapper.mostra(
      context: context,
      child: Material(
        color: const Color(0xFF1F2428),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(superato ? Icons.warning_amber_rounded : Icons.verified_user_rounded, color: superato ? Colors.redAccent : coloreOttanio, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        superato ? 'Attenzione: Soglia Superata' : 'Regime Forfettario in Regola',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Cosa prevede la legge per le soglie del Forfettario:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              
              _buildSogliaRuleRow(
                '1. Soglia Ragguagliata (${TaxProfileScreen.formattaEuro(soglia)})',
                'Se superi questa cifra entro i 100.000,00 €, rimani in Forfettario fino a fine anno, ma dal 1° Gennaio dell\'anno successivo passerai al Regime Ordinario.',
                coloreOro,
              ),
              const SizedBox(height: 12),
              _buildSogliaRuleRow(
                '2. Soglia Critica (100.000,00 €)',
                'Se superi i 100.000,00 € durante l\'anno, l\'uscita dal Forfettario è immediata: da quella fattura dovrai applicare l\'IVA ed esser tassato in Regime Ordinario.',
                Colors.redAccent,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coloreOttanio,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ho Capito', style: TextStyle(color: Color(0xFF12181B), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSogliaRuleRow(String titolo, String spiegazione, Color colore) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colore.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titolo, style: TextStyle(color: colore, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(spiegazione, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }

 // 📍 MODALE RESTYLING MINIMALE & NON INVASIVO
  void _apriModaleModificaCompleta(BuildContext context, WalletProvider provider) {
    Map<String, dynamic> atecoSelezionato = _databaseAteco.firstWhere(
      (element) => provider.codiceAteco.startsWith(element['codice'].toString()),
      orElse: () => _databaseAteco.first,
    );

    final TextEditingController searchCtrl = TextEditingController();
    final TextEditingController accontiCtrl = TextEditingController(text: _formattaInt(provider.accontiVersati));
    final TextEditingController fatturatoCtrl = TextEditingController(text: _formattaInt(provider.fatturatoStimato));
    final TextEditingController annoCtrl = TextEditingController(text: (provider.annoAperturaPiva ?? DateTime.now().year).toString());
    final TextEditingController targetNettoCtrl = TextEditingController(text: _formattaInt(provider.nettoTargetMensile));
    final TextEditingController entrataExtraCtrl = TextEditingController(text: _formattaInt(provider.entrataExtraMensile));
    
    List<bool> mesiAttiviLocal = List.from(provider.mesiAttiviState);
    double tempImposta = provider.aliquotaImposta;
    int tempMeseApertura = provider.meseAperturaPiva ?? 1;
    int tempMensilitaExtra = provider.numeroMensilitaExtra;
    bool mostraListaAteco = false;
    String queryFiltro = '';

    const Color tealBrand = Color(0xFF2DD4BF);
    const Color cardBg = Color(0xFF151A1E);

    AppPopupWrapper.mostra(
      context: context,
      child: Material(
        color: const Color(0xFF1B2026),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final int annoInserito = int.tryParse(annoCtrl.text) ?? DateTime.now().year;
              final bool isAnnoCorrente = annoInserito == DateTime.now().year;

              final listaFiltrata = _databaseAteco.where((item) {
                final q = queryFiltro.toLowerCase().replaceAll('.', '').trim();
                return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(q) ||
                       item['descrizione'].toString().toLowerCase().contains(q);
              }).toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔝 HEADER ESSENZIALE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profilo & Obiettivi',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 📜 SCHEDE COMPATTE SCORREVOLI
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // 🎯 CARD 1: OBIETTIVO PERSONALE
                          _buildModalSectionCard(
                            title: 'OBIETTIVO NETTO',
                            icon: Icons.track_changes_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('QUANTO VUOI IN TASCA OGNI MESE?'),
                                _buildModalTextField(targetNettoCtrl, '2.500', suffix: '€ / mese', isNumber: true, formatThousands: true),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 🏛️ CARD 2: FISCO & P.IVA
                          _buildModalSectionCard(
                            title: 'PARTITA IVA',
                            icon: Icons.badge_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('ATECO PRINCIPALE'),
                                GestureDetector(
                                  onTap: () => setModalState(() => mostraListaAteco = !mostraListaAteco),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${atecoSelezionato['codice']} • ${atecoSelezionato['descrizione']}',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(mostraListaAteco ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: tealBrand, size: 18),
                                      ],
                                    ),
                                  ),
                                ),

                                if (mostraListaAteco) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF101418),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: searchCtrl,
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                          onChanged: (v) => setModalState(() => queryFiltro = v),
                                          decoration: InputDecoration(
                                            hintText: 'Cerca ATECO...',
                                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 16),
                                            filled: true,
                                            fillColor: Colors.black.withOpacity(0.3),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxHeight: 140),
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            itemCount: listaFiltrata.length,
                                            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                                            itemBuilder: (context, idx) {
                                              final item = listaFiltrata[idx];
                                              final isSel = item['codice'] == atecoSelezionato['codice'];

                                              return ListTile(
                                                dense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                                onTap: () {
                                                  setModalState(() {
                                                    atecoSelezionato = item;
                                                    mostraListaAteco = false;
                                                  });
                                                },
                                                title: Text('${item['codice']} - ${item['descrizione']}', style: TextStyle(color: isSel ? tealBrand : Colors.white70, fontSize: 11)),
                                                trailing: isSel ? const Icon(Icons.check_rounded, color: tealBrand, size: 16) : null,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInputLabel('ANNO APERTURA'),
                                          _buildModalTextField(
                                            annoCtrl,
                                            '2025',
                                            isNumber: true,
                                            onChanged: (val) => setModalState(() {}),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInputLabel('ACCONTI F24 ANNO SCORSO'),
                                          _buildModalTextField(accontiCtrl, '0', suffix: '€', isNumber: true, formatThousands: true),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                _buildInputLabel('FATTURATO LORDO PREVISTO ANNO'),
                                _buildModalTextField(fatturatoCtrl, '35.000', suffix: '€ / anno', isNumber: true, formatThousands: true),

                                const SizedBox(height: 12),
                                _buildInputLabel('ALIQUOTA FISCALE'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildPillToggle('5% Startup', tempImposta == 0.05, () => setModalState(() => tempImposta = 0.05)),
                                    const SizedBox(width: 8),
                                    _buildPillToggle('15% Standard', tempImposta == 0.15, () => setModalState(() => tempImposta = 0.15)),
                                  ],
                                ),

                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInputLabel('MESI LAVORATIVI P.IVA (ON / OFF)'),
                                    Text('${mesiAttiviLocal.where((m) => m).length}/12', style: const TextStyle(color: tealBrand, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // 🗓️ GRIGLIA COMPATTA MESI
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: List.generate(12, (index) {
                                    final nomiShort = ['GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU', 'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'];
                                    final bool isAttivo = mesiAttiviLocal[index];
                                    return GestureDetector(
                                      onTap: () => setModalState(() => mesiAttiviLocal[index] = !mesiAttiviLocal[index]),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 120),
                                        width: (MediaQuery.of(context).size.width - 82) / 4,
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isAttivo ? tealBrand.withOpacity(0.18) : Colors.white.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isAttivo ? tealBrand : Colors.white10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            nomiShort[index],
                                            style: TextStyle(
                                              color: isAttivo ? tealBrand : Colors.white38,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 💼 CARD 3: DIPENDENTE / PENSIONE
                          if (provider.hasDipendente || provider.hasPensione)
                            _buildModalSectionCard(
                              title: provider.hasDipendente ? 'STIPENDIO DIPENDENTE' : 'PENSIONE',
                              icon: Icons.work_outline_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInputLabel('NETTO MENSILE'),
_buildModalTextField(entrataExtraCtrl, '1.500', suffix: '€', isNumber: true, formatThousands: true),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInputLabel('MENSILITÀ'),
                                            Row(
                                              children: [12, 13, 14].map((m) {
                                                final bool isSel = tempMensilitaExtra == m;
                                                return Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => setModalState(() => tempMensilitaExtra = m),
                                                    child: Container(
                                                      margin: const EdgeInsets.only(right: 3),
                                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: isSel ? const Color(0xFF38BDF8).withOpacity(0.2) : Colors.black.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: isSel ? const Color(0xFF38BDF8) : Colors.white10),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '$m',
                                                          style: TextStyle(
                                                            color: isSel ? const Color(0xFF38BDF8) : Colors.white54,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final double coeff = (atecoSelezionato['coef'] as num).toDouble();
                        final double acconti = double.tryParse(accontiCtrl.text.replaceAll('.', '')) ?? 0.0;
                        final double fatturato = double.tryParse(fatturatoCtrl.text.replaceAll('.', '')) ?? 35000.0;
                        final int anno = int.tryParse(annoCtrl.text) ?? DateTime.now().year;
                        final String codiceCompleto = '${atecoSelezionato['codice']} - ${atecoSelezionato['descrizione']}';
                        final double target = double.tryParse(targetNettoCtrl.text.replaceAll('.', '')) ?? 2500.0;
                        final int mesi = mesiAttiviLocal.where((m) => m).length;
                        final double extra = double.tryParse(entrataExtraCtrl.text.replaceAll('.', '')) ?? provider.entrataExtraMensile;

                        _gestisciSalvataggioProfiloV12(
                          context: context,
                          provider: provider,
                          nuovoAteco: codiceCompleto,
                          nuovoCoeff: coeff,
                          nuovaAliquota: tempImposta,
                          acconti: acconti,
                          fatturato: fatturato,
                          annoApertura: anno,
                          meseApertura: tempMeseApertura,
                          targetNetto: target,
                          mesiAttivi: mesi,
                          mesiAttiviStateCustom: mesiAttiviLocal,
                          entrataExtra: extra,
                          numeroMensilita: tempMensilitaExtra,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealBrand,
                        foregroundColor: const Color(0xFF12181B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Salva Impostazioni 🎯', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // 🛠️ HELPER GRAFICI MINIMALI
  Widget _buildModalSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14191D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2DD4BF), size: 14),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPillToggle(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.18) : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white10),
          ),
          child: Center(
            child: Text(text, style: TextStyle(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildModalTextField(
    TextEditingController controller, 
    String hint, {
    bool isNumber = false, 
    bool formatThousands = false, 
    String? suffix, 
    Function(String)? onChanged
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      onChanged: (val) {
        // Formattazione Live Migliaia
        if (formatThousands && val.isNotEmpty) {
          String soloNumeri = val.replaceAll(RegExp(r'[^0-9]'), '');
          if (soloNumeri.isNotEmpty) {
            String formattato = _formattaInt(int.parse(soloNumeri));
            if (controller.text != formattato) {
              controller.value = TextEditingValue(
                text: formattato,
                selection: TextSelection.collapsed(offset: formattato.length),
              );
            }
          } else {
            controller.text = '';
          }
        }
        if (onChanged != null) onChanged(val);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🎯 SALVATAGGIO FINALE
  void _gestisciSalvataggioProfiloV12({
    required BuildContext context,
    required WalletProvider provider,
    required String nuovoAteco,
    required double nuovoCoeff,
    required double nuovaAliquota,
    required double acconti,
    required double fatturato,
    required int annoApertura,
    required int meseApertura,
    required double targetNetto,
    required int mesiAttivi,
    required List<bool> mesiAttiviStateCustom,
    required double entrataExtra,
    required int numeroMensilita,
  }) {
    provider.salvaProfiloFiscale(
      codiceAteco: nuovoAteco,
      coeffRedditivitaVal: nuovoCoeff,
      aliquotaImpostaVal: nuovaAliquota,
      accontiVersati: acconti,
      fatturatoStimato: fatturato,
      annoAperturaPiva: annoApertura,
      meseAperturaPiva: meseApertura,
      nettoTarget: targetNetto,
      mesiAttivi: mesiAttivi,
      mesiAttiviStateCustom: mesiAttiviStateCustom,
    );

    provider.salvaEntrateExtra(
      importoMensile: entrataExtra,
      dipendente: provider.hasDipendente,
      pensione: provider.hasPensione,
      numeroMensilita: numeroMensilita,
    );

    Navigator.pop(context);
    AppNotifications.mostraInAlto(context, 'Profilo Fiscale e Obiettivi aggiornati! ✨');
  }
}