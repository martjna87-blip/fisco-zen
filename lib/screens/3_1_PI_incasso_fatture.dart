import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';

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

              AppNotifications.mostraInAlto(
                context, 'Fattura di "${fattura['cliente']}" eliminata 🎉'
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
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final walletProvider = Provider.of<WalletProvider>(context);

    final fattureAttuali = walletProvider.fattureDaIncassare;
    final contiDisponibili = widget.contiWallet ?? walletProvider.accounts.map((a) => a.title).toList();

    if (_contoSelezionato == null && contiDisponibili.isNotEmpty) {
      _contoSelezionato = contiDisponibili.first;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: isKeyboardOpen ? screenSize.height * 0.88 : screenSize.height * 0.78,
            color: const Color(0xFF141417),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=1000&auto=format&fit=crop',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          const Expanded(
                            child: Text(
                              'Processo di Incasso',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141417).withOpacity(0.75),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
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

                                        final double imponibile = lordo * widget.coefficienteRedditivita;
                                        final double inpsY = imponibile * widget.aliquotaInps;
                                        final double impostaY = imponibile * widget.aliquotaImposta;
                                        final double totaleSaldoY = inpsY + impostaY;

                                        final double accontoInpsY1 = inpsY * 0.80;
                                        final double accontoImpostaY1 = impostaY * 1.00;
                                        final double totaleAccontiY1 = accontoInpsY1 + accontoImpostaY1;

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
                                                          Icon(
                                                            isEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                            color: Colors.white54,
                                                            size: 20,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (isEspansa) ...[
                                                const Divider(color: Colors.white12, height: 1),
                                                Padding(
                                                  padding: const EdgeInsets.all(14),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
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
                                                            _buildDetailRow(Icons.account_balance_wallet_outlined, 'Disponibile Spendibile Netto:', '+${disponibileNetto.toStringAsFixed(2)} €', const Color(0xFF2DD4BF), isBold: true),
                                                            const SizedBox(height: 6),
                                                            _buildDetailRow(Icons.shield_outlined, 'Totale Tasse da Accantonare:', '-${tasseTotaliAccantonare.toStringAsFixed(2)} €', const Color(0xFF3B82F6), isBold: true),
                                                            const Divider(color: Colors.white12, height: 14),
                                                            _buildDetailRow(Icons.remove_circle_outline, 'Saldo Tasse (Anno Y):', '-${totaleSaldoY.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                                                            const SizedBox(height: 6),
                                                            _buildDetailRow(Icons.history_toggle_off_rounded, 'Acconti (Anno Y+1):', '-${totaleAccontiY1.toStringAsFixed(2)} €', const Color(0xFFF97316)),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 14),
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
                                                                    Expanded(
                                                                      child: Row(
                                                                        children: [
                                                                          const Icon(Icons.account_balance_outlined, color: Color(0xFF2DD4BF), size: 16),
                                                                          const SizedBox(width: 8),
                                                                          Expanded(
                                                                            child: Text(
                                                                              _contoSelezionato ?? 'Seleziona un conto',
                                                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 6),
                                                                    Icon(
                                                                      _isTendinaContiAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                                      color: const Color(0xFF2DD4BF),
                                                                      size: 18,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
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
                                                                          Expanded(
                                                                            child: Text(
                                                                              conto,
                                                                              style: TextStyle(
                                                                                color: isSelected ? Colors.white : Colors.white70,
                                                                                fontSize: 12,
                                                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                                              ),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
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
                                                              Expanded(
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DD4BF), size: 15),
                                                                    const SizedBox(width: 8),
                                                                    Expanded(
                                                                      child: Text(
                                                                        _formattaDataInItaliano(_dataSelezionata),
                                                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              const Text('Modifica', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 16),
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

                                                              context.read<WalletProvider>().incassaFatturaPiva(
                                                                idFattura: id,
                                                                cliente: nomeCliente,
                                                                importoLordo: lordo,
                                                                importoTasse: tasseTotaliAccantonare,
                                                                contoDestinazione: _contoSelezionato!,
                                                                dataIncasso: dataFormatted,
                                                              );

                                                              if (widget.onIncasse != null) {
                                                                widget.onIncasse!(
                                                                  id,
                                                                  _contoSelezionato!,
                                                                  lordo,
                                                                  tasseTotaliAccantonare,
                                                                  dataFormatted,
                                                                );
                                                              }

                                                              Navigator.pop(context);
                                                            }
                                                          },
                                                          child: const Text(
                                                            'Conferma Incasso e Accantona',
                                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Center(
                                                        child: TextButton.icon(
                                                          onPressed: () => _confermaEliminazione(context, f),
                                                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 15),
                                                          label: const Text(
                                                            'Elimina questa fattura',
                                                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
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