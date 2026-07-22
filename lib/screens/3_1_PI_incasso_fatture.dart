import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class IncassoFattureSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? fattureDaIncassare;
  final List<String>? contiWallet;
  final double coefficienteRedditivita;
  final double aliquotaImposta;
  final double aliquotaInps;
  final Function(
    String idFattura,
    String contoDestinazione,
    double importoLordo,
    double importoTasse,
    String dataFormattata,
  )? onIncasse;

  const IncassoFattureSheet({
    super.key,
    this.fattureDaIncassare,
    this.contiWallet,
    required this.coefficienteRedditivita,
    required this.aliquotaImposta,
    required this.aliquotaInps,
    this.onIncasse,
  });

  @override
  State<IncassoFattureSheet> createState() => _IncassoFattureSheetState();
}

class _IncassoFattureSheetState extends State<IncassoFattureSheet> {
  String? _fatturaEspansaId;
  String? _contoSelezionato;
  bool _isTendinaContiAperta = false;
  DateTime _dataSelezionata = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.contiWallet != null && widget.contiWallet!.isNotEmpty) {
      _contoSelezionato = widget.contiWallet!.first;
    }
  }

  // DIALOGO DI CONFERMA ED ELIMINAZIONE ISTANTANEA
  void _confermaEliminazione(BuildContext context, Map<String, dynamic> fattura) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Elimina Fattura', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Sei sicuro di voler eliminare la fattura #${fattura['numero'] ?? ''} di "${fattura['cliente']}"?\nL\'azione non potrà essere annullata.',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final String id = fattura['id'] as String;

              // 1. ELIMINA NEL PROVIDER
              Provider.of<WalletProvider>(context, listen: false).eliminaFatturaPiva(id);

              // 2. CHIUDI IL DIALOGO
              Navigator.pop(ctx);

              // 3. RINFRESCA IMMEDIATAMENTE LA SCHERMATA CORRENTE
              setState(() {
                if (_fatturaEspansaId == id) {
                  _fatturaEspansaId = null;
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fattura di "${fattura['cliente']}" eliminata.'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _selezionaData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelezionata,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            visualDensity: VisualDensity.compact,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2DD4BF),
              onPrimary: Colors.black,
              surface: Color(0xFF1F1F23),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF141417),
          ),
          child: Container(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 340,  
                maxHeight: 490,
              ),
              child: child!,
            ),
          ),
        );
      },
    );
    if (picked != null && picked != _dataSelezionata) {
      setState(() {
        _dataSelezionata = picked;
      });
    }
  }

  String _formattaDataInItaliano(DateTime date) {
    final List<String> mesi = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    final String giorno = date.day.toString().padLeft(2, '0');
    final String mese = mesi[date.month - 1];
    return '$giorno $mese ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final walletProvider = Provider.of<WalletProvider>(context);

    // LEGGI SEMPRE LA LISTA AGGIORNATA DAL PROVIDER
    final fattureAttuali = walletProvider.fattureDaIncassare;
    final contiDisponibili = widget.contiWallet ?? walletProvider.accounts.map((a) => a.title).toList();

    if (_contoSelezionato == null && contiDisponibili.isNotEmpty) {
      _contoSelezionato = contiDisponibili.first;
    }

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
              height: screenHeight * 0.85,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=1000&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.40), Colors.black.withOpacity(0.85)],
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
                height: screenHeight * 0.80,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417).withOpacity(0.80),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
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
                              'Processo di Incasso',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // LISTA FATTURE DA INCASSARE
                    Expanded(
                      child: fattureAttuali.isEmpty
                          ? const Center(
                              child: Text(
                                'Nessuna fattura da incassare!',
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: fattureAttuali.length,
                              itemBuilder: (context, index) {
                                final f = fattureAttuali[index];
                                final String id = f['id'] as String;
                                final bool isEspansa = _fatturaEspansaId == id;
                                final double lordo = (f['importo'] as num).toDouble();
                                final String nomeCliente = f['cliente'] as String;

                                // 🧮 CALCOLO FISCALE COMPLETO (SALDO Y + ACCONTI Y+1)
                                final double imponibile = lordo * widget.coefficienteRedditivita;

                                // 1. Tasse Saldo Anno Corrente (Y)
                                final double inpsY = imponibile * widget.aliquotaInps;
                                final double impostaY = imponibile * widget.aliquotaImposta;
                                final double totaleSaldoY = inpsY + impostaY;

                                // 2. Acconti Anno Successivo (Y+1)
                                final double accontoInpsY1 = inpsY * 0.80;       // 80% INPS
                                final double accontoImpostaY1 = impostaY * 1.00;  // 100% Imposta Sostitutiva
                                final double totaleAccontiY1 = accontoInpsY1 + accontoImpostaY1;

                                // 3. Totale da accantonare & Netto Spendibile Reale
                                final double tasseTotaliAccantonare = totaleSaldoY + totaleAccontiY1;
                                final double disponibileNetto = lordo - tasseTotaliAccantonare;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: isEspansa ? Colors.black.withOpacity(0.55) : Colors.black.withOpacity(0.30),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isEspansa ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.08),
                                      width: isEspansa ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // INTESTAZIONE FATTURA
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _fatturaEspansaId = isEspansa ? null : id;
                                            _isTendinaContiAperta = false;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(18),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      nomeCliente,
                                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${f['numero'] ?? ''} • ${f['data'] ?? ''}',
                                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '+${lordo.toStringAsFixed(2)} €',
                                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  // 🗑️ CESTINO INTESTAZIONE (CANCELLAZIONE ISTANTANEA)
                                                  InkWell(
                                                    onTap: () => _confermaEliminazione(context, f),
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEF4444).withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),

                                                  Icon(
                                                    isEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                    color: Colors.white54,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // PROCESSO DI INCASSO ESPANSO
                                      if (isEspansa) ...[
                                        const Divider(color: Colors.white12, height: 1),
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // DETTAGLI INCASSO (LAYOUT CORRETTO SENZA OVERFLOW)
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.35),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(color: Colors.white12),
                                                ),
                                                child: Column(
                                                  children: [
                                                    _buildDetailRow(Icons.add_circle_outline, 'Entrata Incasso Lordo:', '+${lordo.toStringAsFixed(2)} €', const Color(0xFF10B981)),
                                                    const SizedBox(height: 6),
                                                    _buildDetailRow(Icons.remove_circle_outline, 'Saldo Tasse (Anno Y):', '-${totaleSaldoY.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                                                    const SizedBox(height: 6),
                                                    _buildDetailRow(Icons.history_toggle_off_rounded, 'Acconti (Anno Y+1):', '-${totaleAccontiY1.toStringAsFixed(2)} €', const Color(0xFFF97316)),
                                                    const Divider(color: Colors.white12, height: 14),
                                                    _buildDetailRow(Icons.shield_outlined, 'Totale Tasse da Accantonare:', '-${tasseTotaliAccantonare.toStringAsFixed(2)} €', const Color(0xFFEF4444), isBold: true),
                                                    const SizedBox(height: 6),
                                                    _buildDetailRow(Icons.account_balance_wallet_outlined, 'Disponibile Spendibile Netto:', '${disponibileNetto.toStringAsFixed(2)} €', const Color(0xFF2DD4BF), isBold: true),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 14),

                                              // SELEZIONE CONTO A TENDINA IN-LINE
                                              const Text('SELEZIONA CONTO DI ACCREDITO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                              const SizedBox(height: 6),
                                              
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.4),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _isTendinaContiAperta ? const Color(0xFF2DD4BF) : Colors.white12,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    // TESTATA TENDINA
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          _isTendinaContiAperta = !_isTendinaContiAperta;
                                                        });
                                                      },
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(Icons.account_balance_outlined, color: Color(0xFF2DD4BF), size: 16),
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  _contoSelezionato ?? 'Seleziona un conto',
                                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                                                ),
                                                              ],
                                                            ),
                                                            Icon(
                                                              _isTendinaContiAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                              color: const Color(0xFF2DD4BF),
                                                              size: 18,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // ELEMENTI TENDINA APERTA
                                                    if (_isTendinaContiAperta) ...[
                                                      const Divider(color: Colors.white12, height: 1),
                                                      Column(
                                                        children: contiDisponibili.map((conto) {
                                                          final bool isSelected = conto == _contoSelezionato;
                                                          return InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                _contoSelezionato = conto;
                                                                _isTendinaContiAperta = false;
                                                              });
                                                            },
                                                            child: Container(
                                                              width: double.infinity,
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                              color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.15) : Colors.transparent,
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                                                    color: isSelected ? const Color(0xFF2DD4BF) : Colors.white38,
                                                                    size: 16,
                                                                  ),
                                                                  const SizedBox(width: 10),
                                                                  Text(
                                                                    conto,
                                                                    style: TextStyle(
                                                                      color: isSelected ? Colors.white : Colors.white70,
                                                                      fontSize: 12,
                                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

                                              const SizedBox(height: 12),

                                              // DATA INCASSO
                                              const Text('DATA INCASSO FATTURA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: () => _selezionaData(context),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.4),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.white12),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DD4BF), size: 15),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            _formattaDataInItaliano(_dataSelezionata),
                                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                                          ),
                                                        ],
                                                      ),
                                                      const Text('Modifica', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 16),

                                              // PULSANTE CONFERMA INCASSO (A LARGHEZZA PIENA)
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF2DD4BF),
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                    elevation: 0,
                                                  ),
                                                  onPressed: () {
                                                    if (_contoSelezionato != null) {
                                                      final String dataFormatted = _formattaDataInItaliano(_dataSelezionata);

                                                     // 1. INCASSO REALE CON TOTALE COMPLETO DI ACCONTI E DATA SCELTA
                                                      context.read<WalletProvider>().incassaFatturaPiva(
                                                        idFattura: id,
                                                        cliente: nomeCliente,
                                                        importoLordo: lordo,
                                                        importoTasse: tasseTotaliAccantonare,
                                                        contoDestinazione: _contoSelezionato!,
                                                        dataIncasso: dataFormatted,
                                                      );

                                                      // 2. CALLBACK LOCALE SE PRESENTE
                                                      if (widget.onIncasse != null) {
                                                        widget.onIncasse!(
                                                          id,
                                                          _contoSelezionato!,
                                                          lordo,
                                                          tasseTotaliAccantonare,
                                                          dataFormatted,
                                                        );
                                                      }

                                                      // 3. CHIUDI MODALE
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Conferma Incasso e Accantona',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
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

  // HELPER ROW FLESSIBILE SENZA PROBLEMI DI OVERFLOW
  Widget _buildDetailRow(IconData icon, String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isBold ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}