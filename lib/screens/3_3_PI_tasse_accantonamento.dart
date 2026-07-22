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

  // CALCOLI FISCALI PRINCIPALI
  double get _imponibileIncassato => widget.totaleFatturatoIncassato * _coeffSelezionato;
  double get _impostaReale => _imponibileIncassato * widget.aliquotaImposta;
  double get _inpsReale => _imponibileIncassato * widget.aliquotaInps;
  double get _tasseRealiIncassate => _impostaReale + _inpsReale;

  double get _imponibileSospeso => widget.totaleFatturatoInSospeso * _coeffSelezionato;
  double get _tasseFutureInSospeso => _imponibileSospeso * (widget.aliquotaImposta + widget.aliquotaInps);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SFONDO CLICCABILE PER CHIUDERE
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: screenHeight * 0.88,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CARD FROSTED GLASS
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 18),
              child: Container(
                height: screenHeight * 0.84,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417).withOpacity(0.72),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER
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
                            const Text(
                              'Stima Tasse P.IVA',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                          ),
                          child: const Text(
                            'Forfettario',
                            style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2. CASELLA PROFILO FISCALE UTENTE
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
                                  const Text('INFORMAZIONI PROFILO FISCALE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                  const SizedBox(height: 8),
                                  _buildRow('Codice ATECO:', _atecoSelezionato, isBold: true),
                                  _buildRow('Coeff. Redditività:', '${(_coeffSelezionato * 100).toInt()}%'),
                                  _buildRow('Imposta Sostitutiva:', '${(widget.aliquotaImposta * 100).toInt()}% (Startup)'),
                                  _buildRow('Contributi INPS:', '${(widget.aliquotaInps * 100).toStringAsFixed(2)}%'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 3. HERO CARD TASSE REALI SU INCASSATO
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('STIMA ACCANTONAMENTO TASSE (CASSA)', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_tasseRealiIncassate.toStringAsFixed(2)} €',
                                        style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 30),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 4. DETTAGLIO CALCOLO FISCALE CASSA
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
                                  const Text('DETTAGLIO CALCOLO FISCALE (INCASSATO)', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                  const SizedBox(height: 8),
                                  _buildRow('Fatturato Incassato 2026:', '${widget.totaleFatturatoIncassato.toStringAsFixed(2)} €', color: const Color(0xFF10B981), isBold: true),
                                  _buildRow('Imponibile Fiscale Reale:', '${_imponibileIncassato.toStringAsFixed(2)} €'),
                                  const Divider(color: Colors.white12, height: 12),
                                  _buildRow('Imposta Sostitutiva (5%):', '${_impostaReale.toStringAsFixed(2)} €'),
                                  _buildRow('Contributi INPS (26.07%):', '${_inpsReale.toStringAsFixed(2)} €'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 5. BOX EVIDENZIATO SOSPESI
                            if (widget.totaleFatturatoInSospeso > 0)
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
                                        Text('FATTURE EMESSE IN SOSPESO', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
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

                            const SizedBox(height: 12),

                            // 6. MENU ESPANDIBILE ATECO (ACCORDION)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isModificaEspansa ? const Color(0xFF2DD4BF).withOpacity(0.5) : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _isModificaEspansa = !_isModificaEspansa),
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
                                                Text('Cambia Codice ATECO', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                SizedBox(height: 2),
                                                Text('Seleziona la tua attività per la % esatta', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            _isModificaEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            color: Colors.white38,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  if (_isModificaEspansa) ...[
                                    const Divider(color: Colors.white12, height: 1),
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
                                                color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.15) : Colors.black.withOpacity(0.2),
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
                                                      style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.white70 : Colors.white54, fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
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