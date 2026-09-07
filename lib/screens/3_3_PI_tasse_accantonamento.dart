import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '../data/ateco_database.dart';

class TasseAccantonamentoSheet extends StatefulWidget {
  final String codiceAteco;
  final double coefficienteRedditivita;
  final double aliquotaImposta;
  final double aliquotaInps;
  final double totaleFatturatoIncassato;
  final double totaleFatturatoInSospeso;
  final List<Map<String, dynamic>>? fattureIncassate;
  final List<Map<String, dynamic>>? fattureDaIncassare;
  final Function(String nuovoAteco, double nuovoCoeff)? onAtecoCambiato;

  const TasseAccantonamentoSheet({
    super.key,
    required this.codiceAteco,
    required this.coefficienteRedditivita,
    required this.aliquotaImposta,
    required this.aliquotaInps,
    required this.totaleFatturatoIncassato,
    this.totaleFatturatoInSospeso = 0.0,
    this.fattureIncassate,
    this.fattureDaIncassare,
    this.onAtecoCambiato,
  });

  @override
  State<TasseAccantonamentoSheet> createState() => _TasseAccantonamentoSheetState();
}

class _TasseAccantonamentoSheetState extends State<TasseAccantonamentoSheet> {
  bool _isSospesoEspanso = false;

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final walletProvider = Provider.of<WalletProvider>(context);

    // ⚡ RECUPERO FATTURE DALL'ANNO FISCALE SELEZIONATO IN 3_5
    final listaTutteIncassate = walletProvider.fattureIncassateAnnoCorrente;
    final fattureInSospeso = walletProvider.fattureDaIncassareAnnoCorrente;

    final int annoCorrente = walletProvider.annoFiscaleCorrente;
    final int annoProssimo = annoCorrente + 1;

    // 🎯 STESSO IDENTICO ALGORITMO DI CALCOLO DEL 3_5
    double lordoTotale = 0.0;
    double inpsYTotale = 0.0;
    double impostaYTotale = 0.0;
    double accontoInpsY1Totale = 0.0;
    double accontoImpostaY1Totale = 0.0;

    for (var f in listaTutteIncassate) {
      final double lordo = (f['importo'] as num).toDouble();
      final double coefFattura = (f['coefAteco'] as num?)?.toDouble() ?? widget.coefficienteRedditivita;
      final double imponibile = lordo * coefFattura;

      final double inpsY = imponibile * widget.aliquotaInps;
      final double impostaY = imponibile * widget.aliquotaImposta;

      final double accontoInpsY1 = inpsY * 0.80;
      final double accontoImpostaY1 = impostaY * 1.00;

      lordoTotale += lordo;
      inpsYTotale += inpsY;
      impostaYTotale += impostaY;
      accontoInpsY1Totale += accontoInpsY1;
      accontoImpostaY1Totale += accontoImpostaY1;
    }

    final double totaleTasseY = inpsYTotale + impostaYTotale;
    final double totaleAccontiY1 = accontoInpsY1Totale + accontoImpostaY1Totale;
    final double grandTotaleAccantonare = totaleTasseY + totaleAccontiY1;
    final double nettoTotaleReale = lordoTotale - grandTotaleAccantonare;

    // 🎯 CALCOLO FATTURE IN SOSPESO IDENTICO A 3_5
    double lordoSospeso = 0.0;
    double imponibileSospeso = 0.0;
    double inpsSospeso = 0.0;
    double impostaSospeso = 0.0;

    for (var f in fattureInSospeso) {
      final double importo = (f['importo'] as num?)?.toDouble() ?? 0.0;
      final double coef = (f['coefAteco'] as num?)?.toDouble() ?? widget.coefficienteRedditivita;

      final double imponibile = importo * coef;
      lordoSospeso += importo;
      imponibileSospeso += imponibile;
      inpsSospeso += (imponibile * widget.aliquotaInps);
      impostaSospeso += (imponibile * widget.aliquotaImposta);
    }

    final double saldoSospeso = inpsSospeso + impostaSospeso;
    final double accontiSospeso = (inpsSospeso * 0.80) + (impostaSospeso * 1.00);
    final double totaleF24Sospeso = saldoSospeso + accontiSospeso;

    return AppBottomSheet(
      title: 'Stima Tasse P.IVA',
      badgeText: 'Forfettario',
      badgeColor: const Color(0xFF3B82F6),
      child: Container(
        height: screenHeight * 0.55,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 1. PROFILO FISCALE ATECO (RECUPERO DINAMICO DA PROVIDER & DATABASE)
              Builder(
                builder: (context) {
                  final String codiceProv = walletProvider.codiceAteco.isNotEmpty 
                      ? walletProvider.codiceAteco 
                      : widget.codiceAteco;
                  
                  final String codicePulito = codiceProv.split(' ').first.replaceAll('.', '').trim();

                  final atecoMatch = AtecoDatabase.lista.firstWhere(
                    (item) => item['codice'].toString().replaceAll('.', '').trim() == codicePulito,
                    orElse: () => {
                      'codice': codiceProv,
                      'descrizione': 'Attività Professionale',
                      'coeff': walletProvider.coeffRedditivita > 0 ? walletProvider.coeffRedditivita : widget.coefficienteRedditivita,
                    },
                  );

                  final String atecoFormattato = '${atecoMatch['codice']} - ${atecoMatch['descrizione']}';
                  final double coeffEffettivo = (atecoMatch['coeff'] as num?)?.toDouble() ?? walletProvider.coeffRedditivita;
                  final double impostaEffettiva = walletProvider.aliquotaImposta > 0 ? walletProvider.aliquotaImposta : widget.aliquotaImposta;
                  final double inpsEffettiva = walletProvider.aliquotaInps > 0 ? walletProvider.aliquotaInps : widget.aliquotaInps;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 6),
                        _buildSimpleRow('Codice ATECO:', atecoFormattato, isBold: true),
                        _buildSimpleRow('Coeff. Redditività:', '${(coeffEffettivo * 100).toInt()}%'),
                        _buildSimpleRow('Imposta Sostitutiva:', '${(impostaEffettiva * 100).toInt()}%'),
                        _buildSimpleRow('Contributi INPS:', '${(inpsEffettiva * 100).toStringAsFixed(2)}%'),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // 📊 2. RIEPILOGO FISCALE COMPLETO (SPECULARE A 3_5)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RIEPILOGO FISCALE COMPLETO',
                          style: TextStyle(
                            color: Color(0xFF2DD4BF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Icon(Icons.analytics_outlined, color: Color(0xFF2DD4BF), size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSalvaDanaioRow(
                      icon: Icons.add_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Incasso Lordo:',
                      value: '+${_formattaValuta(lordoTotale)}',
                      isBold: true,
                    ),
                    const SizedBox(height: 6),
                    _buildSalvaDanaioRow(
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF2DD4BF),
                      title: 'Netto:',
                      value: '+${_formattaValuta(nettoTotaleReale)}',
                      isBold: true,
                    ),
                    const SizedBox(height: 6),
                    _buildSalvaDanaioRow(
                      icon: Icons.shield_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'Totale Tasse (Saldo + Acconto):',
                      value: '-${_formattaValuta(grandTotaleAccantonare)}',
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withOpacity(0.12), height: 1),
                    const SizedBox(height: 8),
                    _buildSalvaDanaioRow(
                      icon: Icons.remove_circle_outline,
                      color: const Color(0xFFF59E0B),
                      title: 'Totale Saldo (Anno $annoCorrente):',
                      value: '-${_formattaValuta(totaleTasseY)}',
                    ),
                    const SizedBox(height: 6),
                    _buildSalvaDanaioRow(
                      icon: Icons.history_toggle_off_rounded,
                      color: const Color(0xFFF97316),
                      title: 'Totale Acconto (Anno $annoProssimo):',
                      value: '-${_formattaValuta(totaleAccontiY1)}',
                    ),
                  ],
                ),
              ),

              // ⏳ 3. FATTURE EMESSE IN SOSPESO (SE PRESENTI)
              if (lordoSospeso > 0) ...[
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isSospesoEspanso = !_isSospesoEspanso),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'FATTURE EMESSE IN SOSPESO',
                                        style: TextStyle(
                                          color: Color(0xFFF59E0B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${fattureInSospeso.length} fattur${fattureInSospeso.length == 1 ? "a" : "e"} per ${_formattaValuta(lordoSospeso)}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(
                                _isSospesoEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isSospesoEspanso) ...[
                        const Divider(color: Colors.white12, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSimpleRow('Lordo non incassato:', '+${_formattaValuta(lordoSospeso)}', isBold: true),
                              _buildSimpleRow('Imponibile Fiscale Stimato:', _formattaValuta(imponibileSospeso)),
                              _buildSimpleRow('Saldo Tasse Stimato (Anno $annoCorrente):', '-${_formattaValuta(saldoSospeso)}', color: const Color(0xFFF59E0B)),
                              _buildSimpleRow('Acconti Stimati (Anno $annoProssimo):', '-${_formattaValuta(accontiSospeso)}', color: const Color(0xFFF97316)),
                              Divider(color: Colors.white.withOpacity(0.12), height: 10),
                              _buildSimpleRow('Totale Tasse Stimato in Sospeso:', '-${_formattaValuta(totaleF24Sospeso)}', color: const Color(0xFFEF4444), isBold: true),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalvaDanaioRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSimpleRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
          const SizedBox(width: 8),
          Text(
            value,
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