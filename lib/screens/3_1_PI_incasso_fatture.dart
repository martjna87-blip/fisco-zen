import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';

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

  // 🇮🇹 HELPER VALUTA ITALIANA (1.000,00 €)
  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  @override
  void initState() {
    super.initState();
    if (widget.contiWallet != null && widget.contiWallet!.isNotEmpty) {
      _contoSelezionato = widget.contiWallet!.first;
    }
  }

  void _confermaEliminazione(BuildContext context, Map<String, dynamic> fattura) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
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
              Provider.of<WalletProvider>(context, listen: false).eliminaFatturaPiva(id);
              Navigator.pop(ctx);
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2DD4BF),
              onPrimary: Colors.black,
              surface: Color(0xFF18181B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF18181B),
          ),
          child: child!,
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
    final giorno = date.day.toString().padLeft(2, '0');
    final mese = date.month.toString().padLeft(2, '0');
    return '$giorno/$mese/${date.year}';
  }

  bool _isScadutaDaOltre15Giorni(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return false;
    try {
      DateTime? dataFattura;
      if (dataStr.contains('/')) {
        final parts = dataStr.split('/');
        if (parts.length == 3) {
          dataFattura = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (dataStr.contains('-')) {
        dataFattura = DateTime.tryParse(dataStr);
      }
      if (dataFattura != null) {
        return DateTime.now().difference(dataFattura).inDays > 15;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final fattureAttuali = walletProvider.fattureDaIncassare;
    final contiDisponibili = widget.contiWallet ?? walletProvider.accounts.map((a) => a.title).toList();

    if (_contoSelezionato == null && contiDisponibili.isNotEmpty) {
      _contoSelezionato = contiDisponibili.first;
    }

    return AppPopupWrapper(
      title: 'Incasso Fatture',
      badgeText: 'P.IVA',
      badgeColor: const Color(0xFF2DD4BF),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: fattureAttuali.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Nessuna fattura da incassare!',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: fattureAttuali.length,
                itemBuilder: (context, index) {
                  final f = fattureAttuali[index];
                  final String id = f['id'] as String;
                  final bool isEspansa = _fatturaEspansaId == id;
                  final double lordo = (f['importo'] as num).toDouble();
                  final String nomeCliente = f['cliente'] as String;

                  // 📌 CONTROLLO SCADENZA > 15 GIORNI
                  final bool isScaduta = _isScadutaDaOltre15Giorni(f['data']?.toString());

                  // 📌 1. LEGGIAMO IL COEFFICIENTE ATECO SALVATO NELLA SPECIFICA FATTURA
                  // (Se per qualsiasi motivo non c'è, usa come scorta quello principale)
                  final double coefFattura = (f['coefAteco'] as num?)?.toDouble() ?? widget.coefficienteRedditivita;

                  // 📌 2. CALCOLIAMO L'IMPONIBILE USANDO IL SUO ATECO CORRETTO
                  final double imponibile = lordo * coefFattura;
                  final double inpsY = imponibile * widget.aliquotaInps;
                  final double impostaY = imponibile * widget.aliquotaImposta;
                  final double totaleSaldoY = inpsY + impostaY;

                  final double accontoInpsY1 = inpsY * 0.80;
                  final double accontoImpostaY1 = impostaY * 1.00;
                  final double totaleAccontiY1 = accontoInpsY1 + accontoImpostaY1;

                  final double tasseTotaliAccantonare = totaleSaldoY + totaleAccontiY1;

                  // 📌 3. CALCOLO PRUDENZIALE CUSCINETTO & NETTO SPENDIBILE REALE
                  final int mesiLavorati = walletProvider.mesiAttivi > 0 ? walletProvider.mesiAttivi : 10;
                  final double percentualeFondoFerie = (12 - mesiLavorati) / 12;
                  
                  final double nettoDopoTasse = lordo - tasseTotaliAccantonare;
                  final double quotaFondoFerie = nettoDopoTasse * percentualeFondoFerie;
                  final double disponibileNetto = nettoDopoTasse - quotaFondoFerie;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isScaduta
                          ? const Color(0xFFEF4444).withOpacity(0.08)
                          : Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEspansa
                            ? const Color(0xFF2DD4BF)
                            : (isScaduta
                                ? const Color(0xFFEF4444).withOpacity(0.65)
                                : Colors.white.withOpacity(0.08)),
                        width: isScaduta && !isEspansa ? 1.2 : 1,
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
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              nomeCliente,
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isScaduta) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 11),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    '> 15 gg',
                                                    style: TextStyle(
                                                      color: Color(0xFFEF4444),
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${f['numero'] != null && f['numero'].toString().isNotEmpty ? "#${f['numero']} • " : ""}${f['data'] ?? ''}',
                                        style: TextStyle(
                                          color: isScaduta ? const Color(0xFFEF4444).withOpacity(0.9) : Colors.white54,
                                          fontSize: 11,
                                          fontWeight: isScaduta ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '+${_formattaValuta(lordo)}',
                                      style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: const Color(0xFF2DD4BF),
                                      size: 18,
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
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Column(
                                    children: [
                                      // 1. INCASSO LORDO (#10B981)
                                      _buildDetailRow(
                                        Icons.add_circle_outline,
                                        'Incasso Lordo:',
                                        '+${_formattaValuta(lordo)}',
                                        const Color(0xFF10B981),
                                        isBold: true,
                                      ),
                                      const SizedBox(height: 6),

                                      // 2. NETTO SPENDIBILE (#2DD4BF)
                                      _buildDetailRow(
                                        Icons.account_balance_wallet_outlined,
                                        'Netto Spendibile:',
                                        '+${_formattaValuta(disponibileNetto)}',
                                        const Color(0xFF2DD4BF),
                                        isBold: true,
                                      ),
                                      const SizedBox(height: 6),

                                      // 3. TASSE (SALDO + ACCONTO) (#3B82F6)
                                      _buildDetailRow(
                                        Icons.shield_outlined,
                                        'Tasse (Saldo + Acconto):',
                                        '-${_formattaValuta(tasseTotaliAccantonare)}',
                                        const Color(0xFF3B82F6),
                                        isBold: true,
                                      ),
                                      const SizedBox(height: 6),

                                      // 4. CUSCINETTO MESI NO-LAVORO (#8B5CF6)
                                      _buildDetailRow(
                                        Icons.beach_access_rounded,
                                        'Cuscinetto mesi No-Lavoro ($mesiLavorati Mesi):',
                                        '-${_formattaValuta(quotaFondoFerie)}',
                                        const Color(0xFF8B5CF6),
                                      ),

                                      const Divider(color: Colors.white12, height: 14),

                                      // CALCOLO ANNO CORRENTE E SUCCESSIVO
                                      _buildDetailRow(
                                        Icons.remove_circle_outline,
                                        'Saldo Tasse (Anno ${_dataSelezionata.year}):',
                                        '-${_formattaValuta(totaleSaldoY)}',
                                        const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildDetailRow(
                                        Icons.history_toggle_off_rounded,
                                        'Acconti (Anno ${_dataSelezionata.year + 1}):',
                                        '-${_formattaValuta(totaleAccontiY1)}',
                                        const Color(0xFFF97316),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('SELEZIONA CONTO DI ACCREDITO', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isTendinaContiAperta ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.1),
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
                                const Text('DATA INCASSO FATTURA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _selezionaData(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                                  height: 46,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2DD4BF),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      if (_contoSelezionato != null) {
                                        final String dataFormatted = _formattaDataInItaliano(_dataSelezionata);
                                        
                                        // 1. Eseguiamo l'incasso nel provider
                                        context.read<WalletProvider>().incassaFatturaPiva(
                                          idFattura: id,
                                          cliente: nomeCliente,
                                          importoLordo: lordo,
                                          importoTasse: tasseTotaliAccantonare,
                                          contoDestinazione: _contoSelezionato!,
                                          dataIncasso: dataFormatted,
                                        );

                                        // 2. Chiamiamo la callback esterna se presente
                                        if (widget.onIncasse != null) {
                                          widget.onIncasse!(
                                            id,
                                            _contoSelezionato!,
                                            lordo,
                                            tasseTotaliAccantonare,
                                            dataFormatted,
                                          );
                                        }

                                        // 3. Ripristiniamo la UI per le prossime fatture
                                        setState(() {
                                          _fatturaEspansaId = null;
                                        });

                                        // 4. Se ne restano altre, mostriamo solo una notifica e restiamo nello sheet.
                                        // Altrimenti (la lista ora è vuota), chiudiamo la schermata!
                                        final rimanenti = context.read<WalletProvider>().fattureDaIncassare.length;
                                        if (rimanenti > 0) {
                                          AppNotifications.mostraInAlto(
                                            context,
                                            'Fattura di "$nomeCliente" incassata con successo! 🎉',
                                          );
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Conferma Incasso',
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
    );
  }

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