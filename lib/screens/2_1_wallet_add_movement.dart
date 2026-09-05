import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../data/wallet_provider.dart';
import '../data/recurrence_manager.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_secondary_popup.dart';
import '../widgets_shared/app_datepicker.dart';
import '../widgets_shared/app_image_picker.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '../screens/0_1_pro_upgrade.dart';
import '../services/document_scanner_service.dart';
import 'package:flutter/services.dart';
import '../widgets_shared/app_action_card.dart';
import '../widgets_shared/app_gestione_ricorrenza_popup.dart';

class AddMovementSheet extends StatefulWidget {
  final String initialTab;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategory;

  const AddMovementSheet({
    super.key,
    this.initialTab = 'riepilogo',
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
  });

  @override
  State<AddMovementSheet> createState() => _AddMovementSheetState();
}

class _AddMovementSheetState extends State<AddMovementSheet> {
  late String _tipoMovimento;
  late PageController _pageController;

  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  String _vistaRiepilogo = 'categoria'; 
  int? _categoriaEspansaIndex; 

  final Set<String> _skippedPredictionIds = {};

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _giornoRicorrenzaController = TextEditingController(text: '1');

  final FocusNode _amountFocusNode = FocusNode();
  
  final ScrollController _scrollControllerSpesa = ScrollController();
  final ScrollController _scrollControllerEntrata = ScrollController();

  String _categoriaSelezionata = '50% Spese Fisse';
  String _contoSelezionato = 'Conto Principale (IBAN)';
  DateTime _dataSelezionata = DateTime.now(); 
  DateTime _meseSelezionatoRiepilogo = DateTime.now();
  DateTime? _dataFineRicorrenza;

  final List<String> _sottocategorieSpesa = [
    'Casa/Affitto',
    'Mutuo',
    'Canoni/Bollette',
    'Supermercato',
    'Ristoranti & Bar',
    'Acquisti',
    'Divertimento',
    'Auto',
    'Viaggi',
    'Salute & Benessere',
    'Altro',
  ];

  final Map<String, String> _mappaSottocategoriaABussola = {
    'Casa/Affitto': '50% Spese Fisse',
    'Mutuo': '50% Spese Fisse',
    'Canoni/Bollette': '50% Spese Fisse',
    'Supermercato': '50% Spese Fisse',
    'Auto': '50% Spese Fisse',
    'Salute & Benessere': '50% Spese Fisse',
    'Ristoranti & Bar': '30% Spese Variabili',
    'Divertimento': '30% Spese Variabili',
    'Acquisti': '30% Spese Variabili',
    'Viaggi': '30% Spese Variabili',
    'Altro': '30% Spese Variabili',
  };

  String _sottocategoriaSelezionata = 'Supermercato';

  final List<String> _sottocategorieEntrata = [
    'Stipendio',
    'Entrate Extra / Freelance',
    'Regalo',
    'Rimborso',
    'Investimenti / Dividendi',
    'Altro',
  ];
  String _sottocategoriaEntrataSelezionata = 'Stipendio';

  bool _isCategoriaEspansa = false;
  bool _isSottocategoriaEspansa = false;
  bool _isContoEspanso = false;
  bool _isFrequenzaEspansa = false;
  bool _isMeseEspanso = false;

  bool _isRicorrente = false;
  String _frequenzaSelezionata = 'Ogni mese';
  String _meseRicorrenzaSelezionato = 'Gennaio';

  String _giornoSettimanaSelezionato = 'Lunedì';
  bool _isGiornoSettimanaEspanso = false;

  final List<String> _giorniSettimana = [
    'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'
  ];

  final List<String> _categorieSpesa = [
    '50% Spese Fisse', 
    '30% Spese Variabili', 
    '20% Risparmio'
  ];

  final List<String> _opzioniFrequenza = [
    'Ogni settimana',
    'Ogni mese',
    'Ogni 2 mesi',
    'Ogni 3 mesi (Trimestrale)',
    'Ogni 6 mesi (Semestrale)',
    'Ogni anno (Annuale)',
  ];

  final List<String> _mesiAnno = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  final List<Map<String, dynamic>> _speseFrequenti = [
    {'label': 'Supermercato', 'icon': Icons.shopping_cart_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Supermercato'},
    {'label': 'Affitto', 'icon': Icons.home_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Casa/Affitto'},
    {'label': 'Mutuo', 'icon': Icons.account_balance_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Mutuo'},
    {'label': 'Bollette', 'icon': Icons.bolt_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Canoni/Bollette'},
    {'label': 'Assicurazione', 'icon': Icons.verified_user_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Canoni/Bollette'},
    {'label': 'Ristorante / Bar', 'icon': Icons.restaurant_outlined, 'cat': '30% Spese Variabili', 'sottoCat': 'Ristoranti & Bar'},
    {'label': 'Carburante', 'icon': Icons.local_gas_station_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Auto'},
    {'label': 'Palestra / Sport', 'icon': Icons.fitness_center_outlined, 'cat': '30% Spese Variabili', 'sottoCat': 'Divertimento'},
  ];

  final List<Map<String, dynamic>> _entrateFrequenti = [
    {'label': 'Stipendio', 'icon': Icons.work_outline, 'sottoCat': 'Stipendio'},
    {'label': 'Regalo', 'icon': Icons.card_giftcard_outlined, 'sottoCat': 'Regalo'},
    {'label': 'Entrate Extra', 'icon': Icons.add_chart_outlined, 'sottoCat': 'Entrate Extra / Freelance'},
    {'label': 'Rimborso', 'icon': Icons.replay_outlined, 'sottoCat': 'Rimborso'},
  ];

  final List<IconData> _iconeDisponibili = [
    Icons.shopping_bag_outlined,
    Icons.shopping_cart_outlined,
    Icons.home_outlined,
    Icons.bolt_outlined,
    Icons.restaurant_outlined,
    Icons.local_gas_station_outlined,
    Icons.fitness_center_outlined,
    Icons.pets_outlined,
    Icons.directions_bus_outlined,
    Icons.medical_services_outlined,
    Icons.subscriptions_outlined,
    Icons.wifi_rounded,
    Icons.flight_takeoff_rounded,
    Icons.build_outlined,
    Icons.work_outline,
    Icons.card_giftcard_outlined,
    Icons.attach_money_outlined,
  ];

  IconData _iconaCorrente = Icons.shopping_cart_outlined;

  @override
  void initState() {
    super.initState();
    _tipoMovimento = widget.initialTab;
    
    if (widget.initialTitle != null) {
      _noteController.text = widget.initialTitle!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
    if (widget.initialCategory != null) {
      _sottocategoriaEntrataSelezionata = widget.initialCategory!;
      _sottocategoriaSelezionata = widget.initialCategory!;
    }

    int initialPage = 0;
    if (_tipoMovimento == 'uscita' || _tipoMovimento == 'spesa') initialPage = 1;
    if (_tipoMovimento == 'entrata') initialPage = 2;
    _pageController = PageController(initialPage: initialPage);

    _noteController.addListener(_suggerisciCategoriaAuto);

    if (initialPage != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _noteController.removeListener(_suggerisciCategoriaAuto);
    _amountController.dispose();
    _noteController.dispose();
    _giornoRicorrenzaController.dispose();
    _amountFocusNode.dispose();
    _scrollControllerSpesa.dispose();
    _scrollControllerEntrata.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _eliminaMovimentoSicuro(BuildContext context, String id, {String? gemelloId}) {
    final provider = context.read<WalletProvider>();
    provider.deleteTransaction(id);
  }

  String _formatValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  void _suggerisciCategoriaAuto() {
    final testo = _noteController.text.toLowerCase().trim();
    if (testo.isEmpty) return;

    final paroleFisse = ['affitto', 'mutuo', 'bolletta', 'luce', 'gas', 'internet', 'assicurazione', 'carburante', 'supermercato', 'spesa'];
    final paroleRistorazione = ['ristorante', 'trattoria', 'osteria', 'pizzeria', 'pub', 'bar', 'cena', 'pranzo', 'caffè'];
    final paroleVariabili = ['palestra', 'sport', 'cinema', 'svago', 'abiti', 'shopping'];
    final paroleRisparmio = ['fondo', 'investimento', 'risparmio', 'pac', 'crypto', 'emerg'];

    if (paroleRistorazione.any((p) => testo.contains(p))) {
      setState(() {
        _sottocategoriaSelezionata = 'Ristoranti & Bar';
        _categoriaSelezionata = _mappaSottocategoriaABussola[_sottocategoriaSelezionata]!;
      });
    } else if (paroleFisse.any((p) => testo.contains(p))) {
      if (testo.contains('affitto')) {
        _sottocategoriaSelezionata = 'Casa/Affitto';
      } else if (testo.contains('mutuo')) {
        _sottocategoriaSelezionata = 'Mutuo';
      } else if (testo.contains('bollett') || testo.contains('luce') || testo.contains('gas')) {
        _sottocategoriaSelezionata = 'Canoni/Bollette';
      } else if (testo.contains('supermercad') || testo.contains('spesa')) {
        _sottocategoriaSelezionata = 'Supermercato';
      } else if (testo.contains('carburante') || testo.contains('auto')) {
        _sottocategoriaSelezionata = 'Auto';
      }
      setState(() {
        _categoriaSelezionata = _mappaSottocategoriaABussola[_sottocategoriaSelezionata] ?? '50% Spese Fisse';
      });
    } else if (paroleVariabili.any((p) => testo.contains(p))) {
      setState(() {
        _sottocategoriaSelezionata = 'Divertimento';
        _categoriaSelezionata = _mappaSottocategoriaABussola[_sottocategoriaSelezionata]!;
      });
    } else if (paroleRisparmio.any((p) => testo.contains(p))) {
      setState(() => _categoriaSelezionata = '20% Risparmio');
    }
  }

  Future<void> _avviaScansioneIntelligente({TipoDocumentoScan tipo = TipoDocumentoScan.scontrino}) async {
    try {
      final XFile? image = await AppImagePickerSheet.mostra(
        context,
        titolo: tipo == TipoDocumentoScan.scontrino ? 'Scansiona Scontrino' : 'Scansiona Fattura',
      );

      if (image == null) return;

      setState(() => _isAnalyzing = true);

      final walletProvider = Provider.of<WalletProvider>(context, listen: false);

      final result = await DocumentScannerService.scanDocument(
        imagePath: image.path,
        wallet: walletProvider,
        tipo: tipo,
        onProgress: (statoText) {
          if (mounted) {
            AppNotifications.mostraInAlto(
              context,
              statoText,
              type: NotificationType.warning,
            );
          }
        },
      );

      setState(() {
        if (result.importo != null) {
          _amountController.text = result.importo!.toStringAsFixed(2).replaceAll('.', ',');
        }
        if (result.ragioneSociale != null && result.ragioneSociale!.isNotEmpty) {
          _noteController.text = result.ragioneSociale!;
        }
        if (result.data != null) {
          _dataSelezionata = result.data!;
        }

        if (result.categoriaSuggerita != null && result.categoriaSuggerita!.isNotEmpty) {
          if (_sottocategorieSpesa.contains(result.categoriaSuggerita)) {
            _sottocategoriaSelezionata = result.categoriaSuggerita!;
          }
        }

        if (_mappaSottocategoriaABussola.containsKey(_sottocategoriaSelezionata)) {
          _categoriaSelezionata = _mappaSottocategoriaABussola[_sottocategoriaSelezionata]!;
        }

        _tipoMovimento = 'uscita';
        _isAnalyzing = false;
      });

      if (mounted) {
        AppNotifications.mostraInAlto(
          context,
          '🤖 Documento analizzato con successo!',
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: const Text('Errore Scansione AI', style: TextStyle(color: Colors.white)),
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Color(0xFF2DD4BF))),
              ),
            ],
          ),
        );
      }
    }
  }

  void _salvaMovimento() {
    final importo = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    if (importo <= 0) {
      AppNotifications.mostraInAlto(
        context, 
        'Inserisci un importo valido!', 
        type: NotificationType.error
      );
      return;
    }

    final bool isSpesa = _tipoMovimento == 'uscita' || _tipoMovimento == 'spesa';
    final String descrizione = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : (isSpesa ? 'Nuova Uscita' : 'Nuova Entrata');

    final String categoriaFinale = isSpesa 
        ? _sottocategoriaSelezionata 
        : _sottocategoriaEntrataSelezionata;

    final accounts = context.read<WalletProvider>().accounts;
    final matchingAccount = accounts.firstWhere(
      (acc) => acc.title == _contoSelezionato,
      orElse: () => accounts.first,
    );

    final String accountId = matchingAccount.id;

    String? giornoRicorrenzaFinale;
    if (_isRicorrente) {
      giornoRicorrenzaFinale = _frequenzaSelezionata == 'Ogni settimana' 
          ? _giornoSettimanaSelezionato 
          : _giornoRicorrenzaController.text;
    }

    context.read<WalletProvider>().addTransaction(
      title: descrizione,
      amount: importo,
      isIncome: !isSpesa,
      category: categoriaFinale,
      accountId: accountId,
      date: _dataSelezionata,
      isRecurrent: _isRicorrente,
      frequenza: _isRicorrente ? _frequenzaSelezionata : null,
      giornoRicorrenza: giornoRicorrenzaFinale,
      dataInizio: _isRicorrente ? _dataSelezionata : null,
      dataFineRicorrenza: _isRicorrente ? _dataFineRicorrenza : null,
    );

    setState(() {
      _amountController.clear();
      _noteController.clear();
      _dataSelezionata = DateTime.now();
      _isRicorrente = false;
      _dataFineRicorrenza = null;
    });

    _amountFocusNode.requestFocus();

    AppNotifications.mostraInAlto(context, 'Movimento "$descrizione" registrato con successo! 🎉');
  }

  void _confermaEliminazioneMovimento(BuildContext context, String id, String desc, bool isRecurrent, {String? gemelloId, bool isFattura = false}) {
    final bool isFatturaPiva = isFattura || desc.toLowerCase().startsWith('incasso:') || desc.toLowerCase().startsWith('fattura');

    if (isFatturaPiva) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 22),
              SizedBox(width: 8),
              Text('Fattura P.IVA Protetta', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Gli incassi delle fatture P.IVA regolano l\'accantonamento delle tasse e non possono essere eliminati dai movimenti comuni.\n\nPer gestire questa fattura utilizza la sezione P.IVA.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Chiudi', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
      return;
    }

    if (!isRecurrent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Text('Elimina Movimento', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Vuoi davvero eliminare "$desc"?\nIl saldo del conto verrà aggiornato.',
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
                _eliminaMovimentoSicuro(context, id, gemelloId: gemelloId);
                Navigator.pop(ctx);
                setState(() {});
                AppNotifications.mostraInAlto(context, 'Movimento "$desc" eliminato 🎉');
              },
              child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    AppGestioneRicorrenzaPopup.mostra(
      context,
      id: id,
      titolo: desc,
      onConcluso: () => setState(() {}),
    );
  }

  void _confermaEliminazioneMovimentoFuturo(BuildContext context, String predictionId, String parentId, String desc, DateTime meseRiferimento) {
    AppGestioneRicorrenzaPopup.mostra(
      context,
      id: parentId,
      titolo: desc,
      meseRiferimento: meseRiferimento,
      onConcluso: () => setState(() {}),
    );
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

  String _formattaDataInItaliano(DateTime date) {
    final List<String> mesi = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${mesi[date.month - 1]} ${date.year}';
  }

  String _formattaMeseAnno(DateTime date) {
    final List<String> mesiBrevi = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic'
    ];
    return '${mesiBrevi[date.month - 1]} ${date.year}';
  }

  bool _isPreferitoSelezionato = false;

  void _selezionaSpesaFrequente(Map<String, dynamic> item) {
    setState(() {
      _noteController.text = item['label'];
      _iconaCorrente = item['icon'] as IconData;
      _categoriaSelezionata = item['cat'] ?? '50% Spese Fisse';
      _sottocategoriaSelezionata = item['sottoCat'] ?? 'Supermercato';
      _isPreferitoSelezionato = true;
    });
  }

  void _selezionaEntrataFrequente(Map<String, dynamic> item) {
    setState(() {
      _noteController.text = item['label'];
      _iconaCorrente = item['icon'] as IconData;
      _sottocategoriaEntrataSelezionata = item['sottoCat'] ?? 'Stipendio';
      _isPreferitoSelezionato = true;
    });
  }

  void _mostraGestionePreferitoModal(int index, bool isExpense) {
    final list = isExpense ? _speseFrequenti : _entrateFrequenti;
    final item = list[index];

    final TextEditingController nameController = TextEditingController(text: item['label']);
    IconData iconaTemp = item['icon'] as IconData;
    String catTemp = item['cat'] ?? '50% Spese Fisse';
    String sottoCatTemp = item['sottoCat'] ?? (isExpense ? 'Supermercato' : 'Stipendio');

    bool isCatEspansa = false;
    bool isSottoCatEspansa = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppSecondaryPopup(
            backgroundColor: const Color(0xFF18181B),
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF2DD4BF),
            titolo: 'Gestisci Preferito',
            testoAnnulla: 'Elimina',
            testoConferma: 'Salva Modifiche',
            onConferma: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  list[index] = {
                    'label': nameController.text.trim(),
                    'icon': iconaTemp,
                    'cat': catTemp,
                    'sottoCat': sottoCatTemp,
                  };
                  if (isExpense) {
                    _selezionaSpesaFrequente(list[index]);
                  } else {
                    _selezionaEntrataFrequente(list[index]);
                  }
                });
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(context, 'Preferito aggiornato! ✨');
              }
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome Preferito',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (isExpense) ...[
                    const Text('REGOLA BUSSOLA SPESE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _buildInlineSelector(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: const Color(0xFF2DD4BF),
                      selectedValue: catTemp,
                      isExpanded: isCatEspansa,
                      onToggle: () => setDialogState(() => isCatEspansa = !isCatEspansa),
                      items: _categorieSpesa,
                      onSelect: (val) {
                        setDialogState(() {
                          catTemp = val;
                          isCatEspansa = false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text(isExpense ? 'CATEGORIA SPECIFICA' : 'TIPOLOGIA ENTRATA', style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildInlineSelector(
                    icon: isExpense ? Icons.category_outlined : Icons.add_chart_outlined,
                    iconColor: const Color(0xFF2DD4BF),
                    selectedValue: sottoCatTemp,
                    isExpanded: isSottoCatEspansa,
                    onToggle: () => setDialogState(() => isSottoCatEspansa = !isSottoCatEspansa),
                    items: isExpense ? _sottocategorieSpesa : _sottocategorieEntrata,
                    onSelect: (val) {
                      setDialogState(() {
                        sottoCatTemp = val;
                        isSottoCatEspansa = false;
                      });
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text('SCEGLI PITTOGRAMMA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _iconeDisponibili.map((icon) {
                      final isSelected = iconaTemp == icon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => iconaTemp = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostraDialogNuovoConto() {
    final TextEditingController nomeContoController = TextEditingController();
    final TextEditingController saldoInizialeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF2DD4BF),
        titolo: 'Crea Nuovo Conto',
        testoConferma: 'Crea e Seleziona',
        onConferma: () {
          final nome = nomeContoController.text.trim();
          final saldo = double.tryParse(
                saldoInizialeController.text.replaceAll('.', '').replaceAll(',', '.'),
              ) ?? 0.0;

          if (nome.isNotEmpty) {
            final provider = context.read<WalletProvider>();
            provider.addAccount(
              title: nome,
              subtitle: 'Conto personalizzato',
              initialAmount: saldo,
              color: const Color(0xFF2DD4BF),
            );

            setState(() {
              _contoSelezionato = provider.accounts.last.title;
              _isContoEspanso = false;
            });

            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nomeContoController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nome Conto o Carta (es. Carta N26)',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                filled: true,
                fillColor: Colors.black.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: saldoInizialeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Saldo Iniziale (€)',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                filled: true,
                fillColor: Colors.black.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                prefixIcon: const Icon(
                  Icons.euro_symbol_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostraSelettoreIcone() {
    showDialog(
      context: context,
      builder: (context) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.grid_view_rounded,
        iconColor: const Color(0xFF2DD4BF),
        titolo: 'Scegli Pittogramma',
        testoAnnulla: 'Chiudi',
        child: SizedBox(
          width: 280,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _iconeDisponibili.length,
            itemBuilder: (context, index) {
              final icon = _iconeDisponibili[index];
              final isSelected = _iconaCorrente == icon;
              return GestureDetector(
                onTap: () {
                  setState(() => _iconaCorrente = icon);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 22),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostraDialogNuovoPreferito(bool isExpense) {
    final TextEditingController nameController = TextEditingController();
    IconData iconaNuova = _iconeDisponibili.first;
    String categoriaNuova = '50% Spese Fisse';
    String sottoCatNuova = isExpense ? 'Acquisti' : 'Stipendio';

    bool isCatEspansa = false;
    bool isSottoCatEspansa = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppSecondaryPopup(
            backgroundColor: const Color(0xFF18181B),
            icon: isExpense ? Icons.shopping_bag_outlined : Icons.add_chart_outlined,
            iconColor: const Color(0xFF2DD4BF),
            titolo: isExpense ? 'Crea Uscita Frequente' : 'Crea Entrata Frequente',
            testoConferma: 'Aggiungi',
            onConferma: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  if (isExpense) {
                    final itemNew = {
                      'label': nameController.text.trim(),
                      'icon': iconaNuova,
                      'cat': categoriaNuova,
                      'sottoCat': sottoCatNuova,
                    };
                    _speseFrequenti.add(itemNew);
                    _selezionaSpesaFrequente(itemNew);
                  } else {
                    final itemNew = {
                      'label': nameController.text.trim(),
                      'icon': iconaNuova,
                      'sottoCat': sottoCatNuova,
                    };
                    _entrateFrequenti.add(itemNew);
                    _selezionaEntrataFrequente(itemNew);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: isExpense ? 'Nome uscita (es. Idraulico)' : 'Nome entrata (es. Dividendi)',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isExpense) ...[
                    const Text('REGOLA BUSSOLA SPESE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _buildInlineSelector(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: const Color(0xFF2DD4BF),
                      selectedValue: categoriaNuova,
                      isExpanded: isCatEspansa,
                      onToggle: () => setDialogState(() => isCatEspansa = !isCatEspansa),
                      items: _categorieSpesa,
                      onSelect: (val) {
                        setDialogState(() {
                          categoriaNuova = val;
                          isCatEspansa = false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text(isExpense ? 'CATEGORIA SPECIFICA' : 'TIPOLOGIA ENTRATA', style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildInlineSelector(
                    icon: isExpense ? Icons.category_outlined : Icons.add_chart_outlined,
                    iconColor: const Color(0xFF2DD4BF),
                    selectedValue: sottoCatNuova,
                    isExpanded: isSottoCatEspansa,
                    onToggle: () => setDialogState(() => isSottoCatEspansa = !isSottoCatEspansa),
                    items: isExpense ? _sottocategorieSpesa : _sottocategorieEntrata,
                    onSelect: (val) {
                      setDialogState(() {
                        sottoCatNuova = val;
                        isSottoCatEspansa = false;
                      });
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text('SCEGLI PITTOGRAMMA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _iconeDisponibili.map((icon) {
                      final isSelected = iconaNuova == icon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => iconaNuova = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _scrollToOffset(double deltaPixels) {
    final activeController = (_tipoMovimento == 'uscita' || _tipoMovimento == 'spesa') 
        ? _scrollControllerSpesa 
        : _scrollControllerEntrata;

    Future.delayed(const Duration(milliseconds: 180), () {
      if (activeController.hasClients) {
        activeController.animateTo(
          (activeController.offset + deltaPixels).clamp(0.0, activeController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String titoloModal = _tipoMovimento == 'riepilogo'
        ? 'Riepilogo Movimenti'
        : (_tipoMovimento == 'uscita' || _tipoMovimento == 'spesa' ? 'Registra Uscita' : 'Registra Entrata');

    return AppBottomSheet(
      title: titoloModal,
      badgeText: 'Wallet',
      badgeColor: const Color(0xFF2DD4BF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔘 TAB SWITCHER PRINCIPALE (STILE PILLOLA MODERNO)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeTab(
                    label: 'Riepilogo',
                    isSelected: _tipoMovimento == 'riepilogo',
                    color: const Color(0xFF38BDF8), // 🎯 Azzurro Oceano
                    onTap: () {
                      FocusScope.of(context).unfocus(); // Chiude la tastiera
                      setState(() => _tipoMovimento = 'riepilogo');
                    },
                  ),
                ),
                Expanded(
  child: _buildTypeTab(
    label: 'Uscita',
    isSelected: _tipoMovimento == 'uscita' || _tipoMovimento == 'spesa',
    color: const Color(0xFFEF4444),
    onTap: () {
      setState(() => _tipoMovimento = 'uscita');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    },
  ),
),
Expanded(
  child: _buildTypeTab(
    label: 'Entrata',
    isSelected: _tipoMovimento == 'entrata',
    color: const Color(0xFF10B981),
    onTap: () {
      setState(() => _tipoMovimento = 'entrata');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    },
  ),
),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_tipoMovimento == 'riepilogo')
            Flexible(child: _buildSchermataRiepilogo())
          else if (_tipoMovimento == 'uscita' || _tipoMovimento == 'spesa')
            Flexible(child: _buildFormMovimento(isSpesa: true))
          else
            Flexible(child: _buildFormMovimento(isSpesa: false)),
        ],
      ),
    );
  }

  Widget _buildSchermataRiepilogo() {
    final walletProvider = Provider.of<WalletProvider>(context);

    String getAccountTitle(String? accountId) {
      if (accountId == null) return 'Conto';
      final matches = walletProvider.accounts.where((a) => a.id == accountId);
      return matches.isNotEmpty ? matches.first.title : 'Conto';
    }

    final allTxs = walletProvider.transactions
        .where((tx) => !tx.title.startsWith('Accantonamento Tasse') && !tx.id.startsWith('rule_'))
        .toList();

    final List<Map<String, dynamic>> movimentiReali = [];
    final Set<String> processedGirocontoIds = {};

    for (var tx in allTxs) {
      final bool isGiroconto = tx.category == 'Giroconto' || 
                               tx.category == 'Trasferimento' || 
                               tx.title.toLowerCase().contains('giroconto') ||
                               tx.title.toLowerCase().contains('salvadanaio');

      if (isGiroconto) {
        if (processedGirocontoIds.contains(tx.id)) continue;

        dynamic gemello;
        try {
          gemello = allTxs.firstWhere((other) =>
              other.id != tx.id &&
              !processedGirocontoIds.contains(other.id) &&
              other.isIncome != tx.isIncome &&
              (other.amount - tx.amount).abs() < 0.01 &&
              other.date.year == tx.date.year &&
              other.date.month == tx.date.month &&
              other.date.day == tx.date.day);
        } catch (_) {
          gemello = null;
        }

        processedGirocontoIds.add(tx.id);
        if (gemello != null) processedGirocontoIds.add(gemello.id);

        dynamic txDa = !tx.isIncome ? tx : gemello;
        dynamic txVerso = tx.isIncome ? tx : gemello;

        String nomeDa = txDa != null ? getAccountTitle(txDa.accountId as String?) : 'Conto';
        String nomeVerso = txVerso != null ? getAccountTitle(txVerso.accountId as String?) : 'Conto';

        movimentiReali.add({
          'id': tx.id,
          'gemelloId': gemello?.id,
          'parentId': tx.id,
          'desc': 'Da $nomeDa a $nomeVerso',
          'imp': tx.amount,
          'cat': 'Giroconto',
          'bussola': 'Giroconto',
          'data': tx.date,
          'isSpesa': false,
          'isFattura': false, 
          'isGiroconto': true,
          'isRecurrent': tx.isRecurrent,
          'isPrevisto': false,
        });
      } else {
        final bool isFatturaPiva = tx.category == 'P.IVA' || tx.title.startsWith('Fattura') || tx.title.startsWith('Incasso:');
        String regolaBussola = tx.isIncome 
            ? 'Entrate' 
            : (_mappaSottocategoriaABussola[tx.category] ?? '50% Spese Fisse');

        movimentiReali.add({
          'id': tx.id,
          'gemelloId': null,
          'parentId': tx.id,
          'desc': tx.title,
          'imp': tx.amount,
          'cat': tx.category,
          'bussola': regolaBussola,
          'data': tx.date,
          'isSpesa': !tx.isIncome,
          'isFattura': isFatturaPiva, 
          'isGiroconto': false,
          'isRecurrent': tx.isRecurrent,
          'isPrevisto': false,
        });
      }
    }

    final List<Map<String, dynamic>> previsti = walletProvider.getMovimentiPrevisti(_meseSelezionatoRiepilogo)
        .where((tx) => !_skippedPredictionIds.contains(tx.id))
        .map((tx) {
      String parentId = tx.id;
      if (parentId.startsWith('prev_')) {
        String cleanId = parentId.replaceFirst('prev_', '');
        List<String> parts = cleanId.split('_');
        if (parts.length >= 3) {
          parentId = parts.sublist(0, parts.length - 2).join('_');
        } else {
          parentId = parts.first;
        }
      }

      String regolaBussola = tx.isIncome 
          ? 'Entrate' 
          : (_mappaSottocategoriaABussola[tx.category] ?? '50% Spese Fisse');

      return {
        'id': tx.id,
        'gemelloId': null,
        'parentId': parentId,
        'desc': tx.title,
        'imp': tx.amount,
        'cat': tx.category,
        'bussola': regolaBussola,
        'data': tx.date,
        'isSpesa': !tx.isIncome,
        'isFattura': false,
        'isGiroconto': false,
        'isRecurrent': true,
        'isPrevisto': true,
      };
    }).toList();

    final List<Map<String, dynamic>> tuttiMovimenti = [...movimentiReali, ...previsti];

    final movimentiMeseSelezionato = tuttiMovimenti.where((m) {
      final dt = m['data'] as DateTime;
      return dt.year == _meseSelezionatoRiepilogo.year && dt.month == _meseSelezionatoRiepilogo.month;
    }).toList();

    final double totaleEntrate = movimentiMeseSelezionato
        .where((m) => m['isSpesa'] == false && m['isGiroconto'] == false) 
        .fold(0.0, (sum, m) => sum + (m['imp'] as double));

    final double totaleSpese = movimentiMeseSelezionato
        .where((m) => m['isSpesa'] == true && m['isGiroconto'] == false) 
        .fold(0.0, (sum, m) => sum + (m['imp'] as double));

    final Map<String, List<Map<String, dynamic>>> perCategoria = {};
    for (var m in movimentiMeseSelezionato) {
      final cat = m['cat'] as String;
      perCategoria.putIfAbsent(cat, () => []).add(m);
    }

    final Map<String, List<Map<String, dynamic>>> perBussola = {};
    for (var m in movimentiMeseSelezionato) {
      final bussola = m['bussola'] as String;
      perBussola.putIfAbsent(bussola, () => []).add(m);
    }

    final List<Map<String, dynamic>> movimentiOrdinatiData = List.from(movimentiMeseSelezionato);
    movimentiOrdinatiData.sort((a, b) => (b['data'] as DateTime).compareTo(a['data'] as DateTime));

    final Map<String, List<Map<String, dynamic>>> perData = {};
    for (var m in movimentiOrdinatiData) {
      final dt = m['data'] as DateTime;
      final dataStr = _formattaDataInItaliano(dt);
      perData.putIfAbsent(dataStr, () => []).add(m);
    }

    final Map<String, List<Map<String, dynamic>>> mappaCorrente = _vistaRiepilogo == 'categoria'
        ? perCategoria
        : (_vistaRiepilogo == 'bussola' ? perBussola : perData);

    const tealAccent = Color(0xFF2DD4BF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: tealAccent, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _meseSelezionatoRiepilogo = DateTime(_meseSelezionatoRiepilogo.year, _meseSelezionatoRiepilogo.month - 1);
                        _categoriaEspansaIndex = null;
                      });
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await AppDatePicker.selezionaData(
                            context,
                            dataIniziale: _meseSelezionatoRiepilogo,
                          );
                          if (picked != null) {
                            setState(() {
                              _meseSelezionatoRiepilogo = picked;
                              _categoriaEspansaIndex = null;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formattaMeseAnno(_meseSelezionatoRiepilogo).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, color: tealAccent, size: 20),
                            ],
                          ),
                        ),
                      ),
                      if (_meseSelezionatoRiepilogo.year != DateTime.now().year || _meseSelezionatoRiepilogo.month != DateTime.now().month) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _meseSelezionatoRiepilogo = DateTime.now();
                              _categoriaEspansaIndex = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tealAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tealAccent.withOpacity(0.5)),
                            ),
                            child: const Text(
                              'Oggi',
                              style: TextStyle(
                                color: tealAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: tealAccent, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _meseSelezionatoRiepilogo = DateTime(_meseSelezionatoRiepilogo.year, _meseSelezionatoRiepilogo.month + 1);
                        _categoriaEspansaIndex = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${_formatValuta(totaleEntrate)}',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('|', style: TextStyle(color: Colors.white24, fontSize: 16)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '-${_formatValuta(totaleSpese)}',
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 🎨 SELETTORE VISTA RIEPILOGO STILE PILLOLA MODERNO
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSubTabPill(
                        label: 'Categoria',
                        icon: Icons.grid_view_rounded,
                        isSelected: _vistaRiepilogo == 'categoria',
                        onTap: () => setState(() {
                          _vistaRiepilogo = 'categoria';
                          _categoriaEspansaIndex = null;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _buildSubTabPill(
                        label: 'Bussola',
                        icon: Icons.explore_outlined,
                        isSelected: _vistaRiepilogo == 'bussola',
                        onTap: () => setState(() {
                          _vistaRiepilogo = 'bussola';
                          _categoriaEspansaIndex = null;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _buildSubTabPill(
                        label: 'Data',
                        icon: Icons.calendar_today_rounded,
                        isSelected: _vistaRiepilogo == 'data',
                        onTap: () => setState(() {
                          _vistaRiepilogo = 'data';
                          _categoriaEspansaIndex = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        movimentiMeseSelezionato.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined, 
                      color: Colors.white.withOpacity(0.2), 
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nessun movimento in questo mese.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4), 
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _tipoMovimento = 'uscita');
                        _amountFocusNode.requestFocus();
                      },
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                      label: const Text(
                        'Registra primo movimento',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              )
            : Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: mappaCorrente.keys.length,
                  itemBuilder: (context, index) {
                    final nomeGruppo = mappaCorrente.keys.elementAt(index);
                    final listaMovs = mappaCorrente[nomeGruppo]!;
                    final bool isCategoriaGiroconto = nomeGruppo.toLowerCase().contains('giroconto') || nomeGruppo.toLowerCase().contains('trasferimento');

                    double totGruppo = listaMovs.fold(0.0, (sum, m) {
                      final imp = m['imp'] as double;
                      final isSpesa = m['isSpesa'] as bool;
                      final isGiroconto = m['isGiroconto'] as bool? ?? false;
                      if (isGiroconto) return sum + imp;
                      return sum + (isSpesa ? -imp : imp);
                    });

                    final bool isEspansa = _categoriaEspansaIndex == index;

                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _categoriaEspansaIndex = isEspansa ? null : index;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    isEspansa ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                                    color: tealAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      nomeGruppo,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    isCategoriaGiroconto
                                        ? _formatValuta(totGruppo)
                                        : '${totGruppo > 0 ? '+' : (totGruppo < 0 ? '-' : '')}${_formatValuta(totGruppo)}',
                                    style: TextStyle(
                                      color: isCategoriaGiroconto 
                                          ? const Color(0xFF3B82F6)
                                          : (totGruppo > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isEspansa)
                            Container(
                              color: Colors.black.withOpacity(0.2),
                              padding: const EdgeInsets.only(left: 36, right: 10, bottom: 8, top: 4),
                              child: Column(
                                children: listaMovs.map((m) {
                                  final dt = m['data'] as DateTime;
                                  final isSpesa = m['isSpesa'] as bool;
                                  final imp = m['imp'] as double;
                                  final bool isFattura = m['isFattura'] as bool;
                                  final bool isGiroconto = m['isGiroconto'] as bool? ?? false;
                                  final String id = m['id'] as String;
                                  final String? gemelloId = m['gemelloId'] as String?;
                                  final String parentId = m['parentId'] as String;
                                  final String desc = m['desc'] as String;
                                  final String catSpecifica = m['cat'] as String;
                                  final bool isRecurrent = m['isRecurrent'] as bool? ?? false;
                                  final bool isPrevisto = m['isPrevisto'] as bool? ?? false;

                                  final bool isFuturo = dt.isAfter(DateTime.now());

                                  Color colorValore = isGiroconto
                                      ? const Color(0xFF3B82F6)
                                      : (isFuturo 
                                          ? (isSpesa ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFF10B981).withOpacity(0.4))
                                          : (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981)));

                                  String testoValore = isGiroconto
                                      ? _formatValuta(imp)
                                      : '${isSpesa ? '-' : '+'}${_formatValuta(imp)}';

                                  final rowContent = Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (isRecurrent) ...[
                                                Icon(
                                                  Icons.sync_rounded, 
                                                  size: 13, 
                                                  color: isFuturo ? Colors.white38 : tealAccent,
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  _vistaRiepilogo == 'bussola'
                                                      ? '$desc ($catSpecifica)'
                                                      : (isPrevisto ? '$desc (Previsto il ${dt.day}/${dt.month})' : '$desc (${dt.day}/${dt.month})'),
                                                  style: TextStyle(
                                                    color: isGiroconto
                                                        ? const Color(0xFF3B82F6)
                                                        : (isFuturo 
                                                            ? Colors.white38 
                                                            : (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                                                    fontSize: 11, 
                                                    fontStyle: isFuturo ? FontStyle.italic : FontStyle.normal,
                                                    fontWeight: isFuturo ? FontWeight.normal : FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          testoValore,
                                          style: TextStyle(
                                            color: colorValore,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  return Dismissible(
                                    key: UniqueKey(),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (isPrevisto) {
                                        _confermaEliminazioneMovimentoFuturo(context, id, parentId, desc, dt);
                                      } else {
                                        _confermaEliminazioneMovimento(context, id, desc, isRecurrent, gemelloId: gemelloId, isFattura: isFattura);
                                      }
                                      return false;
                                    },
                                    child: rowContent,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildFormMovimento({required bool isSpesa}) {
    final bool mostraMeseInizio = [
      'Ogni 2 mesi',
      'Ogni 3 mesi (Trimestrale)',
      'Ogni 6 mesi (Semestrale)',
      'Ogni anno (Annuale)',
    ].contains(_frequenzaSelezionata);

    final Color themeAccent = isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    String termineValoreCorrente = 'Senza fine (default)';
    if (_dataFineRicorrenza != null) {
      termineValoreCorrente = 'Fino al ${_formattaDataInItaliano(_dataFineRicorrenza!)}';
    }

    final List<AppDropdownItem<String>> opzioniTermineDropdown = [
      const AppDropdownItem(
        value: 'Senza fine (default)',
        label: 'Senza fine (default)',
        icon: Icons.all_inclusive_rounded,
      ),
      const AppDropdownItem(
        value: '1 anno',
        label: '1 Anno (12 rate)',
        icon: Icons.event_repeat_rounded,
      ),
      const AppDropdownItem(
        value: '2 anni',
        label: '2 Anni (24 rate)',
        icon: Icons.event_repeat_rounded,
      ),
      if (_dataFineRicorrenza != null)
        AppDropdownItem(
          value: termineValoreCorrente,
          label: termineValoreCorrente,
          icon: Icons.calendar_today_rounded,
        ),
      const AppDropdownItem(
        value: 'data_custom',
        label: '📅 Data specifica...',
        icon: Icons.edit_calendar_rounded,
      ),
    ];

    return SingleChildScrollView(
      controller: isSpesa ? _scrollControllerSpesa : _scrollControllerEntrata,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 220.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSpesa) const SizedBox(height: 10),
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _amountFocusNode.hasFocus && _amountController.text.isNotEmpty
                      ? [
                          BoxShadow(
                            color: themeAccent.withOpacity(0.18),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: IntrinsicWidth(
                        child: TextField(
                          key: ValueKey(isSpesa ? 'amount_spesa' : 'amount_entrata'),
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            ThousandsSeparatorInputFormatter(),
                          ],
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeAccent,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0,00 €',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 36),
                            border: InputBorder.none,
                            prefixText: isSpesa ? '- ' : '+ ',
                            prefixStyle: TextStyle(
                              color: themeAccent,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isSpesa)
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            final wallet = Provider.of<WalletProvider>(context, listen: false);
                            if (!wallet.canUseOCR) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProUpgradeSheet(funzionalita: 'Scansione Scontrini (OCR)')));
                            } else {
                              _avviaScansioneIntelligente();
                            }
                          },
                          child: Consumer<WalletProvider>(
                            builder: (context, wallet, child) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 8, right: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.document_scanner_rounded, color: Colors.white70, size: 20),
                                  ),
                                  if (!wallet.canUseOCR)
                                    Positioned(
                                      top: 0,
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
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PREFERITI RAPIDI', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const Text('Tieni premuto per gestire/modificare', style: TextStyle(color: Colors.white38, fontSize: 8, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: (isSpesa ? _speseFrequenti.length : _entrateFrequenti.length) + 1,
                  itemBuilder: (context, index) {
                    final list = isSpesa ? _speseFrequenti : _entrateFrequenti;
                    
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: InkWell(
                          onTap: () => _mostraDialogNuovoPreferito(isSpesa),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2DD4BF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                            ),
                            child: const Icon(Icons.add, size: 16, color: Color(0xFF2DD4BF)),
                          ),
                        ),
                      );
                    }

                    final item = list[index - 1];
                    final isSelected = _noteController.text == item['label'];

                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onLongPress: () => _mostraGestionePreferitoModal(index - 1, isSpesa),
                        child: FilterChip(
                          showCheckmark: false,
                          selected: isSelected,
                          avatar: Icon(item['icon'], size: 14, color: isSelected ? Colors.white : const Color(0xFF2DD4BF)),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined, size: 10, color: isSelected ? Colors.white60 : Colors.white24),
                            ],
                          ),
                          backgroundColor: Colors.black.withOpacity(0.35),
                          selectedColor: const Color(0xFF2DD4BF).withOpacity(0.4),
                          side: BorderSide(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (_) {
                            if (isSpesa) {
                              _selezionaSpesaFrequente(item);
                            } else {
                              _selezionaEntrataFrequente(item);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (_) {
                  if (_isPreferitoSelezionato) {
                    setState(() => _isPreferitoSelezionato = false);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Descrizione',
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.35),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  prefixIcon: IconButton(
                    icon: Icon(_iconaCorrente, color: const Color(0xFF2DD4BF), size: 20),
                    onPressed: _mostraSelettoreIcone,
                    tooltip: 'Cambia pittogramma',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DATA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selezionaData(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DD4BF), size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formattaDataInItaliano(_dataSelezionata),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CONTO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final contiProvider = context.watch<WalletProvider>().accounts;
                            final List<String> nomiContiReali = contiProvider.map((c) => c.title).toList();

                            if (!nomiContiReali.contains(_contoSelezionato) && nomiContiReali.isNotEmpty) {
                              _contoSelezionato = nomiContiReali.first;
                            }

                            return _buildInlineSelector(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: Colors.white54,
                              selectedValue: _contoSelezionato,
                              isExpanded: _isContoEspanso,
                              onToggle: () {
                                setState(() => _isContoEspanso = !_isContoEspanso);
                                if (_isContoEspanso) _scrollToOffset(100);
                              },
                              items: [...nomiContiReali, '+ Aggiungi conto...'],
                              onSelect: (val) {
                                if (val == '+ Aggiungi conto...') {
                                  _mostraDialogNuovoConto();
                                } else {
                                  setState(() {
                                    _contoSelezionato = val;
                                    _isContoEspanso = false;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (isSpesa) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('CATEGORIA SPECIFICA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              if (_isPreferitoSelezionato) const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 10),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildInlineSelector(
                            icon: Icons.category_outlined,
                            iconColor: _isPreferitoSelezionato ? Colors.white38 : const Color(0xFF2DD4BF),
                            selectedValue: _sottocategoriaSelezionata,
                            isExpanded: _isSottocategoriaEspansa,
                            isDisabled: _isPreferitoSelezionato,
                            onToggle: () {
                              if (_isPreferitoSelezionato) return;
                              setState(() {
                                _isSottocategoriaEspansa = !_isSottocategoriaEspansa;
                                if (_isSottocategoriaEspansa) _scrollToOffset(120);
                              });
                            },
                            items: _sottocategorieSpesa,
                            onSelect: (val) {
                              setState(() {
                                _sottocategoriaSelezionata = val;
                                if (_mappaSottocategoriaABussola.containsKey(val)) {
                                  _categoriaSelezionata = _mappaSottocategoriaABussola[val]!;
                                }
                                _isSottocategoriaEspansa = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('BUSSOLA SPESE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              if (_isPreferitoSelezionato) const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 10),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildInlineSelector(
                            icon: Icons.pie_chart_outline_rounded,
                            iconColor: _isPreferitoSelezionato ? Colors.white38 : const Color(0xFF2DD4BF),
                            selectedValue: _categoriaSelezionata,
                            isExpanded: _isCategoriaEspansa,
                            isDisabled: _isPreferitoSelezionato,
                            onToggle: () {
                              if (_isPreferitoSelezionato) return;
                              setState(() {
                                _isCategoriaEspansa = !_isCategoriaEspansa;
                                if (_isCategoriaEspansa) _scrollToOffset(120);
                              });
                            },
                            items: _categorieSpesa,
                            onSelect: (val) {
                              setState(() {
                                _categoriaSelezionata = val;
                                _isCategoriaEspansa = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('TIPOLOGIA ENTRATA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        if (_isPreferitoSelezionato) const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 10),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildInlineSelector(
                      icon: Icons.add_chart_outlined,
                      iconColor: _isPreferitoSelezionato ? Colors.white38 : const Color(0xFF10B981),
                      selectedValue: _sottocategoriaEntrataSelezionata,
                      isExpanded: _isSottocategoriaEspansa,
                      isDisabled: _isPreferitoSelezionato,
                      onToggle: () {
                        if (_isPreferitoSelezionato) return;
                        setState(() {
                          _isSottocategoriaEspansa = !_isSottocategoriaEspansa;
                          if (_isSottocategoriaEspansa) _scrollToOffset(120);
                        });
                      },
                      items: _sottocategorieEntrata,
                      onSelect: (val) {
                        setState(() {
                          _sottocategoriaEntrataSelezionata = val;
                          _isSottocategoriaEspansa = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: _isRicorrente ? themeAccent.withOpacity(0.08) : Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isRicorrente ? themeAccent.withOpacity(0.3) : Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Movimento Ricorrente', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Es. Abbonamento mensile, affitto o stipendio', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        activeColor: themeAccent,
                        value: _isRicorrente,
                        onChanged: (val) {
                          setState(() => _isRicorrente = val);
                          if (val) _scrollToOffset(200);
                        },
                      ),
                    ),
                    if (_isRicorrente) ...[
                      const Divider(color: Colors.white12, height: 12),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSecondaryDropdown<String>(
                            label: 'Frequenza',
                            accentColor: themeAccent,
                            selectedValue: _opzioniFrequenza.contains(_frequenzaSelezionata) ? _frequenzaSelezionata : 'Ogni mese',
                            items: _opzioniFrequenza.map((f) => AppDropdownItem(value: f, label: f, icon: Icons.repeat_rounded)).toList(),
                            onSelect: (val) => setState(() => _frequenzaSelezionata = val),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (mostraMeseInizio) ...[
                                Expanded(
                                  flex: 2,
                                  child: AppSecondaryDropdown<String>(
                                    label: 'Mese Inizio',
                                    accentColor: themeAccent,
                                    selectedValue: _meseRicorrenzaSelezionato,
                                    items: _mesiAnno.map((m) => AppDropdownItem(value: m, label: m, icon: Icons.calendar_month_rounded)).toList(),
                                    onSelect: (val) => setState(() => _meseRicorrenzaSelezionato = val),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                flex: _frequenzaSelezionata == 'Ogni settimana' ? 2 : 1,
                                child: _frequenzaSelezionata == 'Ogni settimana'
                                    ? AppSecondaryDropdown<String>(
                                        label: 'Giorno Settimana',
                                        accentColor: themeAccent,
                                        selectedValue: _giornoSettimanaSelezionato,
                                        items: _giorniSettimana.map((g) => AppDropdownItem(value: g, label: g, icon: Icons.calendar_view_week_rounded)).toList(),
                                        onSelect: (val) => setState(() => _giornoSettimanaSelezionato = val),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('GIORNO DEL MESE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.35),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                                            ),
                                            child: TextField(
                                              controller: _giornoRicorrenzaController,
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                                                hintText: '1',
                                                hintStyle: TextStyle(color: Colors.white24),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          AppSecondaryDropdown<String>(
                            label: 'Termine Ricorrenza (Opzionale)',
                            accentColor: themeAccent,
                            selectedValue: opzioniTermineDropdown.any((item) => item.value == termineValoreCorrente)
                                ? termineValoreCorrente
                                : 'Senza fine (default)',
                            items: opzioniTermineDropdown,
                            onSelect: (val) async {
                              if (val == 'data_custom') {
                                final picked = await AppDatePicker.selezionaData(
                                  context,
                                  dataIniziale: _dataFineRicorrenza ?? DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dataFineRicorrenza = picked;
                                  });
                                }
                              } else if (val == '1 anno') {
                                setState(() {
                                  _dataFineRicorrenza = DateTime.now().add(const Duration(days: 365));
                                });
                              } else if (val == '2 anni') {
                                setState(() {
                                  _dataFineRicorrenza = DateTime.now().add(const Duration(days: 730));
                                });
                              } else if (val == 'Senza fine (default)') {
                                setState(() {
                                  _dataFineRicorrenza = null;
                                });
                              } else {
                                setState(() {
                                  _dataFineRicorrenza = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🔘 PULSANTE SALVA RIMODERNATO CON STILE PILL
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _salvaMovimento,
                  icon: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    isSpesa ? 'Salva Uscita' : 'Salva Entrata',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineSelector({
    required IconData icon,
    required Color iconColor,
    required String selectedValue,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<String> items,
    required Function(String) onSelect,
    bool isDisabled = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? const Color(0xFF2DD4BF).withOpacity(0.4) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isDisabled ? null : onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedValue,
                      style: TextStyle(
                        color: isDisabled ? Colors.white54 : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isDisabled ? Icons.lock_outline_rounded : (isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                    color: Colors.white38,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && !isDisabled) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: items.map((item) {
                  final bool isSelected = item == selectedValue;
                  final bool isNewOption = item.startsWith('+');

                  return InkWell(
                    onTap: () => onSelect(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.12) : Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: isSelected ? const Color(0xFF2DD4BF) : (isNewOption ? const Color(0xFF2DD4BF) : Colors.white24),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                color: isNewOption ? const Color(0xFF2DD4BF) : (isSelected ? Colors.white : Colors.white70),
                                fontSize: 11,
                                fontWeight: isSelected || isNewOption ? FontWeight.bold : FontWeight.normal,
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
            ),
          ],
        ],
      ),
    );
  }

  // 🎨 TAB SWITCHER PRINCIPALE (STILE PILLOLA MODERNO)
  Widget _buildTypeTab({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 SUB-TAB VISTA RIEPILOGO (CATEGORIA / BUSSOLA / DATA)
  Widget _buildSubTabPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const tealColor = Color(0xFF2DD4BF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? tealColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? tealColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? tealColor : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String cleanText = newValue.text.replaceAll('.', '');
    List<String> parts = cleanText.split(',');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts.sublist(1).join('') : null;

    if (integerPart.isNotEmpty) {
      final doubleNumber = double.tryParse(integerPart);
      if (doubleNumber != null) {
        final formattedInteger = integerPart.replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

        String resultText = formattedInteger;
        if (decimalPart != null) {
          resultText += ',${decimalPart.length > 2 ? decimalPart.substring(0, 2) : decimalPart}';
        }

        return TextEditingValue(
          text: resultText,
          selection: TextSelection.collapsed(offset: resultText.length),
        );
      }
    }
    return newValue;
  }
}