import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class F24FacsimileSheet extends StatelessWidget {
  const F24FacsimileSheet({super.key});

  static String _formattaEuro(double valore) {
    List<String> parti = valore.abs().toStringAsFixed(2).split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String interiFormattati = parti[0].replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '${valore < 0 ? '-' : ''}$interiFormattati,${parti[1]} €';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final int annoCorrente = DateTime.now().year;
    final int annoSuccessivo = annoCorrente + 1;

    final double fatturatoReale = provider.fatturatoTotale;
    final double imponibileReale = fatturatoReale * provider.coeffRedditivita;

    final double inpsSaldo = imponibileReale * provider.aliquotaInps;
    final double impostaSaldo = imponibileReale * provider.aliquotaImposta;

    final double inpsAcconto = inpsSaldo * 0.80;
    final double impostaAcconto = impostaSaldo * 1.00;

    final double accontiVersati = provider.accontiVersati;

    final double totaleDebiti = inpsSaldo + impostaSaldo + inpsAcconto + impostaAcconto;
    final double totaleCrediti = accontiVersati;
    final double saldoFinaleF24 = (totaleDebiti - totaleCrediti).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF121619),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MODELLO F24 (FACSIMILE)',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prospetto di liquidazione su incassato reale ($annoCorrente)',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSezioneHeader('SEZIONE ERARIO (IMPOSTA SOSTITUTIVA)', const Color(0xFF2DD4BF)),
            _buildF24TabellaHeader(),
            _buildF24Riga(
              codice: '1792',
              descrizione: 'Saldo Imposta Sostitutiva $annoCorrente',
              anno: '$annoCorrente',
              debito: impostaSaldo,
              credito: 0.0,
            ),
            _buildF24Riga(
              codice: '1790',
              descrizione: '1ª Rata Acconto Imposta $annoSuccessivo',
              anno: '$annoSuccessivo',
              debito: impostaAcconto * 0.50,
              credito: 0.0,
            ),
            _buildF24Riga(
              codice: '1791',
              descrizione: '2ª Rata Acconto Imposta $annoSuccessivo',
              anno: '$annoSuccessivo',
              debito: impostaAcconto * 0.50,
              credito: 0.0,
            ),

            const SizedBox(height: 16),

            _buildSezioneHeader('SEZIONE INPS (GESTIONE SEPARATA)', const Color(0xFF3B82F6)),
            _buildF24TabellaHeader(),
            _buildF24Riga(
              codice: provider.hasDipendente ? 'C10' : 'P10',
              descrizione: 'Saldo Contributi INPS $annoCorrente',
              anno: '$annoCorrente',
              debito: inpsSaldo,
              credito: 0.0,
            ),
            _buildF24Riga(
              codice: provider.hasDipendente ? 'C20' : 'P20',
              descrizione: 'Acconto Contributi INPS $annoSuccessivo',
              anno: '$annoSuccessivo',
              debito: inpsAcconto,
              credito: 0.0,
            ),

            const SizedBox(height: 16),

            if (totaleCrediti > 0) ...[
              _buildSezioneHeader('COMPENSAZIONI E ACCONTI GIÀ VERSATI', const Color(0xFFF59E0B)),
              _buildF24TabellaHeader(),
              _buildF24Riga(
                codice: 'ACC',
                descrizione: 'Acconti F24 dichiarati anno precedente',
                anno: '${annoCorrente - 1}',
                debito: 0.0,
                credito: totaleCrediti,
                isCreditoHighlight: true,
              ),
              const SizedBox(height: 16),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Totale Importi a Debito:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(_formattaEuro(totaleDebiti), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Totale Importi a Credito / Compensati:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('- ${_formattaEuro(totaleCrediti)}', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SALDO FINALE F24 (DA VERSARE):', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        _formattaEuro(saldoFinaleF24),
                        style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSezioneHeader(String titolo, Color colore) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        titolo,
        style: TextStyle(color: colore, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildF24TabellaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50, child: Text('CODICE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold))),
          Expanded(child: Text('CAUSALE / DESCRIZIONE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold))),
          SizedBox(width: 45, child: Text('ANNO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 75, child: Text('DEBITO (€)', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildF24Riga({
    required String codice,
    required String descrizione,
    required String anno,
    required double debito,
    required double credito,
    bool isCreditoHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(codice, style: TextStyle(color: isCreditoHighlight ? const Color(0xFFF59E0B) : const Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(descrizione, style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 11), overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 45,
            child: Text(anno, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 75,
            child: Text(
              debito > 0 ? _formattaEuro(debito) : '- ${_formattaEuro(credito)}',
              style: TextStyle(
                color: isCreditoHighlight ? const Color(0xFFEF4444) : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}