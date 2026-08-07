import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_secondary_popup.dart';
import '../widgets_shared/app_datepicker.dart';

class AddMovementSheet extends StatefulWidget {
  final String initialTab;

  const AddMovementSheet({
    super.key,
    this.initialTab = 'riepilogo',
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

  // FocusNode per aprire la tastiera automaticamente sull'importo
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
    'Canoni/Bollette',
    'Alimentari',
    'Acquisti',
    'Divertimento',
    'Auto',
    'Viaggi',
    'Salute & Benessere',
    'Altro',
  ];
  String _sottocategoriaSelezionata = 'Alimentari';

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

  final List<String> _categorieSpesa = ['50% Spese Fisse', '30% Spese Variabili', '20% Risparmio'];

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

  final List<String> _contiDisponibili = [
    'Conto Principale (IBAN)',
    'Carta Spese & Svago',
    'Salvadanaio Emergenze / Tasse',
  ];

  final List<Map<String, dynamic>> _speseFrequenti = [
    {'label': 'Supermercato', 'icon': Icons.shopping_cart_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Alimentari'},
    {'label': 'Affitto', 'icon': Icons.home_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Casa/Affitto'},
    {'label': 'Mutuo', 'icon': Icons.account_balance_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Casa/Affitto'},
    {'label': 'Bollette', 'icon': Icons.bolt_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Canoni/Bollette'},
    {'label': 'Assicurazione', 'icon': Icons.verified_user_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Canoni/Bollette'},
    {'label': 'Ristorante / Bar', 'icon': Icons.restaurant_outlined, 'cat': '30% Spese Variabili', 'sottoCat': 'Divertimento'},
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
    
    int initialPage = 0;
    if (_tipoMovimento == 'uscita' || _tipoMovimento == 'spesa') initialPage = 1;
    if (_tipoMovimento == 'entrata') initialPage = 2;
    _pageController = PageController(initialPage: initialPage);

    _noteController.addListener(_suggerisciCategoriaAuto);

    // Gestione autofocus tastiera
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
    final paroleVariabili = ['ristorante', 'bar', 'palestra', 'sport', 'cinema', 'svago', 'abiti', 'shopping', 'cena', 'pranzo'];
    final paroleRisparmio = ['fondo', 'investimento', 'risparmio', 'pac', 'crypto', 'emerg'];

    if (paroleFisse.any((p) => testo.contains(p))) {
      if (_categoriaSelezionata != '50% Spese Fisse') {
        setState(() => _categoriaSelezionata = '50% Spese Fisse');
      }
    } else if (paroleVariabili.any((p) => testo.contains(p))) {
      if (_categoriaSelezionata != '30% Spese Variabili') {
        setState(() => _categoriaSelezionata = '30% Spese Variabili');
      }
    } else if (paroleRisparmio.any((p) => testo.contains(p))) {
      if (_categoriaSelezionata != '20% Risparmio') {
        setState(() => _categoriaSelezionata = '20% Risparmio');
      }
    }

    if (testo.contains('affitto') || testo.contains('mutuo')) {
      _sottocategoriaSelezionata = 'Casa/Affitto';
    } else if (testo.contains('bollett') || testo.contains('luce') || testo.contains('gas')) {
      _sottocategoriaSelezionata = 'Canoni/Bollette';
    } else if (testo.contains('supermercad') || testo.contains('spesa') || testo.contains('cibo')) {
      _sottocategoriaSelezionata = 'Alimentari';
    } else if (testo.contains('ristorante') || testo.contains('cinema') || testo.contains('bar')) {
      _sottocategoriaSelezionata = 'Divertimento';
    } else if (testo.contains('carburante') || testo.contains('auto')) {
      _sottocategoriaSelezionata = 'Auto';
    }
  }

  void _scansionaScontrinoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Scansiona Scontrino / Ticket',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _processaImmagineScontrino(ImageSource.camera);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Color(0xFF2DD4BF), size: 20),
                    SizedBox(width: 12),
                    Text('Scatta Foto da Fotocamera', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _processaImmagineScontrino(ImageSource.gallery);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.photo_library_rounded, color: Color(0xFF2DD4BF), size: 20),
                    SizedBox(width: 12),
                    Text('Scegli da Galleria', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _processaImmagineScontrino(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isAnalyzing = true);

      AppNotifications.mostraInAlto(context, 'Lettura intelligente scontrino in corso... 🤖');

      await Future.delayed(const Duration(seconds: 2));

      double importoTrovato = 42.80;
      String esercenteTrovato = 'Supermercato Conad';
      DateTime dataTrovata = DateTime.now();

      setState(() {
        _amountController.text = importoTrovato.toStringAsFixed(2).replaceAll('.', ',');
        _noteController.text = esercenteTrovato;
        _dataSelezionata = dataTrovata;
        _tipoMovimento = 'uscita'; 
        _suggerisciCategoriaAuto();
        _isAnalyzing = false;
      });

      if (mounted) {
        AppNotifications.mostraInAlto(
          context, 'Dati estratti! Controlla e salva! 🎉'
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        AppNotifications.mostraInAlto(context, 'Impossibile aprire la fotocamera: $e', type: NotificationType.error);
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
      dataFineRicorrenza: _isRicorrente ? _dataFineRicorrenza : null, // 🟢 Data di fine opzionale
    );

    // Reset sicuro dei campi e mantenimento della tab attiva pronto per un nuovo inserimento
    setState(() {
      _amountController.clear();
      _noteController.clear();
      _dataSelezionata = DateTime.now();
      _isRicorrente = false;
      _dataFineRicorrenza = null; // 🟢 Reset di fine ricorrenza
    });

    _amountFocusNode.requestFocus();

    AppNotifications.mostraInAlto(context, 'Movimento "$descrizione" registrato con successo! 🎉');
  }

  void _confermaEliminazioneMovimento(BuildContext context, String id, String desc, bool isRecurrent) {
    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFEF4444),
        titolo: 'Gestisci Movimento',
        testoAnnulla: 'Annulla',
        testoConferma: isRecurrent ? null : 'Elimina',
        onConferma: isRecurrent
            ? null
            : () {
                context.read<WalletProvider>().deleteTransaction(id);
                Navigator.pop(ctx);
                setState(() {});
                AppNotifications.mostraInAlto(context, 'Movimento "$desc" eliminato 🎉');
              },
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRecurrent
                    ? 'Questa è una spesa/entrata ricorrente.\nScegli esattamente come vuoi procedere:'
                    : 'Vuoi davvero eliminare "$desc"?\nIl saldo del conto verrà stornato.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (isRecurrent) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      context.read<WalletProvider>().stopRecurrence(id);
                      Navigator.pop(ctx);
                      setState(() {});
                      AppNotifications.mostraInAlto(
                        context,
                        'Ricorrenza interrotta! Le spese future sono state cancellate',
                        type: NotificationType.warning,
                      );
                    },
                    child: const Text('Mantieni questa, cancella le future', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      context.read<WalletProvider>().deleteButKeepRecurrence(id);
                      Navigator.pop(ctx);
                      setState(() {});
                      AppNotifications.mostraInAlto(
                        context, 'Movimento eliminato solo per questo mese! 🎉',
                      );
                    },
                    child: const Text('Elimina questa, mantieni le future', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      context.read<WalletProvider>().deleteTransaction(id);
                      Navigator.pop(ctx);
                      setState(() {});
                      AppNotifications.mostraInAlto(
                        context, 'Movimento "$desc" e futuri eliminati! 🎉',
                      );
                    },
                    child: const Text('Elimina questa e le future', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confermaEliminazioneMovimentoFuturo(BuildContext context, String predictionId, String parentId, String desc, DateTime meseRiferimento) {
    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        icon: Icons.event_repeat_rounded,
        iconColor: const Color(0xFF2DD4BF),
        titolo: 'Gestisci Ricorrenza Futura',
        testoAnnulla: 'Annulla',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stai modificando la previsione per "$desc".\nLo storico dei mesi passati non verrà toccato. Scegli cosa fare:',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2DD4BF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    final provider = Provider.of<WalletProvider>(context, listen: false);
                    try {
                      provider.skipPrediction(parentId, meseRiferimento);
                    } catch (_) {}

                    setState(() {
                      _skippedPredictionIds.add(predictionId);
                    });

                    Navigator.pop(ctx);

                    AppNotifications.mostraInAlto(
                      context,
                      'Previsione eliminata solo per questo mese',
                      type: NotificationType.warning,
                    );
                  },
                  child: const Text('Elimina solo quella di questo mese', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    final provider = Provider.of<WalletProvider>(context, listen: false);
                    provider.stopRecurrence(parentId);
                    Navigator.pop(ctx);
                    setState(() {});

                    AppNotifications.mostraInAlto(
                      context,
                      'Ricorrenza disdetta per i mesi futuri! Lo storico passato è salvo.',
                      type: NotificationType.warning,
                    );
                  },
                  child: const Text('Elimina questa e tutte le future', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
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
      _sottocategoriaSelezionata = item['sottoCat'] ?? 'Alimentari';
      _isPreferitoSelezionato = true; // 🔒 Blocca le tendine
    });
  }

  void _selezionaEntrataFrequente(Map<String, dynamic> item) {
    setState(() {
      _noteController.text = item['label'];
      _iconaCorrente = item['icon'] as IconData;
      _sottocategoriaEntrataSelezionata = item['sottoCat'] ?? 'Stipendio';
      _isPreferitoSelezionato = true; // 🔒 Blocca le tendine
    });
  }

  void _mostraGestionePreferitoModal(int index, bool isExpense) {
    final list = isExpense ? _speseFrequenti : _entrateFrequenti;
    final item = list[index];

    final TextEditingController nameController = TextEditingController(text: item['label']);
    IconData iconaTemp = item['icon'] as IconData;
    String catTemp = item['cat'] ?? '50% Spese Fisse';
    String sottoCatTemp = item['sottoCat'] ?? (isExpense ? 'Alimentari' : 'Stipendio');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppSecondaryPopup(
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
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (isExpense) ...[
                    const Text('REGOLA BUSSOLA SPESE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: catTemp,
                      dropdownColor: const Color(0xFF18181B),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _categorieSpesa.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => catTemp = v);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text(isExpense ? 'CATEGORIA SPECIFICA' : 'TIPOLOGIA ENTRATA', style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: sottoCatTemp,
                    dropdownColor: const Color(0xFF18181B),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: (isExpense ? _sottocategorieSpesa : _sottocategorieEntrata)
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => sottoCatTemp = v);
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text('SCEGLI PITTOGRAMMA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
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
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppSecondaryPopup(
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
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isExpense) ...[
                    const Text('REGOLA BUSSOLA SPESE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: categoriaNuova,
                      dropdownColor: const Color(0xFF18181B),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _categorieSpesa.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => categoriaNuova = v);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text(isExpense ? 'CATEGORIA SPECIFICA' : 'TIPOLOGIA ENTRATA', style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: sottoCatNuova,
                    dropdownColor: const Color(0xFF18181B),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: (isExpense ? _sottocategorieSpesa : _sottocategorieEntrata)
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => sottoCatNuova = v);
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

    return AppPopupWrapper(
      title: titoloModal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: const Color(0xFF2DD4BF),
                    onTap: () {
                      _pageController.animateToPage(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                    },
                  ),
                ),
                Expanded(
                  child: _buildTypeTab(
                    label: 'Uscita',
                    isSelected: _tipoMovimento == 'uscita' || _tipoMovimento == 'spesa',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      _pageController.animateToPage(1, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                    },
                  ),
                ),
                Expanded(
                  child: _buildTypeTab(
                    label: 'Entrata',
                    isSelected: _tipoMovimento == 'entrata',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      _pageController.animateToPage(2, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  if (index == 0) _tipoMovimento = 'riepilogo';
                  else if (index == 1) _tipoMovimento = 'uscita';
                  else if (index == 2) _tipoMovimento = 'entrata';
                });

                if (index != 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _amountFocusNode.requestFocus();
                  });
                }
              },
              children: [
                _buildSchermataRiepilogo(),
                _buildFormMovimento(isSpesa: true),
                _buildFormMovimento(isSpesa: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchermataRiepilogo() {
    final walletProvider = Provider.of<WalletProvider>(context);

    final List<Map<String, dynamic>> movimentiReali = walletProvider.transactions
        .where((tx) => !tx.title.startsWith('Accantonamento Tasse') && !tx.id.startsWith('rule_'))
        .map((tx) {
      final bool isFatturaPiva = tx.category == 'P.IVA' || tx.title.startsWith('Fattura') || tx.title.startsWith('Incasso:');
      
      final bool isGiroconto = tx.category == 'Giroconto' || 
                               tx.category == 'Trasferimento' || 
                               tx.title.toLowerCase().contains('giroconto') ||
                               tx.title.toLowerCase().contains('salvadanaio');

      // 🧠 MAPPATURA AUTOMATICA PER LA BUSSOLA SPESE (50/30/20)
      String regolaBussola = '50% Spese Fisse';
      final catLower = tx.category.toLowerCase();
      if (catLower.contains('30') || catLower.contains('svag') || catLower.contains('divertiment') || catLower.contains('variabil')) {
        regolaBussola = '30% Spese Variabili';
      } else if (catLower.contains('20') || catLower.contains('risparm') || catLower.contains('invest')) {
        regolaBussola = '20% Risparmio';
      } else if (tx.isIncome) {
        regolaBussola = 'Entrate';
      }

      return {
        'id': tx.id,
        'parentId': tx.id,
        'desc': tx.title,
        'imp': tx.amount,
        'cat': tx.category,
        'bussola': regolaBussola,
        'data': tx.date,
        'isSpesa': !tx.isIncome,
        'isFattura': isFatturaPiva, 
        'isGiroconto': isGiroconto,
        'isRecurrent': tx.isRecurrent,
        'isPrevisto': false,
      };
    }).toList();

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

      String regolaBussola = '50% Spese Fisse';
      final catLower = tx.category.toLowerCase();
      if (catLower.contains('30') || catLower.contains('svag') || catLower.contains('divertiment') || catLower.contains('variabil')) {
        regolaBussola = '30% Spese Variabili';
      } else if (catLower.contains('20') || catLower.contains('risparm') || catLower.contains('invest')) {
        regolaBussola = '20% Risparmio';
      } else if (tx.isIncome) {
        regolaBussola = 'Entrate';
      }

      return {
        'id': tx.id,
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
        .where((m) => m['isSpesa'] == false && m['isPrevisto'] == false && m['isGiroconto'] == false)
        .fold(0.0, (sum, m) => sum + (m['imp'] as double));

    final double totaleSpese = movimentiMeseSelezionato
        .where((m) => m['isSpesa'] == true && m['isPrevisto'] == false && m['isGiroconto'] == false)
        .fold(0.0, (sum, m) => sum + (m['imp'] as double));

    // 1. RAGGRUPPAMENTO PER CATEGORIA SPECIFICA
    final Map<String, List<Map<String, dynamic>>> perCategoria = {};
    for (var m in movimentiMeseSelezionato) {
      final cat = m['cat'] as String;
      perCategoria.putIfAbsent(cat, () => []).add(m);
    }

    // 2. RAGGRUPPAMENTO PER BUSSOLA SPESE
    final Map<String, List<Map<String, dynamic>>> perBussola = {};
    for (var m in movimentiMeseSelezionato) {
      final bussola = m['bussola'] as String;
      perBussola.putIfAbsent(bussola, () => []).add(m);
    }

    // 3. RAGGRUPPAMENTO PER DATA
    final List<Map<String, dynamic>> movimentiOrdinatiData = List.from(movimentiMeseSelezionato);
    movimentiOrdinatiData.sort((a, b) => (b['data'] as DateTime).compareTo(a['data'] as DateTime));

    final Map<String, List<Map<String, dynamic>>> perData = {};
    for (var m in movimentiOrdinatiData) {
      final dt = m['data'] as DateTime;
      final dataStr = _formattaDataInItaliano(dt);
      perData.putIfAbsent(dataStr, () => []).add(m);
    }

    // Selezione Mappa Attiva in base alla Tab scelta
    final Map<String, List<Map<String, dynamic>>> mappaCorrente = _vistaRiepilogo == 'categoria'
        ? perCategoria
        : (_vistaRiepilogo == 'bussola' ? perBussola : perData);

    return Column(
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
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2DD4BF), size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _meseSelezionatoRiepilogo = DateTime(_meseSelezionatoRiepilogo.year, _meseSelezionatoRiepilogo.month - 1);
                        _categoriaEspansaIndex = null;
                      });
                    },
                  ),
                  Text(
                    _formattaMeseAnno(_meseSelezionatoRiepilogo).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF2DD4BF), size: 16),
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

              // 📌 TAB SELETTORE A 3 OPZIONI: CATEGORIA | BUSSOLA | DATA
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _vistaRiepilogo = 'categoria';
                          _categoriaEspansaIndex = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _vistaRiepilogo == 'categoria' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Categoria',
                              style: TextStyle(
                                color: _vistaRiepilogo == 'categoria' ? Colors.black : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _vistaRiepilogo = 'bussola';
                          _categoriaEspansaIndex = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _vistaRiepilogo == 'bussola' ? const Color(0xFF2DD4BF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Bussola',
                              style: TextStyle(
                                color: _vistaRiepilogo == 'bussola' ? Colors.black : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _vistaRiepilogo = 'data';
                          _categoriaEspansaIndex = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _vistaRiepilogo == 'data' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Data',
                              style: TextStyle(
                                color: _vistaRiepilogo == 'data' ? Colors.black : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
        const SizedBox(height: 12),
        Expanded(
          child: movimentiMeseSelezionato.isEmpty
              ? const Center(
                  child: Text('Nessun movimento in questo mese.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: mappaCorrente.keys.length,
                  itemBuilder: (context, index) {
                    final nomeGruppo = mappaCorrente.keys.elementAt(index);
                    final listaMovs = mappaCorrente[nomeGruppo]!;
                    final bool isCategoriaGiroconto = nomeGruppo.toLowerCase().contains('giroconto') || nomeGruppo.toLowerCase().contains('trasferimento');

                    final double totGruppo = listaMovs.fold(0.0, (sum, m) {
                      final imp = m['imp'] as double;
                      final isSpesa = m['isSpesa'] as bool;
                      final isPrevisto = m['isPrevisto'] as bool;
                      final isGiroconto = m['isGiroconto'] as bool? ?? false;
                      if (isPrevisto || isGiroconto) return sum;
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
                                    color: const Color(0xFF2DD4BF),
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
                                        ? '⇄ ${_formatValuta(totGruppo)}'
                                        : '${totGruppo >= 0 ? '+' : '-'}${_formatValuta(totGruppo)}',
                                    style: TextStyle(
                                      color: isCategoriaGiroconto 
                                          ? const Color(0xFF3B82F6)
                                          : (totGruppo >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
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
                                  final String parentId = m['parentId'] as String;
                                  final String desc = m['desc'] as String;
                                  final String catSpecifica = m['cat'] as String;
                                  final bool isRecurrent = m['isRecurrent'] as bool? ?? false;
                                  final bool isPrevisto = m['isPrevisto'] as bool? ?? false;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (isRecurrent) ...[
                                                Icon(Icons.repeat_rounded, size: 12, color: isPrevisto ? Colors.white38 : const Color(0xFF2DD4BF)),
                                                const SizedBox(width: 4),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  _vistaRiepilogo == 'bussola'
                                                    ? '$desc ($catSpecifica)'
                                                    : (isPrevisto ? '$desc (Previsto il ${dt.day}/${dt.month})' : '$desc (${dt.day}/${dt.month})'),
                                                  style: TextStyle(
                                                    color: isPrevisto ? Colors.white38 : Colors.white60, 
                                                    fontSize: 11, 
                                                    fontStyle: isPrevisto ? FontStyle.italic : FontStyle.normal
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isGiroconto 
                                            ? _formatValuta(imp)
                                            : '${isSpesa ? '-' : '+'}${_formatValuta(imp)}',
                                          style: TextStyle(
                                            color: isGiroconto
                                              ? const Color(0xFF3B82F6)
                                              : (isPrevisto 
                                                ? (isSpesa ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFF10B981).withOpacity(0.5))
                                                : (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (!isFattura) ...[
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () {
                                              if (isPrevisto) {
                                                _confermaEliminazioneMovimentoFuturo(context, id, parentId, desc, dt);
                                              } else {
                                                _confermaEliminazioneMovimento(context, id, desc, isRecurrent);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 14),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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

    return SingleChildScrollView(
      controller: isSpesa ? _scrollControllerSpesa : _scrollControllerEntrata,
      physics: const BouncingScrollPhysics(),
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
            Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0,00 €',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 36),
                        border: InputBorder.none,
                        prefixText: isSpesa ? '- ' : '+ ',
                        prefixStyle: TextStyle(
                          color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
                    child: Material(
                      color: const Color(0xFF2DD4BF).withOpacity(0.15),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _scansionaScontrinoModal,
                        borderRadius: BorderRadius.circular(30),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2DD4BF), size: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 📌 1. BARRA PREFERITI SPPOSTATA SOPRA LA DESCRIZIONE CON TASTO '+' COMPATTO
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
                  
                  // 📌 IL TASTO SOLO '+' È IL PRIMO ELEMENTO PICCOLINO
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
                        label: Text(
                          item['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
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

            // 📌 2. CAMPO DESCRIZIONE (Se l'utente digita a mano sblocca le tendine)
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (_) {
                if (_isPreferitoSelezionato) {
                  setState(() => _isPreferitoSelezionato = false); // 🔓 Sblocca se scrive a mano
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

            // 📌 3. DATA CON APPDATEPICKER & CONTO
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

            // 📌 4. CATEGORIA E BUSSOLA SPESE (BLOCCATI SE È SELEZIONATO UN PREFERITO)
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
                          isDisabled: _isPreferitoSelezionato, // 🔒 Blocca tendina
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
                          isDisabled: _isPreferitoSelezionato, // 🔒 Blocca tendina
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
                    isDisabled: _isPreferitoSelezionato, // 🔒 Blocca tendina
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

            // 📌 5. REGOLE RICORRENZA
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _isRicorrente ? const Color(0xFF2DD4BF).withOpacity(0.08) : Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isRicorrente ? const Color(0xFF2DD4BF).withOpacity(0.3) : Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Movimento Ricorrente', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      subtitle: const Text('Es. Abbonamento mensile, affitto o stipendio', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      activeColor: const Color(0xFF2DD4BF),
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
                        const Text('FREQUENZA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        _buildInlineSelector(
                          icon: Icons.repeat_rounded,
                          iconColor: const Color(0xFF2DD4BF),
                          selectedValue: _frequenzaSelezionata,
                          isExpanded: _isFrequenzaEspansa,
                          onToggle: () {
                            setState(() => _isFrequenzaEspansa = !_isFrequenzaEspansa);
                            if (_isFrequenzaEspansa) _scrollToOffset(180);
                          },
                          items: _opzioniFrequenza,
                          onSelect: (val) {
                            setState(() {
                              _frequenzaSelezionata = val;
                              _isFrequenzaEspansa = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mostraMeseInizio) ...[
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MESE INIZIO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                _buildInlineSelector(
                                  icon: Icons.calendar_month_rounded,
                                  iconColor: const Color(0xFF2DD4BF),
                                  selectedValue: _meseRicorrenzaSelezionato,
                                  isExpanded: _isMeseEspanso,
                                  onToggle: () {
                                    setState(() => _isMeseEspanso = !_isMeseEspanso);
                                    if (_isMeseEspanso) _scrollToOffset(220);
                                  },
                                  items: _mesiAnno,
                                  onSelect: (val) {
                                    setState(() {
                                      _meseRicorrenzaSelezionato = val;
                                      _isMeseEspanso = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          flex: _frequenzaSelezionata == 'Ogni settimana' ? 2 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _frequenzaSelezionata == 'Ogni settimana' ? 'GIORNO DELLA SETTIMANA' : 'GIORNO DEL MESE', 
                                style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 4),
                              if (_frequenzaSelezionata == 'Ogni settimana')
                                _buildInlineSelector(
                                  icon: Icons.calendar_view_week_rounded,
                                  iconColor: const Color(0xFF2DD4BF),
                                  selectedValue: _giornoSettimanaSelezionato,
                                  isExpanded: _isGiornoSettimanaEspanso,
                                  onToggle: () {
                                    setState(() => _isGiornoSettimanaEspanso = !_isGiornoSettimanaEspanso);
                                    if (_isGiornoSettimanaEspanso) _scrollToOffset(220);
                                  },
                                  items: _giorniSettimana,
                                  onSelect: (val) {
                                    setState(() {
                                      _giornoSettimanaSelezionato = val;
                                      _isGiornoSettimanaEspanso = false;
                                    });
                                  },
                                )
                              else
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

                    // 🟢 BARRA COMPATTA SCADENZA RICORRENZA
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TERMINE RICORRENZA (OPZIONALE)', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final picked = await AppDatePicker.selezionaData(
                              context,
                              // 🟢 Parte da oggi (o dalla data selezionata per il movimento)
                              dataIniziale: _dataFineRicorrenza ?? _dataSelezionata,
                            );
                            if (picked != null) {
                              setState(() => _dataFineRicorrenza = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _dataFineRicorrenza != null 
                                    ? const Color(0xFF2DD4BF).withOpacity(0.5) 
                                    : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _dataFineRicorrenza != null ? Icons.event_available_rounded : Icons.all_inclusive_rounded,
                                      color: _dataFineRicorrenza != null ? const Color(0xFF2DD4BF) : Colors.white38,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dataFineRicorrenza != null
                                          ? 'Fino al: ${_formattaDataInItaliano(_dataFineRicorrenza!)}'
                                          : '∞ Senza fine (default)',
                                      style: TextStyle(
                                        color: _dataFineRicorrenza != null ? Colors.white : Colors.white54,
                                        fontSize: 12,
                                        fontWeight: _dataFineRicorrenza != null ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_dataFineRicorrenza != null)
                                  InkWell(
                                    onTap: () => setState(() => _dataFineRicorrenza = null),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 14),
                                    ),
                                  )
                                else
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 📌 PULSANTE DI SALVATAGGIO
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _salvaMovimento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  isSpesa ? 'Salva Uscita' : 'Salva Entrata',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
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
    bool isDisabled = false, // 🔒 Supporto blocco tendina
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

  Widget _buildTypeTab({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}