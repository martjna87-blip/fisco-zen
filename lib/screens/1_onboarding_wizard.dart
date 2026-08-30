import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/fluid_wave_painter.dart';
import '1_main_menu.dart';
import '../widgets_shared/fiscon_logo.dart';
import '../data/ateco_database.dart';

// Helper per la formattazione dei numeri con il punto per le migliaia (es. 8.000, 35.000)
String formatEuro(num value) {
  final int val = value.round().abs();
  final String str = val.toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  final String formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  return value < 0 ? '-$formatted' : formatted;
}

// Modello con ID immutabile per la gestione dei conti
class ContoItem {
  final String id;
  final String ruoloDefault; 
  final TextEditingController nomeController;
  final TextEditingController saldoController;

  ContoItem({
    required this.id,
    required this.ruoloDefault,
    required String nomeIniziale,
    required String saldoIniziale,
  })  : nomeController = TextEditingController(text: nomeIniziale),
        saldoController = TextEditingController(text: saldoIniziale);

  void dispose() {
    nomeController.dispose();
    saldoController.dispose();
  }
}

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _waveController;
  final ScrollController _pivaScrollController = ScrollController();

  // Palette Colori Coerente
  final Color bgDark = const Color(0xFF080B0C);
  final Color cardDark = const Color(0xFF101618);
  final Color borderDark = const Color(0xFF1F2937);
  final Color brandTeal = const Color(0xFF2DD4BF);
  final Color textMuted = const Color(0xFF6B7280);
  final Color textWhite = Colors.white;

  // 🎯 STEP 1: OBIETTIVO ENTRATA NETTA
  final TextEditingController _nettoTargetController = TextEditingController(text: '2500');

  // 🗂️ STEP 2: FONTI DI ENTRATA
  bool hasPiva = true;
  bool hasDipendente = false;
  bool hasPensione = false;

  // Dettagli Dipendente / Pensione
  final TextEditingController _dipendenteImportoController = TextEditingController(text: '1500');
  int mensilitaDipendente = 13;

  // Dettagli Partita IVA (ANNO E MESE NON PRESELEZIONATI)
  int? annoAperturaPiva; 
  int? meseAperturaPiva; 
  final TextEditingController _fatturatoController = TextEditingController(text: '35000');
  final List<String> _nomiMesiEstesi = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
  final List<bool> _mesiAttiviState = List.generate(12, (_) => true);
  
  // Dettagli ATECO
  double? coefficienteRedditivita = 0.78;
  String? codiceAtecoSelezionato = '74.10.21 - Design & Digital';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🗂️ FISCO
  String aliquotaTasse = '5%';
  String tipoLavoroDipendente = 'nessuno';
  final TextEditingController _accontiController = TextEditingController(text: '0');
  final TextEditingController _fatturatoAnnoPrecedenteController = TextEditingController(text: '0');
  bool fatturatoPrecedenteSuperava85k = false;

  // 🗂️ CONTI BANCARI
  final List<ContoItem> _contiList = [];

  int get _mesiAttiviConteggio => _mesiAttiviState.where((m) => m).length;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _contiList.add(ContoItem(id: 'main_account', ruoloDefault: 'principale', nomeIniziale: 'Conto Principale', saldoIniziale: '0'));
    _contiList.add(ContoItem(id: 'tax_account', ruoloDefault: 'tasse', nomeIniziale: 'Salvadanaio Tasse', saldoIniziale: '0'));
    _contiList.add(ContoItem(id: 'savings_account', ruoloDefault: 'risparmio', nomeIniziale: 'Fondo Risparmio', saldoIniziale: '0'));
  }

  void _aggiungiNuovoConto() {
    setState(() {
      final int idx = _contiList.length + 1;
      _contiList.add(ContoItem(id: 'extra_$idx', ruoloDefault: 'extra', nomeIniziale: 'Nuovo Conto', saldoIniziale: '0'));
    });
  }

  void _rimuoviConto(int index) {
    final item = _contiList[index];
    if (item.id != 'main_account' && item.id != 'tax_account') {
      setState(() {
        item.dispose();
        _contiList.removeAt(index);
      });
    }
  }

  void _scrollToPivaBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_pivaScrollController.hasClients) {
        _pivaScrollController.animateTo(
          _pivaScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // 🔍 VALIDAZIONE RIGIDA PER OGNI STEP
  bool _canProceed() {
    int idx = 0;
    final int currentYear = DateTime.now().year;

    // Step 1: Obiettivo Mensile
    if (_currentPage == idx) {
      final val = double.tryParse(_nettoTargetController.text.replaceAll('.', ''));
      return val != null && val > 0;
    }
    idx++;

    // Step 2: Selezione Fonti
    if (_currentPage == idx) {
      return hasPiva || hasDipendente || hasPensione;
    }
    idx++;

    // Step opzionale: Dipendente / Pensione
    if (hasDipendente || hasPensione) {
      if (_currentPage == idx) {
        final val = double.tryParse(_dipendenteImportoController.text.replaceAll('.', ''));
        return val != null && val > 0;
      }
      idx++;
    }

    // Step opzionali: Partita IVA
    if (hasPiva) {
      // Step: P.IVA Dettagli
      if (_currentPage == idx) {
        final fatt = double.tryParse(_fatturatoController.text.replaceAll('.', ''));
        if (fatt == null || fatt <= 0) return false;
        if (annoAperturaPiva == null) return false;
        if (annoAperturaPiva == currentYear && meseAperturaPiva == null) return false;
        if (_mesiAttiviConteggio == 0) return false;
        return true;
      }
      idx++;

      // Step: P.IVA Ateco
      if (_currentPage == idx) {
        return codiceAtecoSelezionato != null && codiceAtecoSelezionato!.isNotEmpty;
      }
      idx++;

      // Step: Inquadramento Fiscale
      if (_currentPage == idx) {
        final acc = double.tryParse(_accontiController.text.replaceAll('.', ''));
        return acc != null && acc >= 0;
      }
      idx++;
    }

    // Step: Conti Bancari
    if (_currentPage == idx) {
      for (var conto in _contiList) {
        if (conto.nomeController.text.trim().isEmpty) return false;
        if (double.tryParse(conto.saldoController.text.replaceAll('.', '')) == null) return false;
      }
      return true;
    }
    idx++;

    // Step Finale: Esito Analisi
    return true;
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pageController.dispose();
    _pivaScrollController.dispose();
    _nettoTargetController.dispose();
    _dipendenteImportoController.dispose();
    _fatturatoController.dispose();
    _searchController.dispose();
    _accontiController.dispose();
    _fatturatoAnnoPrecedenteController.dispose();
    for (var conto in _contiList) {
      conto.dispose();
    }
    super.dispose();
  }

  List<Widget> _getDynamicPages() {
    List<Widget> pages = [
      _buildStep1ObiettivoSleek(),
      _buildStep2SelezioneFontiSleek(),
    ];

    if (hasDipendente || hasPensione) pages.add(_buildStepDipendenteDettagliSleek());
    if (hasPiva) {
      pages.add(_buildStepPivaDettagliSleek());
      pages.add(_buildStepPivaAtecoSleek());
      pages.add(_buildStepInquadramentoFiscaleSleek());
    }

    pages.add(_buildStepContiBancariSleek());
    pages.add(_buildStepSostenibilitaSleek());

    return pages;
  }

  void _nextPage() {
    if (!_canProceed()) return;
    FocusScope.of(context).unfocus();
    final pages = _getDynamicPages();
    if (_currentPage >= pages.length - 1) {
      _concludiOnboarding();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  void _concludiOnboarding() {
    final wallet = context.read<WalletProvider>();
    wallet.setPartitaIVA(hasPiva);
    
    // 1. PREPARIAMO I CONTI BANCARI DA SALVARE TRADUCENDOLI NEL MODELLO REALE
    List<AccountModel> contiDaSalvare = _contiList.map((conto) {
      final String nome = conto.nomeController.text.trim().isEmpty ? 'Conto' : conto.nomeController.text.trim();
      final double saldo = double.tryParse(conto.saldoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
      
      AccountRole ruolo = AccountRole.standard;
      Color colore = const Color(0xFFF59E0B); // Default Risparmio (Ambra)
      String sottotitolo = 'Riserva Liquidità';

      // 🛡️ Conserviamo rigorosamente gli ID per i calcoli centrali del Wallet
      if (conto.id == 'main_account') {
        ruolo = AccountRole.principal;
        colore = const Color(0xFF2DD4BF); // Teal
        sottotitolo = 'Conto Operativo';
      } else if (conto.id == 'tax_account') {
        ruolo = AccountRole.taxReserve;
        colore = const Color(0xFF3B82F6); // Blue
        sottotitolo = 'Obiettivo Riserva';
      } else if (conto.ruoloDefault == 'extra') {
        colore = const Color(0xFFA855F7); // Purple
        sottotitolo = 'Conto Aggiuntivo';
      }

      return AccountModel(
        id: conto.id, // 👈 ID FONDAMENTALE INVIOLATO
        title: nome,
        subtitle: sottotitolo,
        amount: saldo,
        color: colore,
        role: ruolo,
      );
    }).toList();

    // 2. PREPARIAMO LE ENTRATE EXTRA (DIPENDENTE/PENSIONE)
    double entrataExtraMensile = 0.0;
    if (hasDipendente || hasPensione) {
      entrataExtraMensile = double.tryParse(_dipendenteImportoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    }

    if (hasPiva) {
      final String codicePulito = (codiceAtecoSelezionato ?? '74.10.21').split(' ').first.trim();
      
      // 3. SALVIAMO PROFILO FISCALE NEL PROVIDER
      wallet.salvaProfiloFiscale(
        codiceAteco: codicePulito,
        coeffRedditivitaVal: coefficienteRedditivita ?? 0.78,
        aliquotaImpostaVal: aliquotaTasse == '15%' || aliquotaTasse == 'Ordinario' ? 0.15 : 0.05,
        accontiVersati: double.tryParse(_accontiController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0,
        nettoTarget: double.tryParse(_nettoTargetController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 2000.0,
        fatturatoStimato: double.tryParse(_fatturatoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 35000.0,
        mesiAttivi: _mesiAttiviConteggio > 0 ? _mesiAttiviConteggio : 12,
        annoAperturaPiva: annoAperturaPiva,
        meseAperturaPiva: meseAperturaPiva,
      );

      // 4. SALVIAMO I CONTI E LE ENTRATE EXTRA (SCOMMENTATI)
      wallet.salvaContiIniziali(contiDaSalvare);
      wallet.salvaEntrateExtra(importoMensile: entrataExtraMensile, dipendente: hasDipendente, pensione: hasPensione);

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => MainMenu(
          hasPartitaIva: true, 
          codiceAtecoIniziale: codicePulito, 
          coefficienteIniziale: coefficienteRedditivita ?? 0.78, 
          aliquotaImpostaIniziale: aliquotaTasse == '15%' || aliquotaTasse == 'Ordinario' ? 0.15 : 0.05
        ))
      );
    } else {
      // SALVATAGGIO ANCHE SE HA SOLO LAVORO DIPENDENTE O PENSIONE
      wallet.salvaContiIniziali(contiDaSalvare);
      wallet.salvaEntrateExtra(importoMensile: entrataExtraMensile, dipendente: hasDipendente, pensione: hasPensione);

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenu(hasPartitaIva: false)));
    }
  }

  Map<String, dynamic> _calcolaSostenibilita() {
    final double nettoTargetMese = double.tryParse(_nettoTargetController.text.replaceAll('.', '')) ?? 2000.0;
    
    double nettoMeseDipendente = 0.0;
    if (hasDipendente || hasPensione) {
      final double importo = double.tryParse(_dipendenteImportoController.text.replaceAll('.', '')) ?? 0.0;
      nettoMeseDipendente = (importo * mensilitaDipendente) / 12;
    }

    double nettoMesePiva = 0.0;
    double coeff = coefficienteRedditivita ?? 0.78;
    double aliquota = (aliquotaTasse == '5%') ? 0.05 : 0.15;
    double aliquotaInps = (hasDipendente && tipoLavoroDipendente == 'full') || hasPensione ? 0.0 : 0.2607;
    final double fatturato = double.tryParse(_fatturatoController.text.replaceAll('.', '')) ?? 0.0;

    if (hasPiva) {
      final double imponibile = fatturato * coeff;
      nettoMesePiva = (fatturato - (imponibile * aliquota) - (imponibile * aliquotaInps)) / 12;
    }

    final double nettoTotaleMese = nettoMeseDipendente + nettoMesePiva;
    final double gapMese = nettoTargetMese - nettoTotaleMese;
    final int mesiOff = 12 - _mesiAttiviConteggio;
    
    double quotaCuscinettoMese = 0.0;
    double nettoMeseNeiMesiAttivi = 0.0;
    final double entrateTotaliAnno = nettoTotaleMese * 12;
    final double fabbisognoTotaleAnno = nettoTargetMese * 12;

    if (_mesiAttiviConteggio > 0) {
      nettoMeseNeiMesiAttivi = entrateTotaliAnno / _mesiAttiviConteggio;
      quotaCuscinettoMese = nettoMeseNeiMesiAttivi - nettoTargetMese;
      if (quotaCuscinettoMese < 0) quotaCuscinettoMese = 0;
    }

    final bool cuscinettoCoperto = (entrateTotaliAnno >= fabbisognoTotaleAnno) && (_mesiAttiviConteggio > 0);

    double extraFatturatoAnnoPiva = 0.0;
    if (gapMese > 0 && hasPiva) {
      final double fattoreNetto = 1 - (coeff * (aliquota + aliquotaInps));
      extraFatturatoAnnoPiva = (gapMese * 12) / (fattoreNetto > 0 ? fattoreNetto : 1.0);
    }

    return {
      'nettoTotaleMese': nettoTotaleMese,
      'gapMese': gapMese,
      'mesiOff': mesiOff,
      'nettoMeseNeiMesiAttivi': nettoMeseNeiMesiAttivi,
      'quotaCuscinettoMese': quotaCuscinettoMese,
      'cuscinettoCoperto': cuscinettoCoperto,
      'extraFatturatoAnnoPiva': extraFatturatoAnnoPiva,
      'extraFatturatoMesePiva': _mesiAttiviConteggio > 0 ? extraFatturatoAnnoPiva / _mesiAttiviConteggio : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dynamicPages = _getDynamicPages();
    final totalPages = dynamicPages.length;
    if (_currentPage >= totalPages) _currentPage = totalPages - 1;

    final bool canProceed = _canProceed();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgDark,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) => CustomPaint(painter: FluidWavePainter(animationValue: _waveController.value)),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const FiscOnLogo(fontSize: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: bgDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderDark)),
                          child: Text('Passo ${_currentPage + 1} di $totalPages', style: TextStyle(color: brandTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int page) => setState(() => _currentPage = page),
                      children: dynamicPages,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: InkWell(
                              onTap: _prevPage,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 54, width: 54,
                                decoration: BoxDecoration(color: cardDark, border: Border.all(color: borderDark), borderRadius: BorderRadius.circular(16)),
                                child: Icon(Icons.arrow_back_rounded, color: textWhite, size: 20),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: canProceed ? [BoxShadow(color: brandTeal.withOpacity(0.15), blurRadius: 16, spreadRadius: 0)] : [],
                            ),
                            child: ElevatedButton(
                              onPressed: canProceed ? _nextPage : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandTeal,
                                foregroundColor: bgDark,
                                disabledBackgroundColor: borderDark,
                                disabledForegroundColor: textMuted,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                _currentPage == totalPages - 1 ? 'Salva e Inizia' : 'Avanti',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  // --- STEP 1: OBIETTIVO ENTRATA NETTA ---
  Widget _buildStep1ObiettivoSleek() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Obiettivo Mensile', style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Qual è l\'entrata netta mensile di cui hai bisogno per vivere sereno?', style: TextStyle(color: textMuted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 32),

          _buildHeroCard(
            title: 'NETTO TARGET DESIDERATO',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nettoTargetController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: textWhite, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      ),
                    ),
                    Text('€ / mese', style: TextStyle(color: brandTeal, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSegmentedControl(
                  options: ['1.500', '2.000', '2.500', '3.500'],
                  selectedValue: _nettoTargetController.text,
                  onChanged: (val) => setState(() => _nettoTargetController.text = val.replaceAll('.', '')),
                  suffix: '€',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: FONTI DI ENTRATA ---
  Widget _buildStep2SelezioneFontiSleek() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Le tue Fonti', style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Seleziona le voci da cui percepirai reddito quest\'anno:', style: TextStyle(color: textMuted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 32),

          _buildSelectableSleekCard(
            title: 'Partita IVA', subtitle: 'Attività autonoma o libera professione',
            icon: Icons.badge_rounded, isSelected: hasPiva, onTap: () => setState(() => hasPiva = !hasPiva),
          ),
          const SizedBox(height: 12),
          _buildSelectableSleekCard(
            title: 'Lavoro Dipendente', subtitle: 'Stipendio da contratto privato o pubblico',
            icon: Icons.work_rounded, isSelected: hasDipendente, onTap: () => setState(() => hasDipendente = !hasDipendente),
          ),
          const SizedBox(height: 12),
          _buildSelectableSleekCard(
            title: 'Pensione', subtitle: 'Assegno pensionistico INPS o Ente',
            icon: Icons.account_balance_rounded, isSelected: hasPensione, onTap: () => setState(() => hasPensione = !hasPensione),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: DIPENDENTE / PENSIONE ---
  Widget _buildStepDipendenteDettagliSleek() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasDipendente && hasPensione ? 'Dipendente & Pensione' : (hasDipendente ? 'Stipendio Dipendente' : 'Assegno Pensione'),
            style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            hasDipendente 
                ? 'Inserisci lo stipendio netto mensile percepito:' 
                : 'Inserisci l\'importo netto mensile della tua pensione:',
            style: TextStyle(color: textMuted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 32),

          _buildHeroCard(
            title: 'IMPORTO NETTO MENSILE',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dipendenteImportoController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: textWhite, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      ),
                    ),
                    Text('€ / mese', style: TextStyle(color: brandTeal, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mensilità erogate:', style: TextStyle(color: textWhite, fontSize: 13)),
                    Row(
                      children: [12, 13, 14].map((m) {
                        final isSelected = mensilitaDipendente == m;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: InkWell(
                            onTap: () => setState(() => mensilitaDipendente = m),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? brandTeal : bgDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? brandTeal : borderDark),
                              ),
                              child: Text('$m', style: TextStyle(color: isSelected ? bgDark : textWhite, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 4: PARTITA IVA ---
  Widget _buildStepPivaDettagliSleek() {
    final int currentYear = DateTime.now().year;

    final bool canShowMesiAttivi = annoAperturaPiva != null &&
        (annoAperturaPiva != currentYear || (annoAperturaPiva == currentYear && meseAperturaPiva != null));

    return SingleChildScrollView(
      controller: _pivaScrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Partita IVA: Fatturato e Periodo', style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Stima il tuo fatturato lordo e imposta il periodo di apertura e attività:', style: TextStyle(color: textMuted, fontSize: 14, height: 1.4)),
            const SizedBox(height: 28),

            // CARD 1: FATTURATO LORDO PREVISTO
            _buildHeroCard(
              title: 'FATTURATO LORDO PREVISTO P.IVA',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fatturatoController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: textWhite, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    ),
                  ),
                  Text('€ / anno', style: TextStyle(color: brandTeal, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARD 2: ANNO DI APERTURA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderDark)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ANNO DI APERTURA PARTITA IVA', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...List.generate(3, (index) => currentYear - index).map((anno) {
                          return _buildPill(
                            label: anno == currentYear ? '$anno (Ora)' : '$anno',
                            isSelected: annoAperturaPiva == anno,
                            onTap: () {
                              setState(() { 
                                annoAperturaPiva = anno; 
                                aliquotaTasse = '5%';
                                if (anno != currentYear) {
                                  meseAperturaPiva = null;
                                }
                              });
                              _scrollToPivaBottom();
                            },
                          );
                        }),
                        _buildPill(
                          label: '> 5 anni',
                          isSelected: annoAperturaPiva != null && annoAperturaPiva! <= (currentYear - 3),
                          onTap: () {
                            setState(() { 
                              annoAperturaPiva = currentYear - 5; 
                              aliquotaTasse = '15%';
                              meseAperturaPiva = null;
                            });
                            _scrollToPivaBottom();
                          },
                        ),
                      ],
                    ),
                  ),

                  // SELEZIONE MESE APERTURA (Solo se selezionato 2026)
                  if (annoAperturaPiva == currentYear) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFF1F2937)),
                    const SizedBox(height: 16),
                    Text('SELEZIONA IL MESE DI APERTURA ($currentYear)', style: TextStyle(color: brandTeal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(12, (index) {
                          final isSelected = meseAperturaPiva == (index + 1);
                          return _buildPill(
                            label: _nomiMesiEstesi[index],
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => meseAperturaPiva = index + 1);
                              _scrollToPivaBottom();
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARD 3: MESI ATTIVI (GRIGLIA COMPATTA 4 COLONNE x 3 RIGHE)
            if (canShowMesiAttivi) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(24), border: Border.all(color: brandTeal.withOpacity(0.5), width: 1.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('MESI DI ATTIVITÀ', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Text('$_mesiAttiviConteggio/12', style: TextStyle(color: brandTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: List.generate(12, (index) {
                        final isSelected = _mesiAttiviState[index];
                        final double itemWidth = (MediaQuery.of(context).size.width - 40 - 40 - 24) / 4;
                        return InkWell(
                          onTap: () => setState(() => _mesiAttiviState[index] = !isSelected),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: itemWidth,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? brandTeal.withOpacity(0.12) : bgDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? brandTeal : borderDark, width: isSelected ? 1.5 : 1),
                            ),
                            child: Text(_nomiMesiEstesi[index], style: TextStyle(color: isSelected ? brandTeal : textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- STEP ATECO ---
  Widget _buildStepPivaAtecoSleek() {
    final atecoFiltrati = AtecoDatabase.lista.where((item) {
      final query = _searchQuery.toLowerCase().replaceAll('.', '').trim();
      return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(query) || 
             item['descrizione'].toString().toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Codice ATECO', style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Individua il tuo settore per definire la redditività fiscale:', style: TextStyle(color: textMuted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderDark)),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textWhite, fontSize: 15),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: brandTeal, size: 20),
                hintText: 'Cerca codice o professione (es. 85.52.09)...',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _searchQuery.isEmpty
                ? Column(
                    children: [
                      _buildSelectableSleekCard(
                        title: 'Consulenza & Digital (78%)', subtitle: '74.10.21 - Design, IT, Marketing',
                        icon: Icons.laptop_mac_rounded, isSelected: codiceAtecoSelezionato?.startsWith('74.10.21') ?? false,
                        onTap: () => setState(() { coefficienteRedditivita = 0.78; codiceAtecoSelezionato = '74.10.21 - Digital'; }),
                      ),
                      const SizedBox(height: 12),
                      _buildSelectableSleekCard(
                        title: 'Formazione Culturale & Coaching (78%)', subtitle: '85.52.09 - Altra formazione culturale, corsi',
                        icon: Icons.school_rounded, isSelected: codiceAtecoSelezionato?.startsWith('85.52.09') ?? false,
                        onTap: () => setState(() { coefficienteRedditivita = 0.78; codiceAtecoSelezionato = '85.52.09 - Formazione Culturale'; }),
                      ),
                      const SizedBox(height: 12),
                      _buildSelectableSleekCard(
                        title: 'Commercio & E-commerce (40%)', subtitle: '47.91.10 - Vendita Online',
                        icon: Icons.storefront_rounded, isSelected: codiceAtecoSelezionato?.startsWith('47.91.10') ?? false,
                        onTap: () => setState(() { coefficienteRedditivita = 0.40; codiceAtecoSelezionato = '47.91.10 - E-commerce'; }),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderDark)),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: atecoFiltrati.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderDark),
                      itemBuilder: (context, index) {
                        final item = atecoFiltrati[index];
                        final double coef = (item['coef'] as num).toDouble();
                        final int percentuale = (coef * 100).round();
                        final isSelected = codiceAtecoSelezionato != null && codiceAtecoSelezionato!.startsWith(item['codice'].toString());
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          onTap: () => setState(() { coefficienteRedditivita = coef; codiceAtecoSelezionato = '${item['codice']} - ${item['descrizione']}'; }),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['codice'], style: TextStyle(color: isSelected ? brandTeal : textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: brandTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text('$percentuale%', style: TextStyle(color: brandTeal, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                          subtitle: Text(item['descrizione'], style: TextStyle(color: textMuted, fontSize: 12)),
                          trailing: isSelected ? Icon(Icons.check_circle_rounded, color: brandTeal, size: 20) : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- STEP INQUADRAMENTO FISCALE ---
  Widget _buildStepInquadramentoFiscaleSleek() {
    final int currentYear = DateTime.now().year;
    final double fatturatoAttuale = double.tryParse(_fatturatoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    
    final bool supera100k = fatturatoAttuale >= 100000.0; // 👈 Corretto con >= e pulizia virgole
    final bool supera85k = fatturatoAttuale > 85000.0 && !supera100k;
    final bool eSecondoAnnoOSucc = annoAperturaPiva != null && annoAperturaPiva! < currentYear;

    // Blocca il Forfettario se supera 100k o se ha superato 85k anche l'anno scorso
    final bool forfettarioInibito = supera100k || (supera85k && eSecondoAnnoOSucc && fatturatoPrecedenteSuperava85k);

    if (forfettarioInibito && aliquotaTasse != 'Ordinario') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => aliquotaTasse = 'Ordinario');
      });
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parametri Fiscali', style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Verifica la fattibilità del Regime Forfettario e imposta le aliquote:', style: TextStyle(color: textMuted, fontSize: 14, height: 1.4)),
            const SizedBox(height: 24),

            // CASO 1: SUPERAMENTO > 100K (INIBIZIONE DIRETTA)
            if (supera100k)
              Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF451A03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SUPERATI 100.000 €', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            'Il superamento di 100.000 € comporta l\'uscita immediata dal Forfettario nell\'anno in corso. Assegnato Regime Ordinario (IRPEF).',
                            style: TextStyle(color: textWhite.withOpacity(0.9), fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // CASO 2: TRA 85K E 100K E SECONDO ANNO O SUCC. (DOMANDA EXTRA)
            if (supera85k && eSecondoAnnoOSucc) ...[
              Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF97316)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, color: Color(0xFFF97316), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'VERIFICA ANNO PRECEDENTE (${annoAperturaPiva!})',
                            style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Stai stimando di fatturare ${formatEuro(fatturatoAttuale)} €. Avevi superato la soglia di 85.000 € anche l\'anno precedente?',
                      style: TextStyle(color: textWhite.withOpacity(0.9), fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => fatturatoPrecedenteSuperava85k = false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !fatturatoPrecedenteSuperava85k ? brandTeal.withOpacity(0.2) : bgDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: !fatturatoPrecedenteSuperava85k ? brandTeal : borderDark),
                              ),
                              child: Text('NO (<= 85k)', style: TextStyle(color: !fatturatoPrecedenteSuperava85k ? brandTeal : textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => fatturatoPrecedenteSuperava85k = true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: fatturatoPrecedenteSuperava85k ? const Color(0xFFEF4444).withOpacity(0.2) : bgDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: fatturatoPrecedenteSuperava85k ? const Color(0xFFEF4444) : borderDark),
                              ),
                              child: Text('SÌ (> 85k)', style: TextStyle(color: fatturatoPrecedenteSuperava85k ? const Color(0xFFEF4444) : textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // SELEZIONE REGIME FISCALE
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderDark)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REGIME E ALIQUOTA FISCALE', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  if (forfettarioInibito)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(color: bgDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderDark)),
                      child: const Row(
                        children: [
                          Icon(Icons.gavel_rounded, color: Color(0xFFF97316), size: 18),
                          SizedBox(width: 10),
                          Text('Regime Ordinario / IRPEF Semplificato', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    _buildSegmentedControl(
                      options: ['5%', '15%'],
                      labels: const ['5% (Primi 5 anni)', '15% (Standard)'],
                      selectedValue: aliquotaTasse,
                      onChanged: (val) => setState(() => aliquotaTasse = val),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildHeroCard(
              title: 'ACCONTI F24 GIÀ VERSATI',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _accontiController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: textWhite, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.0),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    ),
                  ),
                  Text('€ crediti', style: TextStyle(color: brandTeal, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- STEP CONTI BANCARI ---
  Widget _buildStepContiBancariSleek() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('I tuoi Conti', style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              InkWell(
                onTap: _aggiungiNuovoConto,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: brandTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: brandTeal, size: 16),
                      const SizedBox(width: 4),
                      Text('Aggiungi', style: TextStyle(color: brandTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Rinomina i conti e inserisci il saldo attuale:', style: TextStyle(color: textMuted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              itemCount: _contiList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _contiList[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderDark)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: bgDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderDark)),
                        child: Icon(item.ruoloDefault == 'tasse' ? Icons.lock_rounded : Icons.account_balance_wallet_rounded, color: textWhite, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: item.nomeController,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(color: textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Nome', hintStyle: TextStyle(color: textMuted), contentPadding: EdgeInsets.zero),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Saldo: ', style: TextStyle(color: textMuted, fontSize: 12)),
                                Expanded(
                                  child: TextField(
                                    controller: item.saldoController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(color: brandTeal, fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                  ),
                                ),
                                Text('€', style: TextStyle(color: brandTeal, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (item.id != 'main_account' && item.id != 'tax_account')
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded, color: textMuted, size: 20),
                          onPressed: () => _rimuoviConto(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP FINALE ESITO ANALISI ---
  Widget _buildStepSostenibilitaSleek() {
    final sost = _calcolaSostenibilita();
    final double nettoTotaleMese = sost['nettoTotaleMese']!;
    final double gapMese = sost['gapMese']!;
    final int mesiOff = sost['mesiOff']!;
    final double quotaCuscinettoMese = sost['quotaCuscinettoMese']!;
    final bool cuscinettoCoperto = sost['cuscinettoCoperto']!;
    final double extraFatturatoAnnoPiva = sost['extraFatturatoAnnoPiva']!;
    final double extraFatturatoMesePiva = sost['extraFatturatoMesePiva']!;
    final double nettoTargetMese = double.tryParse(_nettoTargetController.text.replaceAll('.', '')) ?? 2000.0;
    
    final bool isSostenibile = gapMese <= 0;
    final Color statusColor = isSostenibile ? brandTeal : const Color(0xFFF97316);
    final Color statusBgHeader = isSostenibile ? const Color(0xFF064E3B) : const Color(0xFF451A03);
    final double percentage = nettoTargetMese > 0 
        ? (nettoTotaleMese / nettoTargetMese).clamp(0.0, 1.0) 
        : 0.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSostenibile ? 'Obiettivo Coperto!' : 'Attenzione al Target',
              style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              isSostenibile 
                  ? 'Il tuo piano finanziario copre interamente il tuo fabbisogno.' 
                  : 'Le entrate attuali non coprono del tutto il target desiderato.',
              style: TextStyle(color: textMuted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),

            // HERO CARD A IMPATTO VISIVO CON PROGRESS BAR
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusBgHeader.withOpacity(0.6), cardDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: statusColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 12)
                          ],
                        ),
                        child: Icon(
                          isSostenibile ? Icons.rocket_launch_rounded : Icons.warning_amber_rounded,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSostenibile ? 'PIANO OTTIMALE' : 'TARGET GAP',
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSostenibile 
                                  ? 'Target Netto Raggiunto' 
                                  : 'Mancano ${formatEuro(gapMese)} € / mese',
                              style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // BARRA DI PROGRESSO GRAFICA (VISUAL GAUGE)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Copertura Target', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('${(percentage * 100).toStringAsFixed(0)}%', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(height: 10, color: bgDark),
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 8)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  Container(height: 1, color: borderDark),
                  const SizedBox(height: 18),

                  // NUMERI A CONFRONTO CON IL PUNTO PER LE MIGLIAIA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NETTO STIMATO', style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('${formatEuro(nettoTotaleMese)} €', style: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          Text('al mese', style: TextStyle(color: textMuted, fontSize: 11)),
                        ],
                      ),
                      Container(height: 40, width: 1, color: borderDark),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TARGET', style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('${formatEuro(nettoTargetMese)} €', style: TextStyle(color: statusColor, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          Text('desiderato', style: TextStyle(color: textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CHIARIFICATO: LE OPZIONI SONO ALTERNATIVE
            if (!isSostenibile)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
  children: [
    Icon(Icons.lightbulb_rounded, color: statusColor, size: 20),
    const SizedBox(width: 8),
    Text(
      (hasPiva && hasDipendente) ? 'SCEGLI UNA DI QUESTE ALTERNATIVE:' : 'SOLUZIONE CONSIGLIATA:',
      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
    ),
  ],
),
                    const SizedBox(height: 12),
                    
                    // Opzione Partita IVA (se attiva)
                    if (hasPiva) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.add_chart_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Opzione A: Aumenta il Fatturato P.IVA di +${formatEuro(extraFatturatoAnnoPiva)} €/anno (+${formatEuro(extraFatturatoMesePiva)} €/mese nei tuoi $_mesiAttiviConteggio mesi attivi)',
                              style: TextStyle(color: textWhite.withOpacity(0.9), fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      if (hasDipendente) const SizedBox(height: 8),
                    ],

                    // Opzione Lavoro Dipendente (se attivo)
                    if (hasDipendente) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.work_outline_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${hasPiva ? "Opzione B: Oppure adegua" : "Opzione A: Adegua"} lo Stipendio Dipendente di +${formatEuro(gapMese)} € netti/mese',
                              style: TextStyle(color: textWhite.withOpacity(0.9), fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Nota per la Pensione (non modificabile)
                    if (hasPensione) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nota: la Pensione non è modificabile. Per coprire il gap di ${formatEuro(gapMese)} €/mese valuta l\'apertura o l\'incremento di un\'attività autonoma P.IVA.',
                              style: TextStyle(color: textWhite.withOpacity(0.9), fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ANALISI DEDICATA DEL CUSCINETTO MESI OFF
            if (mesiOff > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cuscinettoCoperto ? brandTeal.withOpacity(0.5) : const Color(0xFFF97316).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.beach_access_rounded, 
                          color: cuscinettoCoperto ? brandTeal : const Color(0xFFF97316), 
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CUSCINETTO $mesiOff MESI OFF:', 
                          style: TextStyle(
                            color: cuscinettoCoperto ? brandTeal : const Color(0xFFF97316), 
                            fontWeight: FontWeight.bold, 
                            fontSize: 12, 
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (cuscinettoCoperto)
                      Text(
                        'Cuscinetto ampiamente gestibile! Nei tuoi $_mesiAttiviConteggio mesi di lavoro incasserai ${formatEuro(sost["nettoMeseNeiMesiAttivi"])} €/mese netti. Accantonando +${formatEuro(quotaCuscinettoMese)} €/mese coprirai i $mesiOff mesi di pausa garantendoti il tuo target mensile.',
                        style: TextStyle(color: textWhite.withOpacity(0.9), fontSize: 12, height: 1.3),
                      )
                    else
                      Text(
                        'Attenzione al cuscinetto: con il reddito stimato attuale, non riesci ad accantonare abbastanza nei mesi lavorativi per coprire i tuoi $mesiOff mesi di pausa mantenendo il target desiderato.',
                        style: TextStyle(color: textWhite.withOpacity(0.9), fontSize: 12, height: 1.3),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildHeroCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: brandTeal.withOpacity(0.5), width: 1),
        boxShadow: [BoxShadow(color: brandTeal.withOpacity(0.05), blurRadius: 20, spreadRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectableSleekCard({required String title, required String subtitle, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? brandTeal.withOpacity(0.05) : cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? brandTeal : borderDark, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected ? [BoxShadow(color: brandTeal.withOpacity(0.1), blurRadius: 16)] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? brandTeal : bgDark, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: isSelected ? bgDark : textWhite, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? brandTeal : borderDark, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({required List<String> options, List<String>? labels, required String selectedValue, required Function(String) onChanged, String? suffix}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: bgDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderDark)),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = selectedValue.replaceAll('.', '') == options[index].replaceAll('.', '');
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(options[index]),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isSelected ? cardDark : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? borderDark : Colors.transparent)),
                child: Text(labels != null ? labels[index] : '${options[index]}${suffix ?? ''}', style: TextStyle(color: isSelected ? brandTeal : textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: isSelected ? brandTeal.withOpacity(0.12) : bgDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? brandTeal : borderDark, width: isSelected ? 1.5 : 1)),
          child: Text(label, style: TextStyle(color: isSelected ? brandTeal : textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}