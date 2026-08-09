import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_datepicker.dart';
import '../screens/0_1_pro_upgrade.dart';

// 🇮🇹 FORMATTATORE IN TEMPO REALE PER VALUTA ITALIANA (1.000,00)
class ItalianCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

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

  // 🔒 ATECO PREDEFINITO (Fisso dall'Onboarding)
  String _defaultAtecoCodice = '74.10.21';
  double _defaultAtecoCoef = 0.78;

  // 🗂️ ATECO TEMPORANEO (Selezionato per questa specifica fattura)
  late double _atecoCoef;
  late String _atecoCodice;
  late String _atecoNome;
  
  bool _initializedAteco = false;
  bool _calcolaAncheAccontoF24 = true;

  final List<Map<String, dynamic>> _databaseAteco = [
    {'codice': '74.10.21', 'descrizione': 'Graphic design, Web design, UI/UX', 'coef': 0.78},
    {'codice': '62.01.00', 'descrizione': 'Sviluppo software e programmazione', 'coef': 0.78},
    {'codice': '70.22.09', 'descrizione': 'Consulenza imprenditoriale e gestionale', 'coef': 0.78},
    {'codice': '73.11.02', 'descrizione': 'Marketing, Social Media e Advertising', 'coef': 0.78},
    {'codice': '85.52.09', 'descrizione': 'Formazione culturale e corsi', 'coef': 0.78},
    {'codice': '47.91.10', 'descrizione': 'Commercio al dettaglio (E-commerce)', 'coef': 0.67},
    {'codice': '56.10.11', 'descrizione': 'Ristoranti, Pizzerie, Bar', 'coef': 0.40},
    {'codice': '96.02.01', 'descrizione': 'Servizi dei saloni e personal care', 'coef': 0.40},
  ];

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
      
      // 1. Leggiamo il codice ATECO salvato nel provider (fallback sicuro)
      try {
        _defaultAtecoCodice = wallet.codiceAteco.split(' ').first.trim();
      } catch (_) {
        _defaultAtecoCodice = '74.10.21';
      }

      if (wallet.coeffRedditivita > 0) {
        _defaultAtecoCoef = wallet.coeffRedditivita;
      }

      // 2. Impostiamo l'ATECO iniziale della fattura uguale al predefinito
      _atecoCoef = _defaultAtecoCoef;
      _atecoCodice = _defaultAtecoCodice;
      
      final matchIniziale = _databaseAteco.firstWhere(
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

  // 🔍 MODALE SELEZIONE ATECO (TAG PREDEFINITO BLOCATO SUL PROFILO)
  void _apriSelettoreAteco() {
    _searchAtecoController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _searchAtecoController.text.toLowerCase().replaceAll('.', '').trim();
            final atecoFiltrati = _databaseAteco.where((item) {
              return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(query) || 
                     item['descrizione'].toString().toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Seleziona ATECO Fattura', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // CAMPO DI RICERCA
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _searchAtecoController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (v) => setModalState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Cerca per codice o professione...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                        icon: Icon(Icons.search_rounded, color: Color(0xFF2DD4BF), size: 18),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // LISTA RISULTATI (IL TAG PREDEFINITO RIMANE FISSO SULL'ATECO ONBOARDING)
                  Expanded(
                    child: ListView.separated(
                      itemCount: atecoFiltrati.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final item = atecoFiltrati[index];
                        final double coef = (item['coef'] as num).toDouble();
                        final String codice = item['codice'].toString();
                        
                        // 📌 IL TAG RIGUARDA ESCLUSIVAMENTE IL CODICE PREDEFINITO DELL'ONBOARDING
                        final bool isDefaultAteco = (codice == _defaultAtecoCodice);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            setState(() {
                              _atecoCoef = coef;
                              _atecoCodice = codice;
                              _atecoNome = '$codice - ${item['descrizione']} (${(coef * 100).toInt()}%)';
                            });
                            Navigator.pop(ctx);
                          },
                          title: Row(
                            children: [
                              Text(item['codice'], style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                                child: Text('${(coef * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              if (isDefaultAteco) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    'PREDEFINITO',
                                    style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(item['descrizione'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

    // Rimuove i punti delle migliaia e converte la virgola in punto per il calcolo matematico
    final double? importo = double.tryParse(importoText.replaceAll('.', '').replaceAll(',', '.'));
    if (importo == null || importo <= 0) {
      AppNotifications.mostraInAlto(
        context, 
        'Importo non valido', 
        type: NotificationType.error
      );
      return;
    }

    // 🧮 CALCOLO ESATTO DELLE TASSE CON L'ATECO SCELTO PER QUESTA FATTURA
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

    // 💾 SALVIAMO INSIEME ALLA FATTURA ANCHE IL SUO ATECO E LE SUE TASSE ESATTE
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
      context, 'Fattura ${numero.isNotEmpty ? "#$numero " : ""}di $cliente del $dataFormattata registrata! 🎉'
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verifichiamo se l'ATECO attualmente selezionato per la fattura è quello predefinito
    final bool isCurrentSelectedDefault = (_atecoCodice == _defaultAtecoCodice);

    return AppPopupWrapper(
      title: 'Registra Fattura',
      badgeText: 'P.IVA',
      badgeColor: const Color(0xFF2DD4BF),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 INTESTAZIONE CON GANCO FOTOCAMERA OCR (Stile Canva PRO)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INSERIMENTO MANUALE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final wallet = Provider.of<WalletProvider>(context, listen: false);
                    if (!wallet.canUseOCR) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProUpgradeSheet(funzionalita: 'Scansione OCR')));
                    } else {
                      AppNotifications.mostraInAlto(context, 'Scansione in attivazione... 📸');
                    }
                  },
                  child: Consumer<WalletProvider>(
                    builder: (context, wallet, child) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            // 👈 QUESTO MARGINE CREA LO SPAZIO FISICO PER IL BADGE
                            margin: const EdgeInsets.only(top: 8, right: 8), 
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.document_scanner_rounded, color: Colors.white70, size: 16),
                          ),
                          // 👑 Coroncina ARANCIONE visibile se NON hai il Pro
                          if (!wallet.canUseOCR)
                            Positioned(
                              top: 0, // 👈 Ora sta a zero, appoggiato sul margine creato sopra
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF18181B), width: 2),
                                ),
                                child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 12),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numeroController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _buildInputDecoration('N° Fattura', Icons.tag_rounded),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selezionaData(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DD4BF), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formattaData(_dataSelezionata),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
            TextField(
              controller: _clienteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _buildInputDecoration('Nome Cliente / Azienda', Icons.person_outline),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _importoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [ItalianCurrencyFormatter()],
              style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.bold),
              decoration: _buildInputDecoration('Importo Lordo (€)', Icons.euro_symbol_rounded),
            ),
            
            // 🏷️ SELETTORE ATECO FATTURA INLINE CON RICERCA E BADGE VERIFIED
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isAtecoEspanso ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isAtecoEspanso = !_isAtecoEspanso;
                        if (!_isAtecoEspanso) {
                          _searchAtecoController.clear();
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.category_rounded, color: Color(0xFF2DD4BF), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _atecoNome,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentSelectedDefault) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Codice ATECO Predefinito Profilo',
                              triggerMode: TooltipTriggerMode.tap,
                              child: Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF2DD4BF),
                                size: 16,
                              ),
                            ),
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
                          // 🔍 CAMPO RICERCA INTEGRATO NELLA TENDINA
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
                          
                          // LISTA FILTRATA
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              children: (() {
                                final query = _searchAtecoController.text.toLowerCase().replaceAll('.', '').trim();
                                final atecoFiltrati = _databaseAteco.where((item) {
                                  return item['codice'].toString().toLowerCase().replaceAll('.', '').contains(query) || 
                                         item['descrizione'].toString().toLowerCase().contains(query);
                                }).toList();

                                if (atecoFiltrati.isEmpty) {
                                  return [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: Text(
                                          'Nessun codice ATECO trovato',
                                          style: TextStyle(color: Colors.white38, fontSize: 11),
                                        ),
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
                                            const Tooltip(
                                              message: 'Codice Predefinito Profilo',
                                              triggerMode: TooltipTriggerMode.tap,
                                              child: Icon(
                                                Icons.verified_rounded,
                                                color: Color(0xFF2DD4BF),
                                                size: 15,
                                              ),
                                            ),
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

            // ⚡ TOGGLE FATTURAZIONE ELETTRONICA SDI (FASCIA PREMIUM)
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _inviaSdi ? const Color(0xFF2DD4BF) : Colors.white12,
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
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Padding(
                                    // 👈 SPAZIO FISICO PER IL BADGE FUCSIA
                                    padding: const EdgeInsets.only(top: 8, right: 10), 
                                    child: Icon(Icons.send_rounded, color: _inviaSdi ? const Color(0xFF2DD4BF) : Colors.white54, size: 18),
                                  ),
                                  if (!wallet.canSendSDI)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD946EF),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF18181B), width: 2),
                                        ),
                                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 12),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text('Invia allo SDI', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Switch(
                        value: _inviaSdi,
                        activeColor: const Color(0xFF2DD4BF),
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
                    const Divider(color: Colors.white12, height: 16),
                    TextField(controller: _pivaClienteController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _buildInputDecoration('P.IVA / Codice Fiscale Cliente', Icons.badge_outlined)),
                    const SizedBox(height: 8),
                    TextField(controller: _codiceSdiController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _buildInputDecoration('Codice SDI (7 cifre) o PEC', Icons.mark_email_read_outlined)),
                    const SizedBox(height: 8),
                    TextField(controller: _descrizioneController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _buildInputDecoration('Descrizione Prestazione', Icons.description_outlined)),
                  ],
                ],
              ),
            ),

            // 🧮 CARD RIPARTIZIONE CON DETTAGLIO SALDO + ACCONTO F24
            _buildRipartizionePreviewCard(context),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
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
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🇮🇹 HELPER VALUTA ITALIANA (1.000,00 €)
  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  // 📊 CALCOLO RIPARTIZIONE PRUDENZIALE (NETTO = LORDO - SALDO - ACCONTO - CUSCINETTO)
  Widget _buildRipartizionePreviewCard(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);
    final double importoLordo = double.tryParse(_importoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

    if (importoLordo <= 0) return const SizedBox.shrink();

    // 1. Calcolo Imponibile e Saldo Anno Corrente
    final double imponibile = importoLordo * _atecoCoef;
    final double aliquotaTasse = wallet.aliquotaImposta > 0 ? wallet.aliquotaImposta : 0.05;
    const double aliquotaInps = 0.2607; // Gestione Separata INPS
    
    final double saldoImposta = imponibile * aliquotaTasse;
    final double saldoInps = imponibile * aliquotaInps;
    final double totaleSaldo = saldoImposta + saldoInps;
    
    // 2. Calcolo Acconti Anno Successivo: (100% Imposta Sostitutiva / 80% INPS)
    final double accontoImposta = saldoImposta * 1.00;
    final double accontoInps = saldoInps * 0.80;
    final double totaleAcconto = accontoImposta + accontoInps;

    // Totale F24 da accantonare (Saldo + Acconti se abilitato in alto a destra)
    final double totaleF24 = _calcolaAncheAccontoF24 ? (totaleSaldo + totaleAcconto) : totaleSaldo;

    // 📌 NUOVO CALCOLO: Liquidità rimasta dopo aver sottratto TUTTO il F24
    final double nettoDopoTasse = importoLordo - totaleF24;

    // 3. Cuscinetto Mesi No-Lavoro - DINAMICO DAL PROVIDER (Onboarding)
    final int mesiLavorati = wallet.mesiAttivi > 0 ? wallet.mesiAttivi : 10;
    final double percentualeFondoFerie = (12 - mesiLavorati) / 12;
    
    // Il cuscinetto si calcola sulla liquidità al netto di tutto il F24
    final double quotaFondoFerie = nettoDopoTasse * percentualeFondoFerie;

    // 4. Netto Spendibile Reale (pronto per essere speso senza rischi)
    final double nettoSpendibileSubito = nettoDopoTasse - quotaFondoFerie;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
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
          
          // 1. INCASSO LORDO (#10B981)
          _buildSalvaDanaioRow(
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF10B981),
            title: 'Incasso Lordo:',
            value: '+${_formattaValuta(importoLordo)}',
            isBold: true,
          ),
          const SizedBox(height: 6),

          // 2. NETTO SPENDIBILE (#2DD4BF)
          _buildSalvaDanaioRow(
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF2DD4BF),
            title: 'Netto Spendibile:',
            value: '+${_formattaValuta(nettoSpendibileSubito)}',
            isBold: true,
          ),
          const SizedBox(height: 6),

          // 3. TASSE (SALDO + ACCONTO) (#3B82F6)
          _buildSalvaDanaioRow(
            icon: Icons.shield_rounded,
            color: const Color(0xFF3B82F6),
            title: _calcolaAncheAccontoF24 ? 'Tasse (Saldo + Acconto):' : 'Tasse (Solo Saldo):',
            value: '-${_formattaValuta(totaleF24)}',
            isBold: true,
          ),
          const SizedBox(height: 6),

          // 4. CUSCINETTO MESI NO-LAVORO (#8B5CF6)
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