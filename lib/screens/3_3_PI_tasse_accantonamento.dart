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

  Map<String, double> _calcolaFiscalita(double lordo) {
    final double imponibile = lordo * _coeffSelezionato;

    final double inpsY = imponibile * widget.aliquotaInps;
    final double impostaY = imponibile * widget.aliquotaImposta;
    final double saldoY = inpsY + impostaY;

    final double accontoInpsY1 = inpsY * 0.80;
    final double accontoImpostaY1 = impostaY * 1.00;
    final double accontiY1 = accontoInpsY1 + accontoImpostaY1;

    final double totaleTasse = saldoY + accontiY1;
    final double nettoSpendibile = lordo - totaleTasse;

    return {
      'imponibile': imponibile,
      'inpsY': inpsY,
      'impostaY': impostaY,
      'saldoY': saldoY,
      'accontoInpsY1': accontoInpsY1,
      'accontoImpostaY1': accontoImpostaY1,
      'accontiY1': accontiY1,
      'totaleTasse': totaleTasse,
      'nettoSpendibile': nettoSpendibile,
    };
  }

  void _toggleAtecoAccordion() {
    setState(() {
      _isModificaEspansa = !_isModificaEspansa;
    });

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

  void _mostraInfoTasse(BuildContext context, String titolo, String spiegazione) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF2DD4BF), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titolo,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          spiegazione,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ho capito', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    final fiscaliIncassato = _calcolaFiscalita(widget.totaleFatturatoIncassato);
    final fiscaliSospeso = _calcolaFiscalita(widget.totaleFatturatoInSospeso);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: isKeyboardOpen ? screenSize.height * 0.88 : screenSize.height * 0.78,
            color: const Color(0xFF18181B),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.75),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
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
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Stima Tasse P.IVA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'PROFILO FISCALE ATECO',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: _toggleAtecoAccordion,
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.verified_rounded, color: Color(0xFF2DD4BF), size: 12),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _isModificaEspansa ? 'Chiudi' : 'Cambia',
                                                        style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildRow('Codice ATECO:', _atecoSelezionato, isBold: true),
                                          _buildRow('Coeff. Redditività:', '${(_coeffSelezionato * 100).toInt()}%'),
                                          _buildRow('Imposta Sostitutiva:', '${(widget.aliquotaImposta * 100).toInt()}% (Startup)'),
                                          _buildRow('Contributi INPS:', '${(widget.aliquotaInps * 100).toStringAsFixed(2)}%'),
                                          if (_isModificaEspansa) ...[
                                            const SizedBox(height: 8),
                                            Divider(color: Colors.white.withOpacity(0.12), height: 1),
                                            const SizedBox(height: 8),
                                            Column(
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
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'ACCANTONAMENTO REALE (SALDO + ACCONTI)',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${fiscaliIncassato['totaleTasse']!.toStringAsFixed(2)} €',
                                                style: const TextStyle(
                                                  color: Color(0xFF3B82F6),
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Netto spendibile rimanente: ${fiscaliIncassato['nettoSpendibile']!.toStringAsFixed(2)} €',
                                                style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 28),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                          'DETTAGLIO FISCALE (FATTURATO INCASSATO)',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildRow(
                                          'Fatturato Incassato:',
                                          '${widget.totaleFatturatoIncassato.toStringAsFixed(2)} €',
                                          color: const Color(0xFF10B981),
                                          isBold: true,
                                        ),
                                        _buildRow('Imponibile Fiscale:', '${fiscaliIncassato['imponibile']!.toStringAsFixed(2)} €'),
                                        Divider(color: Colors.white.withOpacity(0.12), height: 12),
                                        _buildRow(
                                          'Saldo Tasse:',
                                          '-${fiscaliIncassato['saldoY']!.toStringAsFixed(2)} €',
                                          color: const Color(0xFFF59E0B),
                                          onInfoTap: () => _mostraInfoTasse(
                                            context,
                                            'Saldo Tasse Anno Corrente',
                                            'Rappresenta le tasse reali sul fatturato incassato sull\'Imponibile Fiscale (${(_coeffSelezionato * 100).toInt()}%):\n\n'
                                            '• INPS: ${(widget.aliquotaInps * 100).toStringAsFixed(2)}%\n'
                                            '• Imposta Sostitutiva: ${(widget.aliquotaImposta * 100).toInt()}%\n\n'
                                            'Totale Saldo = ${((widget.aliquotaInps + widget.aliquotaImposta) * 100).toStringAsFixed(2)}% sull\'Imponibile.',
                                          ),
                                        ),
                                        _buildRow(
                                          'Acconto Tasse:',
                                          '-${fiscaliIncassato['accontiY1']!.toStringAsFixed(2)} €',
                                          color: const Color(0xFFF97316),
                                          onInfoTap: () => _mostraInfoTasse(
                                            context,
                                            'Acconti Anno Successivo',
                                            'Sono i contributi e le tasse che lo Stato chiede di anticipare per l\'anno a venire:\n\n'
                                            '• Acconto INPS: 80% dell\'INPS calcolato quest\'anno\n'
                                            '• Acconto Imposta: 100% dell\'Imposta calcolata quest\'anno\n\n'
                                            'Accantonarli ora ti evita brutte sorprese alla prossima dichiarazione dei redditi!',
                                          ),
                                        ),
                                        Divider(color: Colors.white.withOpacity(0.12), height: 12),
                                        _buildRow('Totale da Accantonare:', '-${fiscaliIncassato['totaleTasse']!.toStringAsFixed(2)} €', color: const Color(0xFFEF4444), isBold: true),
                                        _buildRow('Netto Spendibile Reale:', '${fiscaliIncassato['nettoSpendibile']!.toStringAsFixed(2)} €', color: const Color(0xFF2DD4BF), isBold: true),
                                      ],
                                    ),
                                  ),
                                  if (widget.totaleFatturatoInSospeso > 0) ...[
                                    const SizedBox(height: 10),
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
                                          _buildRow('Saldo Tasse Stimato (Y):', '-${fiscaliSospeso['saldoY']!.toStringAsFixed(2)} €', color: const Color(0xFFF59E0B)),
                                          _buildRow('Acconti Stimati (Y+1):', '-${fiscaliSospeso['accontiY1']!.toStringAsFixed(2)} €', color: const Color(0xFFF97316)),
                                          Divider(color: Colors.white.withOpacity(0.12), height: 10),
                                          _buildRow('Totale Tasse in Sospeso:', '-${fiscaliSospeso['totaleTasse']!.toStringAsFixed(2)} €', color: const Color(0xFFEF4444), isBold: true),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ), // <--- QUESTA PARENTESI ) CHIUDE EXPANDED( CHE MANCAVA!
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color, VoidCallback? onInfoTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isBold ? Colors.white : Colors.white54,
                      fontSize: 11,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onInfoTap != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onInfoTap,
                    child: const Icon(Icons.info_outline_rounded, color: Color(0xFF2DD4BF), size: 14),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color ?? (isBold ? Colors.white : Colors.white.withOpacity(0.9)),
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}