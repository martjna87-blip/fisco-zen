import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/fluid_wave_painter.dart';
import '1_main_menu.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> with SingleTickerProviderStateMixin {
  // 🕹️ CONTROLLER DI NAVIGAZIONE
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  late AnimationController _waveController;
  final ScrollController _scrollController = ScrollController();

  // 🗂️ VARIABILI STEP 1: PROFILO & ATECO
  String? tipoProfilo; // 'piva' o 'dipendente'
  String? aliquotaTasse;
  double? coefficienteRedditivita;
  String? codiceAtecoSelezionato;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🗂️ VARIABILI STEP 2: CONTRIBUTI & ACCONTI
  String? tipoLavoroDipendente; // 'nessuno', 'full', 'part_over50', 'part_under50'
  final TextEditingController _accontiController = TextEditingController();

  // 🗂️ VARIABILI STEP 3: OBIETTIVO NETTO
  final TextEditingController _nettoTargetController = TextEditingController(text: '2000');

  // 🗂️ VARIABILI STEP 4: PROIEZIONE & STAGIONALITÀ
  final TextEditingController _fatturatoController = TextEditingController(text: '35000');
  int _mesiAttivi = 10;

  final List<Map<String, dynamic>> _databaseAteco = [
    {'codice': '85.52.09', 'descrizione': 'Altra formazione culturale', 'coef': 0.78},
    {'codice': '62.01.00', 'descrizione': 'Sviluppo di software e programmazione', 'coef': 0.78},
    {'codice': '70.22.09', 'descrizione': 'Consulenza imprenditoriale e gestionale', 'coef': 0.78},
    {'codice': '73.11.02', 'descrizione': 'Marketing, Social Media e Advertising', 'coef': 0.78},
    {'codice': '74.10.21', 'descrizione': 'Graphic design, Web design, UI/UX', 'coef': 0.78},
    {'codice': '47.91.10', 'descrizione': 'Commercio al dettaglio (E-commerce)', 'coef': 0.67},
    {'codice': '56.10.11', 'descrizione': 'Ristoranti, Pizzerie con somministrazione', 'coef': 0.40},
    {'codice': '96.02.01', 'descrizione': 'Servizi dei saloni di barbiere e parrucchiere', 'coef': 0.40},
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
    // Se è dipendente, salta tutto e vai alla fine
    if (tipoProfilo == 'dipendente' || _currentPage == _totalPages - 1) {
      _concludiOnboarding();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
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
      
      // Qui potrai passare tutte le nuove variabili (acconti, target, mesi) al Provider 
      // tramite un futuro metodo es: wallet.salvaProfiloFiscale(...)
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainMenu(
            hasPartitaIva: true,
            codiceAtecoIniziale: codiceAtecoSelezionato ?? '74.10.21',
            coefficienteIniziale: coefficienteRedditivita ?? 0.78,
            aliquotaImpostaIniziale: aliquotaTasse == '5%' ? 0.05 : 0.15,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0C),
      resizeToAvoidBottomInset: false, // 👈 Impedisce alla tastiera di schiacciare lo schermo
      body: Stack(
        children: [
          // 🌊 SFONDO 3D FLUIDO (Mantenuto identico!)
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
                // 📊 HEADER & PROGRESS BAR
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
                          const Text('Fisco Zen', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

                // 🔀 IL MOTORE DELLE SCHERMATE
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

                // 🕹️ BOTTOM BAR (TASTI AVANTI/INDIETRO)
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
                                  : (_currentPage == _totalPages - 1 ? 'Scopri il tuo Netto' : 'Avanti'),
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
    );
  }

  // ==========================================
  // 🟢 STEP 1: PROFILO & ATECO (Tuo codice originale adattato)
  // ==========================================
  Widget _buildStep1() {
    final atecoFiltrati = _databaseAteco.where((item) {
      final query = _searchQuery.toLowerCase().replaceAll('.', '').trim();
      return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(query) || 
             item['descrizione'].toString().toLowerCase().contains(query);
    }).toList();

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
            const SizedBox(height: 32),
            const Text('Da quanto tempo hai aperto la Partita IVA?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeaderQuickAction(icon: Icons.eco, label: 'Startup (5%)', subtitle: 'Meno di 5 anni', isSelected: aliquotaTasse == '5%', onTap: () => setState(() => aliquotaTasse = '5%')),
                _buildHeaderQuickAction(icon: Icons.work_outline_rounded, label: 'Standard (15%)', subtitle: 'Più di 5 anni', isSelected: aliquotaTasse == '15%', onTap: () => setState(() => aliquotaTasse = '15%')),
              ],
            ),
            
            if (aliquotaTasse != null) ...[
              const SizedBox(height: 32),
              const Text('CERCA O SELEZIONA CODICE ATECO', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              _buildCustomTextField(
                controller: _searchController,
                hintText: 'es. 855209 o professione...',
                icon: Icons.search_rounded,
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF101618).withOpacity(0.88), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF1F2937))),
                child: _searchQuery.isNotEmpty
                    ? ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: atecoFiltrati.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF1F2937), indent: 16),
                        itemBuilder: (context, index) {
                          final item = atecoFiltrati[index];
                          final isSelected = codiceAtecoSelezionato == item['codice'];
                          final double coef = (item['coef'] as num).toDouble();
                          return ListTile(
                            onTap: () {
                              setState(() {
                                coefficienteRedditivita = coef;
                                codiceAtecoSelezionato = '${item['codice']} - ${item['descrizione']}';
                              });
                              _scrollToBottom();
                            },
                            title: Row(
                              children: [
                                Text(item['codice'], style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(6)), child: Text('${(coef * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            subtitle: Text(item['descrizione'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 20) : null,
                          );
                        })
                    : Column(
                        children: [
                          _buildRevolutListTile(icon: Icons.laptop_mac_rounded, title: 'Consulenza & Digital (78%)', subtitle: 'IT, Marketing, Formazione', isSelected: coefficienteRedditivita == 0.78, onTap: () => _selectAtecoPreset(0.78, '74.10.21 - Consulenza & Digital')),
                          const Divider(height: 1, color: Color(0xFF1F2937), indent: 64),
                          _buildRevolutListTile(icon: Icons.storefront_rounded, title: 'Commercio & Agenti (67%)', subtitle: 'E-commerce, Negozi', isSelected: coefficienteRedditivita == 0.67, onTap: () => _selectAtecoPreset(0.67, '47.91.10 - Commercio & Agenti')),
                          const Divider(height: 1, color: Color(0xFF1F2937), indent: 64),
                          _buildRevolutListTile(icon: Icons.build_rounded, title: 'Artigiani & Ristorazione (40%)', subtitle: 'Produzione, Bar, Estetisti', isSelected: coefficienteRedditivita == 0.40, onTap: () => _selectAtecoPreset(0.40, '56.10.11 - Artigiani & Ristorazione')),
                        ],
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

  // ==========================================
  // 🟡 STEP 2: CONTRIBUTI & ACCONTI F24
  // ==========================================
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
          _buildRevolutListTile(icon: Icons.work, title: 'Sì, Full-Time', subtitle: '36-40 ore a settimana', isSelected: tipoLavoroDipendente == 'full', onTap: () => setState(() => tipoLavoroDipendente = 'full')),
          const SizedBox(height: 8),
          _buildRevolutListTile(icon: Icons.timelapse_rounded, title: 'Sì, Part-Time', subtitle: 'Meno di 36 ore a settimana', isSelected: tipoLavoroDipendente == 'part_over50' || tipoLavoroDipendente == 'part_under50', onTap: () => setState(() => tipoLavoroDipendente = 'part_over50')),
          
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
                      Expanded(child: _buildProfileCard(id: 'part_over50', icon: Icons.keyboard_double_arrow_up_rounded, title: 'Più del 50%', subtitle: 'Es. 24h su 40h', activeColor: const Color(0xFF0D9488), groupValue: tipoLavoroDipendente, onChanged: (v) => setState(() => tipoLavoroDipendente = v))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildProfileCard(id: 'part_under50', icon: Icons.keyboard_double_arrow_down_rounded, title: 'Fino al 50%', subtitle: 'Es. 20h su 40h', activeColor: const Color(0xFF3B82F6), groupValue: tipoLavoroDipendente, onChanged: (v) => setState(() => tipoLavoroDipendente = v))),
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

  // ==========================================
  // 🔵 STEP 3: OBIETTIVO NETTO
  // ==========================================
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Obiettivo di Vita', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Qual è lo stipendio netto mensile di cui hai bisogno per vivere sereno e pagare le tue spese?', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
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
          const Center(child: Text('L\'app utilizzerà questo valore per capire se\nil tuo fatturato è sufficiente a sostenerti.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))),
        ],
      ),
    );
  }

  // ==========================================
  // 🟣 STEP 4: PROIEZIONE & STAGIONALITÀ
  // ==========================================
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proiezione Annuale', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ultimo passo: stima i tuoi incassi lordi per scoprire il tuo Verdetto di Sostenibilità.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 32),
          
          const Text('FATTURATO LORDO STIMATO', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: _fatturatoController,
            hintText: 'Es. 35000',
            icon: Icons.trending_up_rounded,
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 32),
          const Text('MESI ATTIVI DI LAVORO', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF101618).withOpacity(0.85), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1F2937))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lavoro e incasso per:', style: TextStyle(color: Colors.white, fontSize: 14)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF2DD4BF)), onPressed: () => setState(() { if (_mesiAttivi > 1) _mesiAttivi--; })),
                    Text('$_mesiAttivi mesi', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2DD4BF)), onPressed: () => setState(() { if (_mesiAttivi < 12) _mesiAttivi++; })),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Se ti fermi ad Agosto e Dicembre, seleziona 10 mesi. L\'app creerà un cuscinetto per pagarti lo stipendio nei mesi di pausa.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
      ),
    );
  }

  // ==========================================
  // 🛠️ COMPONENTI GRAFICI RIUTILIZZABILI (Tuo Stile)
  // ==========================================
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