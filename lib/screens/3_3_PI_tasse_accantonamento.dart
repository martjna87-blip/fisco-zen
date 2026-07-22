import 'dart:ui';
import 'package:flutter/material.dart';

class TasseAccantonamentoSheet extends StatefulWidget {
  final String codiceAteco;
  final double coefficienteRedditivita;
  final double aliquotaImposta;
  final double aliquotaInps;
  final double totaleFatturatoIncassato;
  final double totaleFatturatoInSospeso;
  final Function(String nuovoAteco, double nuovoCoeff) onAtecoCambiato;

  const TasseAccantonamentoSheet({
    super.key,
    required this.codiceAteco,
    required this.coefficienteRedditivita,
    required this.aliquotaImposta,
    required this.aliquotaInps,
    required this.totaleFatturatoIncassato,
    this.totaleFatturatoInSospeso = 0.0,
    required this.onAtecoCambiato,
  });

  @override
  State<TasseAccantonamentoSheet> createState() => _TasseAccantonamentoSheetState();
}

class _TasseAccantonamentoSheetState extends State<TasseAccantonamentoSheet> {
  bool _isModificaEspansa = false;
  late String _atecoSelezionato;
  late double _coeffSelezionato;
  
  // Controller per gestire lo scroll automatico all'apertura dell'ATECO
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _listaAteco = [
    {'codice': '74.10.21 - Consulenza & Digital', 'coeff': 0.78},
    {'codice': '62.02.00 - Consulenza Software', 'coeff': 0.67},
    {'codice': '70.22.09 - Consulenza Aziendale', 'coeff': 0.78},
    {'codice': '47.91.10 - E-commerce / Commercio', 'coeff': 0.40},
    {'codice': '96.02.01 - Servizi alla Persona', 'coeff': 0.67},
    {'codice': '68.31.00 - Intermediazione Immobiliare', 'coeff': 0.86},
  ];

  @override
  void initState() {
    super.initState();
    _atecoSelezionato = widget.codiceAteco;
    _coeffSelezionato = widget.coefficienteRedditivita;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // CALCOLI FISCALI PRINCIPALI
  double get _imponibileIncassato => widget.totaleFatturatoIncassato * _coeffSelezionato;
  double get _impostaReale => _imponibileIncassato * widget.aliquotaImposta;
  double get _inpsReale => _imponibileIncassato * widget.aliquotaInps;
  double get _tasseRealiIncassate => _impostaReale + _inpsReale;

  double get _imponibileSospeso => widget.totaleFatturatoInSospeso * _coeffSelezionato;
  double get _tasseFutureInSospeso => _imponibileSospeso * (widget.aliquotaImposta + widget.aliquotaInps);

  void _toggleAtecoAccordion() {
    setState(() {
      _isModificaEspansa = !_isModificaEspansa;
    });

    // Se stiamo aprendo l'accordion, facciamo uno scroll fluido verso il fondo
    if (_isModificaEspansa) {
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
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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

              // 3. CONTENUTO ARTICOLATO IN 2 RIQUADRI GLASS CON HEADER FLUTTUANTE
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // --- HEADER FLUTTUANTE ---
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
                              'Stima Tasse P.IVA',
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
                            color: const Color(0xFF2563EB).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                          ),
                          child: const Text(
                            'Forfettario',
                            style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // 🔲 RIQUADRO 1: PROFILO, SCUDO HERO, DETTAGLI & ACCORDION
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
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // CASELLA PROFILO FISCALE UTENTE
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'INFORMAZIONI PROFILO FISCALE',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildRow('Codice ATECO:', _atecoSelezionato, isBold: true),
                                        _buildRow('Coeff. Redditività:', '${(_coeffSelezionato * 100).toInt()}%'),
                                        _buildRow('Imposta Sostitutiva:', '${(widget.aliquotaImposta * 100).toInt()}% (Startup)'),
                                        _buildRow('Contributi INPS:', '${(widget.aliquotaInps * 100).toStringAsFixed(2)}%'),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // HERO CARD TASSE REALI SU INCASSATO CON SCUDO
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'STIMA ACCANTONAMENTO TASSE (CASSA)',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_tasseRealiIncassate.toStringAsFixed(2)} €',
                                              style: const TextStyle(
                                                color: Color(0xFF3B82F6),
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 28),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // DETTAGLIO CALCOLO FISCALE CASSA
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'DETTAGLIO CALCOLO FISCALE (INCASSATO)',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildRow(
                                          'Fatturato Incassato 2026:',
                                          '${widget.totaleFatturatoIncassato.toStringAsFixed(2)} €',
                                          color: const Color(0xFF10B981),
                                          isBold: true,
                                        ),
                                        _buildRow('Imponibile Fiscale Reale:', '${_imponibileIncassato.toStringAsFixed(2)} €'),
                                        Divider(color: Colors.white.withOpacity(0.12), height: 12),
                                        _buildRow('Imposta Sostitutiva (5%):', '${_impostaReale.toStringAsFixed(2)} €'),
                                        _buildRow('Contributi INPS (26.07%):', '${_inpsReale.toStringAsFixed(2)} €'),
                                      ],
                                    ),
                                  ),

                                  if (widget.totaleFatturatoInSospeso > 0) ...[
                                    const SizedBox(height: 10),

                                    // BOX EVIDENZIATO SOSPESI
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B), size: 15),
                                              SizedBox(width: 6),
                                              Text(
                                                'FATTURE EMESSE IN SOSPESO',
                                                style: TextStyle(
                                                  color: Color(0xFFF59E0B),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildRow('Non ancora incassate:', '${widget.totaleFatturatoInSospeso.toStringAsFixed(2)} €', color: Colors.white),
                                          _buildRow('Tasse stimate alla cassa:', '~${_tasseFutureInSospeso.toStringAsFixed(2)} €', color: const Color(0xFFF59E0B)),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Nota: Se incassate dopo il 31/12 slitteranno all\'anno fiscale successivo.',
                                            style: TextStyle(color: Colors.white38, fontSize: 9, fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  // MENU ESPANDIBILE ATECO (ACCORDION CON AUTO-SCROLL)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isModificaEspansa
                                            ? const Color(0xFF2DD4BF).withOpacity(0.5)
                                            : Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onTap: _toggleAtecoAccordion,
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.business_center_outlined, color: Color(0xFF2DD4BF), size: 18),
                                                ),
                                                const SizedBox(width: 12),
                                                const Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Cambia Codice ATECO',
                                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        'Seleziona la tua attività per la % esatta',
                                                        style: TextStyle(color: Colors.white38, fontSize: 10),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  _isModificaEspansa
                                                      ? Icons.keyboard_arrow_up_rounded
                                                      : Icons.keyboard_arrow_down_rounded,
                                                  color: Colors.white38,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        if (_isModificaEspansa) ...[
                                          Divider(color: Colors.white.withOpacity(0.12), height: 1),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              children: _listaAteco.map((item) {
                                                final bool isSelected = item['codice'] == _atecoSelezionato;
                                                final double coeff = item['coeff'] as double;

                                                return InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _atecoSelezionato = item['codice'] as String;
                                                      _coeffSelezionato = coeff;
                                                      _isModificaEspansa = false;
                                                    });
                                                    widget.onAtecoCambiato(_atecoSelezionato, _coeffSelezionato);
                                                  },
                                                  child: Container(
                                                    width: double.infinity,
                                                    margin: const EdgeInsets.only(bottom: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color(0xFF2DD4BF).withOpacity(0.15)
                                                          : Colors.black.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: isSelected ? const Color(0xFF2DD4BF) : Colors.transparent,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            item['codice'] as String,
                                                            style: TextStyle(
                                                              color: isSelected ? Colors.white : Colors.white70,
                                                              fontSize: 11,
                                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF2DD4BF).withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            '${(coeff * 100).toInt()}%',
                                                            style: const TextStyle(
                                                              color: Color(0xFF2DD4BF),
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // 🔲 RIQUADRO 2: TASTO CHIUDI BOTTOM GLASS
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
                              'Chiudi',
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

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white70 : Colors.white54,
              fontSize: 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color ?? (isBold ? Colors.white : Colors.white.withOpacity(0.85)),
                fontSize: 10,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}