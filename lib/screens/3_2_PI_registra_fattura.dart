import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '../widgets_shared/app_datepicker.dart';
import '../screens/0_1_pro_upgrade.dart';
import 'package:image_picker/image_picker.dart';
import '../services/document_scanner_service.dart';
import '../widgets_shared/app_image_picker.dart';
import '../data/ateco_database.dart'; // 👈 ECCO IL COLLEGAMENTO AL DATABASE CENTRALIZZATO!

// 🇮🇹 FORMATTATORE VALUTA ITALIANA (1.000,00)
class ItalianCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    int firstCommaIndex = cleanText.indexOf(',');
    if (firstCommaIndex != -1) {
      cleanText = cleanText.substring(0, firstCommaIndex + 1) +
          cleanText.substring(firstCommaIndex + 1).replaceAll(',', '');
      List<String> parts = cleanText.split(',');
      if (parts.length > 1 && parts[1].length > 2) {
        cleanText = '${parts[0]},${parts[1].substring(0, 2)}';
      }
    }

    List<String> parts = cleanText.split(',');
    String intPart = parts[0];
    String decPart = parts.length > 1 ? ',${parts[1]}' : (cleanText.endsWith(',') ? ',' : '');

    if (intPart.length > 1 && intPart.startsWith('0')) {
      intPart = intPart.replaceFirst(RegExp(r'^0+'), '');
      if (intPart.isEmpty) intPart = '0';
    }

    String formattedInt = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      count++;
      formattedInt = intPart[i] + formattedInt;
      if (count % 3 == 0 && i != 0) {
        formattedInt = '.$formattedInt';
      }
    }

    String finalString = formattedInt + decPart;
    return TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }
}

class RegistraFatturaSheet extends StatefulWidget {
  final Function(String cliente, double importo, String dataFormattata)? onFatturaSalvata;

  const RegistraFatturaSheet({
    super.key,
    this.onFatturaSalvata,
  });

  @override
  State<RegistraFatturaSheet> createState() => _RegistraFatturaSheetState();
}

class _RegistraFatturaSheetState extends State<RegistraFatturaSheet> {
  final _numeroController = TextEditingController();
  final _clienteController = TextEditingController();
  final _importoController = TextEditingController();
  final _searchAtecoController = TextEditingController();

  final _pivaClienteController = TextEditingController();
  final _codiceSdiController = TextEditingController();
  final _descrizioneController = TextEditingController();
  bool _inviaSdi = false;

  DateTime _dataSelezionata = DateTime.now();
  bool _isAtecoEspanso = false;

  String _defaultAtecoCodice = '74.10.21';
  double _defaultAtecoCoef = 0.78;

  late double _atecoCoef;
  late String _atecoCodice;
  late String _atecoNome;

  bool _initializedAteco = false;
  bool _calcolaAncheAccontoF24 = true;

  @override
  void initState() {
    super.initState();
    _importoController.addListener(_aggiornaCalcoli);
  }

  void _aggiornaCalcoli() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedAteco) {
      final wallet = Provider.of<WalletProvider>(context, listen: false);

      try {
        _defaultAtecoCodice = wallet.codiceAteco.split(' ').first.trim();
      } catch (_) {
        _defaultAtecoCodice = '74.10.21';
      }

      if (wallet.coeffRedditivita > 0) {
        _defaultAtecoCoef = wallet.coeffRedditivita;
      }

      _atecoCoef = _defaultAtecoCoef;
      _atecoCodice = _defaultAtecoCodice;

      // 👇 USIAMO IL NUOVO DATABASE PER CERCARE IL NOME INIZIALE
      final matchIniziale = AtecoDatabase.lista.firstWhere(
        (item) => item['codice'] == _atecoCodice,
        orElse: () => {'descrizione': 'Consulenza & Digital'},
      );
      _atecoNome = '$_atecoCodice - ${matchIniziale['descrizione']} (${(_atecoCoef * 100).toInt()}%)';

      _initializedAteco = true;
    }
  }

  @override
  void dispose() {
    _importoController.removeListener(_aggiornaCalcoli);
    _numeroController.dispose();
    _clienteController.dispose();
    _importoController.dispose();
    _searchAtecoController.dispose();
    _pivaClienteController.dispose();
    _codiceSdiController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _selezionaData(BuildContext context) async {
    final DateTime? picked = await AppDatePicker.selezionaData(
      context,
      dataIniziale: _dataSelezionata,
    );
    if (picked != null && picked != _dataSelezionata) {
      setState(() {
        _dataSelezionata = picked;
      });
    }
  }

  String _formattaData(DateTime dt) {
    final giorno = dt.day.toString().padLeft(2, '0');
    final mese = dt.month.toString().padLeft(2, '0');
    return '$giorno/$mese/${dt.year}';
  }

  void _salvaFattura() {
    final numero = _numeroController.text.trim();
    final cliente = _clienteController.text.trim();
    final importoText = _importoController.text.trim();

    if (cliente.isEmpty || importoText.isEmpty) {
      AppNotifications.mostraInAlto(
        context,
        'Inserisci nome cliente e importo valido',
        type: NotificationType.warning,
      );
      return;
    }

    final double? importo = double.tryParse(importoText.replaceAll('.', '').replaceAll(',', '.'));
    if (importo == null || importo <= 0) {
      AppNotifications.mostraInAlto(
        context,
        'Importo non valido',
        type: NotificationType.error,
      );
      return;
    }

    final double imponibile = importo * _atecoCoef;
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final double aliquotaTasse = wallet.aliquotaImposta > 0 ? wallet.aliquotaImposta : 0.05;
    const double aliquotaInps = 0.2607;

    final double saldoImposta = imponibile * aliquotaTasse;
    final double saldoInps = imponibile * aliquotaInps;
    final double totaleSaldo = saldoImposta + saldoInps;
    final double totaleAcconto = (saldoImposta * 1.00) + (saldoInps * 0.80);
    final double totaleF24 = _calcolaAncheAccontoF24 ? (totaleSaldo + totaleAcconto) : totaleSaldo;

    final dataFormattata = _formattaData(_dataSelezionata);

    Provider.of<WalletProvider>(context, listen: false).addFatturaPiva(
      cliente: cliente,
      importo: importo,
      data: dataFormattata,
      numero: numero.isNotEmpty ? numero : null,
      coefAteco: _atecoCoef,
      importoTasseStimate: totaleF24,
      inviaSdi: _inviaSdi,
      pivaCliente: _pivaClienteController.text.trim(),
      codiceSdiPec: _codiceSdiController.text.trim(),
      descrizione: _descrizioneController.text.trim(),
    );

    if (widget.onFatturaSalvata != null) {
      try {
        widget.onFatturaSalvata!(cliente, importo, dataFormattata);
      } catch (_) {}
    }

    Navigator.pop(context);

    AppNotifications.mostraInAlto(
      context,
      'Fattura ${numero.isNotEmpty ? "#$numero " : ""}di $cliente del $dataFormattata registrata! 🎉',
    );
  }
  
  Future<void> _scattaFoto() async {
    final XFile? photo = await AppImagePickerSheet.mostra(
      context,
      titolo: 'Scansiona Fattura',
    );

    if (photo != null) {
      AppNotifications.mostraInAlto(
        context,
        '🔍 Lettura del documento in corso...',
        type: NotificationType.warning,
      );

      try {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        
        final result = await DocumentScannerService.scanDocument(
          imagePath: photo.path,
          wallet: walletProvider,
        );

        setState(() {
          if (result.importo != null) {
            _importoController.text = result.importo!.toStringAsFixed(2).replaceAll('.', ',');
          }
          if (result.piva != null && result.piva!.isNotEmpty) {
            _pivaClienteController.text = result.piva!;
            _inviaSdi = true; 
          }
          if (result.ragioneSociale != null && result.ragioneSociale!.isNotEmpty) {
            _clienteController.text = result.ragioneSociale!;
          }
          if (result.data != null) {
            _dataSelezionata = result.data!;
          }
        });

        final messaggio = result.metodoUsato == 'AI_VISION'
            ? '🤖 Documento analizzato con AI Vision Pro!'
            : '⚡ Dati estratti con scansione rapida.';

        AppNotifications.mostraInAlto(context, messaggio, type: NotificationType.success);

      } catch (e) {
        debugPrint('Errore scansione: $e');
        AppNotifications.mostraInAlto(
          context,
          'Non sono riuscito a leggere bene la foto. Riprova!',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentSelectedDefault = (_atecoCodice == _defaultAtecoCodice);
    final double importoInserito = double.tryParse(_importoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    final bool richiedeBollo = importoInserito > 77.47;

    return AppBottomSheet(
      title: 'Registra Fattura',
      badgeText: 'P.IVA',
      badgeColor: const Color(0xFF2DD4BF),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 HEADER: INSERIMENTO MANUALE VS SCANNER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INSERIMENTO MANUALE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final wallet = Provider.of<WalletProvider>(context, listen: false);
                    if (!wallet.canUseOCR) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProUpgradeSheet(funzionalita: 'Scansione OCR')));
                    } else {
                      await _scattaFoto(); 
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Consumer<WalletProvider>(
                    builder: (context, wallet, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.document_scanner_rounded, color: Color(0xFF2DD4BF), size: 14),
                            const SizedBox(width: 6),
                            const Text('Scansiona OCR', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                            if (!wallet.canUseOCR) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text('PRO', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
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
            const SizedBox(height: 12),

            // N° FATTURA + DATA 
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numeroController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _buildInputDecoration('N° Fattura', Icons.tag_rounded),
                  ),
                ),
                const SizedBox(width: 12), 
                Expanded(
                  child: InkWell(
                    onTap: () => _selezionaData(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), 
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)), 
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DD4BF), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formattaData(_dataSelezionata),
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // CLIENTE
            TextField(
              controller: _clienteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _buildInputDecoration('Nome Cliente / Azienda', Icons.person_outline),
            ),
            const SizedBox(height: 10),

            // IMPORTO LORDO
            TextField(
              controller: _importoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [ItalianCurrencyFormatter()],
              style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.bold),
              decoration: _buildInputDecoration('Importo Lordo (€)', Icons.euro_symbol_rounded),
            ),

            // SELETTORE ATECO INLINE
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAtecoEspanso ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isAtecoEspanso = !_isAtecoEspanso;
                        if (!_isAtecoEspanso) _searchAtecoController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.category_rounded, color: Color(0xFF2DD4BF), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _atecoNome,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis, 
                            ),
                          ),
                          if (isCurrentSelectedDefault) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Color(0xFF2DD4BF), size: 16),
                            const SizedBox(width: 6),
                          ],
                          Icon(
                            _isAtecoEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF2DD4BF),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isAtecoEspanso) ...[
                    const Divider(color: Colors.white12, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: TextField(
                              controller: _searchAtecoController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Cerca codice ATECO o mansione...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                icon: Icon(Icons.search_rounded, color: Color(0xFF2DD4BF), size: 16),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: ListView(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              children: (() {
                                final query = _searchAtecoController.text.toLowerCase().replaceAll('.', '').trim();
                                
                                // 👇 FILTRIAMO DALLA LISTA CENTRALIZZATA!
                                final atecoFiltrati = AtecoDatabase.lista.where((item) {
                                  return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(query) ||
                                      item['descrizione'].toString().toLowerCase().contains(query);
                                }).toList();

                                if (atecoFiltrati.isEmpty) {
                                  return [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: Text('Nessun codice ATECO trovato', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                      ),
                                    ),
                                  ];
                                }

                                return atecoFiltrati.map((item) {
                                  final double coef = (item['coef'] as num).toDouble();
                                  final String codice = item['codice'].toString();
                                  final String nomeFmt = '$codice - ${item['descrizione']} (${(coef * 100).toInt()}%)';
                                  final bool isSelected = codice == _atecoCodice;
                                  final bool isDefaultAteco = codice == _defaultAtecoCodice;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _atecoCoef = coef;
                                        _atecoCodice = codice;
                                        _atecoNome = nomeFmt;
                                        _isAtecoEspanso = false;
                                        _searchAtecoController.clear();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.12) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white38,
                                            size: 15,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              nomeFmt,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.white70,
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isDefaultAteco) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified_rounded, color: Color(0xFF2DD4BF), size: 15),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList();
                              })(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // TOGGLE FATTURAZIONE ELETTRONICA SDI
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _inviaSdi ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Consumer<WalletProvider>(
                            builder: (context, wallet, child) {
                              return Row(
                                children: [
                                  Icon(Icons.send_rounded, color: _inviaSdi ? const Color(0xFF2DD4BF) : Colors.white54, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Invia allo SDI', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  if (!wallet.canSendSDI) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD946EF),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      Switch(
                        value: _inviaSdi,
                        activeColor: const Color(0xFF2DD4BF),
                        activeTrackColor: const Color(0xFF2DD4BF).withOpacity(0.3),
                        inactiveThumbColor: Colors.white70,
                        inactiveTrackColor: Colors.white12, 
                        onChanged: (val) {
                          final wallet = Provider.of<WalletProvider>(context, listen: false);
                          if (!wallet.canSendSDI && val) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProUpgradeSheet(funzionalita: 'Fatturazione Elettronica SDI')));
                          } else {
                            setState(() => _inviaSdi = val);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_inviaSdi) ...[
                    const Divider(color: Colors.white12, height: 12),
                    TextField(controller: _pivaClienteController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _buildInputDecoration('P.IVA / Codice Fiscale Cliente', Icons.badge_outlined)),
                    const SizedBox(height: 8),
                    TextField(controller: _codiceSdiController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _buildInputDecoration('Codice SDI (7 cifre) o PEC', Icons.mark_email_read_outlined)),
                    const SizedBox(height: 8),
                    TextField(controller: _descrizioneController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _buildInputDecoration('Descrizione Prestazione', Icons.description_outlined)),
                    
                    if (richiedeBollo) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sticky_note_2_rounded, color: Color(0xFF3B82F6), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Marca da Bollo Virtuale di 2,00 € inserita in fattura (obbligatoria per importi > 77,47 €)',
                                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // CARD RIPARTIZIONE PREVIEW
            _buildRipartizionePreviewCard(context),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _salvaFattura,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Registra e Salva Fattura',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  Widget _buildRipartizionePreviewCard(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);
    final double importoLordo = double.tryParse(_importoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

    if (importoLordo <= 0) return const SizedBox.shrink();

    final double imponibile = importoLordo * _atecoCoef;
    final double aliquotaTasse = wallet.aliquotaImposta > 0 ? wallet.aliquotaImposta : 0.05;
    const double aliquotaInps = 0.2607;

    final double saldoImposta = imponibile * aliquotaTasse;
    final double saldoInps = imponibile * aliquotaInps;
    final double totaleSaldo = saldoImposta + saldoInps;

    final double accontoImposta = saldoImposta * 1.00;
    final double accontoInps = saldoInps * 0.80;
    final double totaleAcconto = accontoImposta + accontoInps;

    final double totaleF24 = _calcolaAncheAccontoF24 ? (totaleSaldo + totaleAcconto) : totaleSaldo;
    final double nettoDopoTasse = importoLordo - totaleF24;

    final int mesiLavorati = wallet.mesiAttivi > 0 ? wallet.mesiAttivi : 10;
    final double percentualeFondoFerie = (12 - mesiLavorati) / 12;
    final double quotaFondoFerie = nettoDopoTasse * percentualeFondoFerie;
    final double nettoSpendibileSubito = nettoDopoTasse - quotaFondoFerie;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RIPARTIZIONE F24 & CUSCINETTO',
                style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              GestureDetector(
                onTap: () => setState(() => _calcolaAncheAccontoF24 = !_calcolaAncheAccontoF24),
                child: Text(
                  _calcolaAncheAccontoF24 ? 'Incl. Acconti (100% Tasse / 80% INPS)' : 'Solo Saldo Anno Corrente',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildSalvaDanaioRow(
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF10B981),
            title: 'Incasso Lordo:',
            value: '+${_formattaValuta(importoLordo)}',
            isBold: true,
          ),
          const SizedBox(height: 6),

          _buildSalvaDanaioRow(
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF2DD4BF),
            title: 'Netto Spendibile:',
            value: '+${_formattaValuta(nettoSpendibileSubito)}',
            isBold: true,
          ),
          const SizedBox(height: 6),

          _buildSalvaDanaioRow(
            icon: Icons.shield_rounded,
            color: const Color(0xFF3B82F6),
            title: _calcolaAncheAccontoF24 ? 'Tasse (Saldo + Acconto):' : 'Tasse (Solo Saldo):',
            value: '-${_formattaValuta(totaleF24)}',
            isBold: true,
          ),
          const SizedBox(height: 6),

          _buildSalvaDanaioRow(
            icon: Icons.beach_access_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Cuscinetto mesi No-Lavoro ($mesiLavorati Mesi):',
            value: '-${_formattaValuta(quotaFondoFerie)}',
          ),
        ],
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
            style: TextStyle(color: isBold ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
      prefixIcon: Icon(icon, color: const Color(0xFF2DD4BF), size: 18),
      filled: true,
      fillColor: Colors.black.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}