import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/fluid_wave_painter.dart';
import '1_main_menu.dart';
import '../widgets_shared/fiscon_logo.dart';
import '../data/ateco_database.dart'; // 👈 IMPORT DEL DATABASE CENTRALIZZATO!

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  late AnimationController _waveController;
  final ScrollController _scrollController = ScrollController();

  // 🗂️ STEP 1: PROFILO & ATECO
  String? tipoProfilo; // 'piva' o 'dipendente'
  String? aliquotaTasse; // '5%' o '15%'
  int? annoAperturaPiva; 
  double? coefficienteRedditivita;
  String? codiceAtecoSelezionato;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🗂️ STEP 2: CONTRIBUTI & ACCONTI
  String? tipoLavoroDipendente; // 'nessuno', 'full', 'part_over50', 'part_under50'
  final TextEditingController _accontiController = TextEditingController();

  // 🗂️ STEP 3: OBIETTIVO NETTO
  final TextEditingController _nettoTargetController = TextEditingController(text: '2000');

  // 🗂️ STEP 4: PROIEZIONE, MESI & VERDETTO
  final TextEditingController _fatturatoController = TextEditingController(text: '35000');
  
  // Lista dei 12 mesi (tutti attivi di default)
  final List<String> _nomiMesi = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
  final List<bool> _mesiAttiviState = List.generate(12, (_) => true);

  int get _mesiAttiviConteggio => _mesiAttiviState.where((m) => m).length;

  // 👇 RIMOSSA LA VECCHIA LISTA _databaseAteco
  // Ora useremo AtecoDatabase.lista

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
    _pageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _accontiController.dispose();
    _nettoTargetController.dispose();
    _fatturatoController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (tipoProfilo == 'dipendente' || _currentPage == _totalPages - 1) {
      _concludiOnboarding();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _concludiOnboarding() {
    final wallet = context.read<WalletProvider>();
    
    if (tipoProfilo == 'dipendente') {
      wallet.setPartitaIVA(false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenu(hasPartitaIva: false)));
    } else {
      wallet.setPartitaIVA(true);
      
      // 📌 ESTRAIAMO SOLO IL CODICE NUMERICO PULITO (es. "74.10.21")
      final String codicePulito = (codiceAtecoSelezionato ?? '74.10.21').split(' ').first.trim();

      wallet.salvaProfiloFiscale(
        codiceAteco: codicePulito,
        coeffRedditivitaVal: coefficienteRedditivita ?? 0.78,
        aliquotaImpostaVal: aliquotaTasse == '5%' ? 0.05 : 0.15,
        accontiVersati: double.tryParse(_accontiController.text) ?? 0.0,
        nettoTarget: double.tryParse(_nettoTargetController.text) ?? 2000.0,
        fatturatoStimato: double.tryParse(_fatturatoController.text) ?? 35000.0,
        mesiAttivi: _mesiAttiviConteggio > 0 ? _mesiAttiviConteggio : 12,
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainMenu(
            hasPartitaIva: true,
            codiceAtecoIniziale: codicePulito,
            coefficienteIniziale: coefficienteRedditivita ?? 0.78,
            aliquotaImpostaIniziale: aliquotaTasse == '5%' ? 0.05 : 0.15,
          ),
        ),
      );
    }
  }

  // 🧮 CALCOLO VERDETTO & SUGGERIMENTI
  Map<String, double> _calcolaVerdetto() {
    final double fatturato = double.tryParse(_fatturatoController.text) ?? 0.0;
    final double nettoTargetMese = double.tryParse(_nettoTargetController.text) ?? 0.0;
    final double coeff = coefficienteRedditivita ?? 0.78;
    final double aliquota = (aliquotaTasse == '5%') ? 0.05 : 0.15;
    
    // Esenzione o riduzione INPS se dipendente Full-Time o Part-Time > 50%
    final double aliquotaInps = (tipoLavoroDipendente == 'full' || tipoLavoroDipendente == 'part_over50') ? 0.0 : 0.2607;

    final double imponibile = fatturato * coeff;
    final double tasseAnno = imponibile * aliquota;
    final double inpsAnno = imponibile * aliquotaInps;
    final double nettoAnno = fatturato - tasseAnno - inpsAnno;
    final double nettoMeseReale = nettoAnno / 12;

    final double gapMese = nettoTargetMese - nettoMeseReale;
    
    double extraFatturatoAnno = 0.0;
    if (gapMese > 0) {
      final double fattoreNetto = 1 - (coeff * (aliquota + aliquotaInps));
      extraFatturatoAnno = (gapMese * 12) / (fattoreNetto > 0 ? fattoreNetto : 1.0);
    }

    return {
      'nettoMese': nettoMeseReale,
      'gapMese': gapMese,
      'extraFatturatoAnno': extraFatturatoAnno,
      'extraFatturatoMese': _mesiAttiviConteggio > 0 ? extraFatturatoAnno / _mesiAttiviConteggio : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF080B0C),
        resizeToAvoidBottomInset: true,
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
              child: Column(
                children: [
                  // HEADER & PROGRESS BAR
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const FiscOnLogo(fontSize: 26),
                          ],
                        ),
                        if (tipoProfilo == 'piva')
                          Text('Step ${_currentPage + 1} di $_totalPages', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  if (tipoProfilo == 'piva')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / _totalPages,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                          minHeight: 4,
                        ),
                      ),
                    ),

                  // SCHERMATE PAGEVIEW
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int page) => setState(() => _currentPage = page),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                        _buildStep3(),
                        _buildStep4(),
                      ],
                    ),
                  ),

                  // BOTTOM BAR CON TASTI
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [const Color(0xFF080B0C), const Color(0xFF080B0C).withOpacity(0.0)],
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_currentPage > 0 && tipoProfilo == 'piva')
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: InkWell(
                              onTap: _prevPage,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 54,
                                width: 54,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF1F2937)),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              ),
                            ),
                          ),
                        
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: (tipoProfilo == null || (tipoProfilo == 'piva' && coefficienteRedditivita == null && _currentPage == 0)) ? null : _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2DD4BF),
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: const Color(0xFF1F2937),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tipoProfilo == 'dipendente' ? 'Home Dipendente' 
                                    : (_currentPage == _totalPages - 1 ? 'Scopri il tuo Verdetto' : 'Avanti'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(tipoProfilo == 'dipendente' || _currentPage == _totalPages - 1 ? Icons.check_circle : Icons.arrow_forward_rounded, size: 18),
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
          ],
        ),
      ),
    );
  }

  // STEP 1: PROFILO & ATECO
  Widget _buildStep1() {
    final atecoFiltrati = AtecoDatabase.lista.where((item) {
      final query = _searchQuery.toLowerCase().replaceAll('.', '').trim();
      return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(query) || 
             item['descrizione'].toString().toLowerCase().contains(query);
    }).toList();

    // Generiamo gli anni selezionabili (ultimi 5 anni + opzione "> 5 anni fa")
    final int annoCorrente = DateTime.now().year;
    final List<int> anniApertura = List.generate(5, (index) => annoCorrente - index);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual è il tuo profilo lavorativo?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildProfileCard(id: 'piva', icon: Icons.badge_rounded, title: 'Partita IVA', subtitle: 'Forfettario', activeColor: const Color(0xFF0D9488))),
              const SizedBox(width: 12),
              Expanded(child: _buildProfileCard(id: 'dipendente', icon: Icons.work_rounded, title: 'Dipendente', subtitle: 'Privato', activeColor: const Color(0xFF3B82F6))),
            ],
          ),
          
          if (tipoProfilo == 'piva') ...[
            const SizedBox(height: 28),
            const Text('IN CHE ANNO HAI APERTO LA PARTITA IVA?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            
            // CHIP SELEZIONE ANNO DI APERTURA
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...anniApertura.map((anno) {
                  final isSelected = annoAperturaPiva == anno;
                  return ChoiceChip(
                    label: Text(
                      anno == annoCorrente ? '$anno (Quest\'anno)' : '$anno',
                      style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2DD4BF),
                    backgroundColor: const Color(0xFF101618),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF1F2937)),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        annoAperturaPiva = anno;
                        aliquotaTasse = '5%'; // Entro i 5 anni -> default 5%
                      });
                      _scrollToBottom();
                    },
                  );
                }),
                ChoiceChip(
                label: Text(
                  '${annoCorrente - 5} o prima (> 5 anni)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                selected: annoAperturaPiva != null && annoAperturaPiva! <= (annoCorrente - 5),
                selectedColor: const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFF101618),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: (annoAperturaPiva != null && annoAperturaPiva! <= (annoCorrente - 5)) ? const Color(0xFF3B82F6) : const Color(0xFF1F2937)),
                ),
                onSelected: (selected) {
                  setState(() {
                    annoAperturaPiva = annoCorrente - 5;
                    aliquotaTasse = '15%';
                  });
                  _scrollToBottom();
                },
              ),
              ],
            ),

            // BOX INFO ALIQUOTA AUTOMATICA
            if (annoAperturaPiva != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101618),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          aliquotaTasse == '5%' ? Icons.eco_rounded : Icons.work_outline_rounded,
                          color: aliquotaTasse == '5%' ? const Color(0xFF2DD4BF) : const Color(0xFF3B82F6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          aliquotaTasse == '5%' ? 'Aliquota Agevolata Startup (5%)' : 'Aliquota Standard (15%)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      annoAperturaPiva == 2021
                          ? 'Avendo aperto da oltre 5 anni, la tua imposta sostitutiva è passata alla misura standard del 15%.'
                          : 'Sei nei primi 5 anni di attività: hai diritto al 5% (a meno che tu non abbia aperto senza requisiti startup; in tal caso seleziona 15% qui sotto).',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                    if (annoAperturaPiva != 2021) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => aliquotaTasse = (aliquotaTasse == '5%' ? '15%' : '5%')),
                            child: Text(
                              aliquotaTasse == '5%' ? 'Non ho requisiti startup -> Passa al 15%' : 'Torna al 5% Startup',
                              style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            if (aliquotaTasse != null) ...[
              const SizedBox(height: 32),
              const Text('CERCA O SELEZIONA CODICE ATECO PRINCIPALE', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              _buildCustomTextField(
                controller: _searchController,
                hintText: 'es. 855209 o professione...',
                icon: Icons.search_rounded,
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101618).withOpacity(0.88), 
                  borderRadius: BorderRadius.circular(24), 
                  border: Border.all(color: const Color(0xFF1F2937))
                ),
                // 🧠 LOGICA SMART: Se la barra è vuota mostra i Top 3, altrimenti cerca su Firebase!
                child: _searchQuery.isEmpty
                    ? Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 8),
                            child: Text('🔥 I PIÙ SCELTI IN ITALIA', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                          _buildRevolutListTile(
                            icon: Icons.laptop_mac_rounded, 
                            title: 'Consulenza & Digital (78%)', 
                            subtitle: 'Es. 74.10.21 - IT, Marketing, Design', 
                            isSelected: codiceAtecoSelezionato?.startsWith('74.10.21') ?? false, 
                            onTap: () => _selectAtecoPreset(0.78, '74.10.21 - Consulenza & Digital')
                          ),
                          const Divider(height: 1, color: Color(0xFF1F2937), indent: 64),
                          _buildRevolutListTile(
                            icon: Icons.storefront_rounded, 
                            title: 'Commercio & E-commerce (40%)', 
                            subtitle: 'Es. 47.91.10 - Vendita online, Dropshipping', 
                            isSelected: codiceAtecoSelezionato?.startsWith('47.91.10') ?? false, 
                            onTap: () => _selectAtecoPreset(0.40, '47.91.10 - Commercio & E-commerce')
                          ),
                          const Divider(height: 1, color: Color(0xFF1F2937), indent: 64),
                          _buildRevolutListTile(
                            icon: Icons.build_rounded, 
                            title: 'Artigiani & Ristorazione (40%)', 
                            subtitle: 'Es. 56.10.11 - Produzione, Bar, Parrucchieri', 
                            isSelected: codiceAtecoSelezionato?.startsWith('56.10.11') ?? false, 
                            onTap: () => _selectAtecoPreset(0.40, '56.10.11 - Artigiani & Ristorazione')
                          ),
                        ],
                      )
                    : (atecoFiltrati.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20), 
                            child: Center(child: Text('Nessun codice ATECO trovato', style: TextStyle(color: Colors.white54, fontSize: 12)))
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: atecoFiltrati.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF1F2937), indent: 16),
                            itemBuilder: (context, index) {
                              final item = atecoFiltrati[index];
                              final isSelected = codiceAtecoSelezionato != null && codiceAtecoSelezionato!.startsWith(item['codice'].toString());
                              final double coef = (item['coef'] as num).toDouble();

                              return Container(
                                color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.12) : Colors.transparent,
                                child: ListTile(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    setState(() {
                                      coefficienteRedditivita = coef;
                                      codiceAtecoSelezionato = '${item['codice']} - ${item['descrizione']}';
                                    });
                                    _scrollToBottom();
                                  },
                                  title: Row(
                                    children: [
                                      Text(item['codice'], style: TextStyle(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                                        decoration: BoxDecoration(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF1F2937), borderRadius: BorderRadius.circular(6)), 
                                        child: Text('${(coef * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(item['descrizione'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 22) : const Icon(Icons.circle_outlined, color: Colors.white24, size: 20),
                                ),
                              );
                            }
                          )
                      ),
                  ),
                ],
              ],
            ],
          ),
        );
      }

  void _selectAtecoPreset(double coef, String str) {
    setState(() {
      coefficienteRedditivita = coef;
      codiceAtecoSelezionato = str;
    });
    _scrollToBottom();
  }

  // STEP 2: CONTRIBUTI & ACCONTI F24
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Situazione Contributiva', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Oltre alla P.IVA, hai un contratto da dipendente?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 20),
          
          _buildRevolutListTile(icon: Icons.close_rounded, title: 'No, solo Partita IVA', subtitle: 'Lavoro in proprio al 100%', isSelected: tipoLavoroDipendente == 'nessuno', onTap: () => setState(() => tipoLavoroDipendente = 'nessuno')),
          const SizedBox(height: 8),
          _buildRevolutListTile(icon: Icons.work, title: 'Sì, Full-Time', subtitle: 'Esenzione contributi INPS P.IVA', isSelected: tipoLavoroDipendente == 'full', onTap: () => setState(() => tipoLavoroDipendente = 'full')),
          const SizedBox(height: 8),
          _buildRevolutListTile(icon: Icons.timelapse_rounded, title: 'Sì, Part-Time', subtitle: 'Riduzione contributi INPS', isSelected: tipoLavoroDipendente == 'part_over50' || tipoLavoroDipendente == 'part_under50', onTap: () => setState(() => tipoLavoroDipendente = 'part_over50')),
          
          if (tipoLavoroDipendente == 'part_over50' || tipoLavoroDipendente == 'part_under50') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0D9488).withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dettaglio Part-Time', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildProfileCard(id: 'part_over50', icon: Icons.keyboard_double_arrow_up_rounded, title: 'Più del 50%', subtitle: 'Es. > 20h', activeColor: const Color(0xFF0D9488), groupValue: tipoLavoroDipendente, onChanged: (v) => setState(() => tipoLavoroDipendente = v))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildProfileCard(id: 'part_under50', icon: Icons.keyboard_double_arrow_down_rounded, title: 'Fino al 50%', subtitle: 'Es. <= 20h', activeColor: const Color(0xFF3B82F6), groupValue: tipoLavoroDipendente, onChanged: (v) => setState(() => tipoLavoroDipendente = v))),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          const Text('IL TUO GRUZZOLETTO (F24 ANNO SCORSO)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: _accontiController,
            hintText: 'Es. 1500 (Lascia 0 se è il 1° anno)',
            icon: Icons.savings_rounded,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // STEP 3: OBIETTIVO NETTO
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Obiettivo di Vita', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Qual è lo stipendio netto mensile di cui hai bisogno per vivere sereno?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 32),
          
          Center(
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF101618), border: Border.all(color: const Color(0xFF2DD4BF), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)]),
              child: Column(
                children: [
                  const Text('NETTO TARGET', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _nettoTargetController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(bottom: 6.0, left: 4.0), child: Text('€', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 24, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Center(child: Text('L\'app utilizzerà questo valore per calcolare\nla sostenibilità delle tue entrate.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))),
        ],
      ),
    );
  }

  // STEP 4: PROIEZIONE, MESI ATTIVI & VERDETTO INTELLIGENTE
  Widget _buildStep4() {
    final verdetto = _calcolaVerdetto();
    final double nettoMese = verdetto['nettoMese']!;
    final double gapMese = verdetto['gapMese']!;
    final double extraFatturatoAnno = verdetto['extraFatturatoAnno']!;
    final double extraFatturatoMese = verdetto['extraFatturatoMese']!;
    final double nettoTargetMese = double.tryParse(_nettoTargetController.text) ?? 2000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proiezione & Verdetto', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Stima gli incassi lordi da P.IVA e seleziona i mesi di lavoro.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 24),
          
          const Text('FATTURATO LORDO P.IVA STIMATO', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          const Text('Inserisci solo il lordo P.IVA (escludi lo stipendio da dipendente)', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          const SizedBox(height: 8),
          _buildCustomTextField(
            controller: _fatturatoController,
            hintText: 'Es. 35000',
            icon: Icons.trending_up_rounded,
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() {}),
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MESI DI ATTIVITÀ / INCASSO', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Text('$_mesiAttiviConteggio / 12 Mesi', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(12, (index) {
              final isSelected = _mesiAttiviState[index];
              return ChoiceChip(
                label: Text(_nomiMesi[index], style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                selectedColor: const Color(0xFF2DD4BF),
                backgroundColor: const Color(0xFF101618),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF1F2937),
                  ),
                ),                onSelected: (bool selected) {
                  setState(() {
                    _mesiAttiviState[index] = selected;
                  });
                },
              );
            }),
          ),

          const SizedBox(height: 32),
          
          // CARD VERDETTO FINALE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF101618),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gapMese <= 0 ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      gapMese <= 0 ? '🎉 Sostenibile!' : '⚠️ Attenzione al Target',
                      style: TextStyle(color: gapMese <= 0 ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Icon(gapMese <= 0 ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: gapMese <= 0 ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Netto Mensile Stimato:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('${nettoMese.toStringAsFixed(0)} € / mese', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFF1F2937)),
                
                if (gapMese <= 0)
                  Text(
                    'Il tuo fatturato stimato ti permette di superare il tuo obiettivo netto mensile di ${nettoTargetMese.toStringAsFixed(0)} €!',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  )
                else ...[
                  Text(
                    'Ti mancano circa ${gapMese.toStringAsFixed(0)} € netti al mese per raggiungere il tuo obiettivo di ${nettoTargetMese.toStringAsFixed(0)} €.',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Text('SUGGERIMENTI DI INTEGRATIVI:', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.add_chart_rounded, color: Color(0xFF2DD4BF), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Incrementa il Fatturato P.IVA di +${extraFatturatoAnno.toStringAsFixed(0)} €/anno (+${extraFatturatoMese.toStringAsFixed(0)} € nei ${_mesiAttiviConteggio} mesi attivi)',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.work_outline_rounded, color: Color(0xFF3B82F6), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Oppure integra +${gapMese.toStringAsFixed(0)} € netti/mese da un lavoro Dipendente',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // COMPONENTI GRAFICI RIUTILIZZABILI
  Widget _buildCustomTextField({required TextEditingController controller, required String hintText, required IconData icon, Function(String)? onChanged, TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFF101618).withOpacity(0.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1F2937))),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onChanged: onChanged,
        decoration: InputDecoration(icon: Icon(icon, color: const Color(0xFF9CA3AF)), hintText: hintText, hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14), border: InputBorder.none),
      ),
    );
  }

  Widget _buildProfileCard({required String id, required IconData icon, required String title, required String subtitle, required Color activeColor, String? groupValue, Function(String)? onChanged}) {
    final bool isSelected = (groupValue ?? tipoProfilo) == id;
    return GestureDetector(
      onTap: () => (onChanged != null) ? onChanged(id) : setState(() => tipoProfilo = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? activeColor.withOpacity(0.15) : const Color(0xFF101618), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? activeColor : const Color(0xFF1F2937), width: isSelected ? 2 : 1)),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 32),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderQuickAction({required IconData icon, required String label, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(duration: const Duration(milliseconds: 150), width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.white : const Color(0xFF101618), border: Border.all(color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF1F2937), width: 2)), child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 26)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF9CA3AF), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRevolutListTile({required IconData icon, required String title, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.1) : const Color(0xFF101618), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF1F2937))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF1F2937)), child: Icon(icon, color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}