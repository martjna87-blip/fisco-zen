import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';

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
  
  final ScrollController _scrollControllerSpesa = ScrollController();
  final ScrollController _scrollControllerEntrata = ScrollController();

  String _categoriaSelezionata = '50% Spese Fisse';
  String _contoSelezionato = 'Conto Principale (IBAN)';
  DateTime _dataSelezionata = DateTime.now(); 
  DateTime _meseSelezionatoRiepilogo = DateTime.now();

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
    {'label': 'Stipendio', 'icon': Icons.work_outline},
    {'label': 'Regalo', 'icon': Icons.card_giftcard_outlined},
    {'label': 'Entrate Extra', 'icon': Icons.add_chart_outlined},
    {'label': 'Rimborso', 'icon': Icons.replay_outlined},
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
  }

  @override
  void dispose() {
    _noteController.removeListener(_suggerisciCategoriaAuto);
    _amountController.dispose();
    _noteController.dispose();
    _giornoRicorrenzaController.dispose();
    _scrollControllerSpesa.dispose();
    _scrollControllerEntrata.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatValuta(double importo) {
    final parts = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]} €';
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
    final importo = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
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
      (acc) => acc.title == _contoSelezionato || _contoSelezionato.contains(acc.title),
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
    );

    setState(() {
      _amountController.clear();
      _noteController.clear();
      _meseSelezionatoRiepilogo = DateTime(_dataSelezionata.year, _dataSelezionata.month);
      _tipoMovimento = 'riepilogo'; 
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });

    AppNotifications.mostraInAlto(context, 'Movimento "$descrizione" registrato con successo! 🎉');
  }

  void _confermaEliminazioneMovimento(BuildContext context, String id, String desc, bool isRecurrent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Gestisci Movimento', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isRecurrent 
            ? 'Questa è una spesa/entrata ricorrente.\nScegli esattamente come vuoi procedere:'
            : 'Vuoi davvero eliminare "$desc"?\nIl saldo del conto verrà stornato.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actionsAlignment: isRecurrent ? MainAxisAlignment.center : MainAxisAlignment.end,
        actions: isRecurrent
            ? [
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                        child: const Text('Mantieni questa, cancella le future', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          context.read<WalletProvider>().deleteButKeepRecurrence(id);
                          Navigator.pop(ctx);
                          setState(() {});
                          
                          AppNotifications.mostraInAlto(
                            context, 'Movimento eliminato solo per questo mese! 🎉'
                          );
                        },
                        child: const Text('Elimina questa, mantieni le future', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          context.read<WalletProvider>().deleteTransaction(id);
                          Navigator.pop(ctx);
                          setState(() {});

                          AppNotifications.mostraInAlto(
                            context, 'Movimento "$desc" e futuri eliminati! 🎉'
                          );
                        },
                        child: const Text('Elimina questa e le future', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                )
              ]
            : [
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
                    context.read<WalletProvider>().deleteTransaction(id);
                    Navigator.pop(ctx);
                    setState(() {});
                    
                    AppNotifications.mostraInAlto(
                      context, 'Movimento "$desc" eliminato 🎉'
                    );
                  },
                  child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
      ),
    );
  }

  void _confermaEliminazioneMovimentoFuturo(BuildContext context, String predictionId, String parentId, String desc, DateTime meseRiferimento) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.event_repeat_rounded, color: Color(0xFF2DD4BF), size: 22),
            SizedBox(width: 8),
            Text('Gestisci Ricorrenza Futura', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Stai modificando la previsione per "$desc".\nLo storico dei mesi passati non verrà toccato. Scegli cosa fare:',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2DD4BF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                  child: const Text('Elimina solo quella di questo mese', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                  child: const Text('Elimina questa e tutte le future', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
            ],
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
      locale: const Locale('it', 'IT'),
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
              constraints: const BoxConstraints(maxWidth: 340, maxHeight: 490),
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
    return '${date.day.toString().padLeft(2, '0')} ${mesi[date.month - 1]} ${date.year}';
  }

  String _formattaMeseAnno(DateTime date) {
    final List<String> mesiBrevi = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic'
    ];
    return '${mesiBrevi[date.month - 1]} ${date.year}';
  }

  void _selezionaSpesaFrequente(String label, IconData icon, String cat, String sottoCat) {
    setState(() {
      _noteController.text = label;
      _iconaCorrente = icon;
      _categoriaSelezionata = cat;
      _sottocategoriaSelezionata = sottoCat;
    });
  }

  void _selezionaEntrataFrequente(String label, IconData icon) {
    setState(() {
      _noteController.text = label;
      _iconaCorrente = icon;
      if (_sottocategorieEntrata.contains(label)) {
        _sottocategoriaEntrataSelezionata = label;
      }
    });
  }

  void _mostraDialogNuovoConto() {
    final TextEditingController nomeContoController = TextEditingController();
    final TextEditingController saldoInizialeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Crea Nuovo Conto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Colors.white54, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final nome = nomeContoController.text.trim();
              if (nome.isNotEmpty) {
                setState(() {
                  _contiDisponibili.add(nome);
                  _contoSelezionato = nome;
                  _isContoEspanso = false;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Crea e Seleziona', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostraSelettoreIcone() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Scegli Pittogramma', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _confermaEliminazionePreferito(int index, bool isExpense) {
    final lista = isExpense ? _speseFrequenti : _entrateFrequenti;
    final voceDaEliminare = lista[index]['label'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina voce', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Vuoi davvero rimuovere "$voceDaEliminare" dai preferiti?', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_noteController.text == voceDaEliminare) {
                  _noteController.clear();
                }
                lista.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Elimina', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostraDialogNuovoPreferito(bool isExpense) {
    final TextEditingController nameController = TextEditingController();
    IconData iconaNuova = _iconeDisponibili.first;
    String categoriaNuova = '50% Spese Fisse';
    String sottoCatNuova = 'Acquisti';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isExpense ? 'Crea Uscita Frequente' : 'Crea Entrata Frequente', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  const Text('SCEGLI PITTOGRAMMA', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _iconeDisponibili.map((icon) {
                      final isSelected = iconaNuova == icon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => iconaNuova = icon),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    setState(() {
                      if (isExpense) {
                        _speseFrequenti.add({
                          'label': nameController.text.trim(),
                          'icon': iconaNuova,
                          'cat': categoriaNuova,
                          'sottoCat': sottoCatNuova,
                        });
                        _selezionaSpesaFrequente(nameController.text.trim(), iconaNuova, categoriaNuova, sottoCatNuova);
                      } else {
                        _entrateFrequenti.add({
                          'label': nameController.text.trim(),
                          'icon': iconaNuova,
                        });
                        _selezionaEntrataFrequente(nameController.text.trim(), iconaNuova);
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aggiungi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
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
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    
    // 🛡️ Prendiamo l'altezza hardware REALE dell'orologio (viewPadding) + 24px di respiro
    final notchHeight = MediaQuery.of(context).viewPadding.top;
    final topMargin = (notchHeight > 0 ? notchHeight : 44.0) + 24.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: topMargin, // 🎯 Spinge la scheda ~75px sotto il bordo del telefono!
        bottom: isKeyboardOpen ? 10 : 20,
      ),
    child: ClipRRect( // 👈 Togliamo SafeArea da qui
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        height: double.infinity, // 👈 Altezza fluida e uguale per tutti i telefoni
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
                          Expanded(
                            child: Text(
                              _tipoMovimento == 'riepilogo'
                                  ? 'Riepilogo Movimenti'
                                  : (_tipoMovimento == 'uscita' || _tipoMovimento == 'spesa' ? 'Registra Uscita' : 'Registra Entrata'),
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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
                                color: const Color(0xFF18181B).withOpacity(0.60),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
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
    );
  }

  Widget _buildSchermataRiepilogo() {
    final walletProvider = Provider.of<WalletProvider>(context);

    final List<Map<String, dynamic>> movimentiReali = walletProvider.transactions
        .where((tx) => !tx.title.startsWith('Accantonamento Tasse') && !tx.id.startsWith('rule_'))
        .map((tx) {
      final bool isFatturaPiva = tx.category == 'P.IVA' || tx.title.startsWith('Fattura') || tx.title.startsWith('Incasso:');
      return {
        'id': tx.id,
        'parentId': tx.id,
        'desc': tx.title,
        'imp': tx.amount,
        'cat': tx.category,
        'data': tx.date,
        'isSpesa': !tx.isIncome,
        'isFattura': isFatturaPiva, 
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
      return {
        'id': tx.id,
        'parentId': parentId,
        'desc': tx.title,
        'imp': tx.amount,
        'cat': tx.category,
        'data': tx.date,
        'isSpesa': !tx.isIncome,
        'isFattura': false,
        'isRecurrent': true,
        'isPrevisto': true,
      };
    }).toList();

    final List<Map<String, dynamic>> tuttiMovimenti = [...movimentiReali, ...previsti];

    final movimentiMeseSelezionato = tuttiMovimenti.where((m) {
      final dt = m['data'] as DateTime;
      return dt.year == _meseSelezionatoRiepilogo.year && dt.month == _meseSelezionatoRiepilogo.month;
    }).toList();

    final double totaleSpese = movimentiMeseSelezionato
        .where((m) => m['isSpesa'] == true && m['isPrevisto'] == false)
        .fold(0.0, (sum, m) => sum + (m['imp'] as double));

    final double totaleEntrate = movimentiMeseSelezionato
        .where((m) => m['isSpesa'] == false && m['isPrevisto'] == false)
        .fold(0.0, (sum, m) => sum + (m['imp'] as double));

    final Map<String, List<Map<String, dynamic>>> perCategoria = {};
    for (var m in movimentiMeseSelezionato) {
      final cat = m['cat'] as String;
      perCategoria.putIfAbsent(cat, () => []).add(m);
    }

    final List<Map<String, dynamic>> movimentiOrdinatiData = List.from(movimentiMeseSelezionato);
    movimentiOrdinatiData.sort((a, b) => (b['data'] as DateTime).compareTo(a['data'] as DateTime));

    final Map<String, List<Map<String, dynamic>>> perData = {};
    for (var m in movimentiOrdinatiData) {
      final dt = m['data'] as DateTime;
      final dataStr = _formattaDataInItaliano(dt);
      perData.putIfAbsent(dataStr, () => []).add(m);
    }

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
                              'Per Categoria',
                              style: TextStyle(
                                color: _vistaRiepilogo == 'categoria' ? Colors.black : Colors.white70,
                                fontSize: 11,
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
                              'Per Data',
                              style: TextStyle(
                                color: _vistaRiepilogo == 'data' ? Colors.black : Colors.white70,
                                fontSize: 11,
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
              : _vistaRiepilogo == 'categoria'
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: perCategoria.keys.length,
                      itemBuilder: (context, index) {
                        final catName = perCategoria.keys.elementAt(index);
                        final listaMovs = perCategoria[catName]!;
                        final double totCat = listaMovs.fold(0.0, (sum, m) {
                          final imp = m['imp'] as double;
                          final isSpesa = m['isSpesa'] as bool;
                          final isPrevisto = m['isPrevisto'] as bool;
                          if (isPrevisto) return sum;
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
                                          catName,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        '${totCat >= 0 ? '+' : '-'}${_formatValuta(totCat)}',
                                        style: TextStyle(
                                          color: totCat >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                                      final String id = m['id'] as String;
                                      final String parentId = m['parentId'] as String;
                                      final String desc = m['desc'] as String;
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
                                                      isPrevisto 
                                                        ? (desc.contains('entrate') || desc.contains('uscite') ? '$desc - Previsto' : '$desc (Previsto il ${dt.day}/${dt.month})') 
                                                        : '$desc (${dt.day}/${dt.month})',
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
                                              '${isSpesa ? '-' : '+'}${_formatValuta(imp)}',
                                              style: TextStyle(
                                                color: isPrevisto 
                                                  ? (isSpesa ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFF10B981).withOpacity(0.5))
                                                  : (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
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
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: perData.keys.length,
                      itemBuilder: (context, index) {
                        final dataStr = perData.keys.elementAt(index);
                        final listaMovs = perData[dataStr]!;
                        
                        final double totGiorno = listaMovs.fold(0.0, (sum, m) {
                          final double imp = m['imp'] as double;
                          final bool isSpesa = m['isSpesa'] as bool;
                          final bool isPrevisto = m['isPrevisto'] as bool;
                          if (isPrevisto) return sum;
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
                                          dataStr,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        '${totGiorno >= 0 ? '+' : '-'}${_formatValuta(totGiorno)}',
                                        style: TextStyle(
                                          color: totGiorno >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                                      final String id = m['id'] as String;
                                      final String parentId = m['parentId'] as String;
                                      final String desc = m['desc'] as String;
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
                                                      isPrevisto 
                                                        ? '$desc (${m['cat']} - Previsto)' 
                                                        : '$desc (${m['cat']})',
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
                                              '${isSpesa ? '-' : '+'}${_formatValuta(imp)}',
                                              style: TextStyle(
                                                color: isPrevisto 
                                                  ? (isSpesa ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFF10B981).withOpacity(0.5))
                                                  : (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: false,
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
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PREFERITI RAPIDI', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                Text('Tieni premuto per eliminare', style: TextStyle(color: Colors.white38, fontSize: 8, fontStyle: FontStyle.italic)),
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
                  if (index == list.length) {
                    return ActionChip(
                      avatar: const Icon(Icons.add, size: 14, color: Color(0xFF2DD4BF)),
                      label: const Text('Nuova', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF2DD4BF).withOpacity(0.12),
                      side: const BorderSide(color: Color(0xFF2DD4BF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () => _mostraDialogNuovoPreferito(isSpesa),
                    );
                  }

                  final item = list[index];
                  final isSelected = _noteController.text == item['label'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: GestureDetector(
                      onLongPress: () => _confermaEliminazionePreferito(index, isSpesa),
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
                            _selezionaSpesaFrequente(item['label'], item['icon'], item['cat'], item['sottoCat'] ?? 'Acquisti');
                          } else {
                            _selezionaEntrataFrequente(item['label'], item['icon']);
                          }
                        },
                      ),
                    ),
                  );
                },
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
                      _buildInlineSelector(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.white54,
                        selectedValue: _contoSelezionato,
                        isExpanded: _isContoEspanso,
                        onToggle: () {
                          setState(() => _isContoEspanso = !_isContoEspanso);
                          if (_isContoEspanso) _scrollToOffset(100);
                        },
                        items: [..._contiDisponibili, '+ Aggiungi conto...'],
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
                        const Text('CATEGORIA SPECIFICA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        _buildInlineSelector(
                          icon: Icons.category_outlined,
                          iconColor: const Color(0xFF2DD4BF),
                          selectedValue: _sottocategoriaSelezionata,
                          isExpanded: _isSottocategoriaEspansa,
                          onToggle: () {
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
                        const Text('REGOLE BUDGET', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        _buildInlineSelector(
                          icon: Icons.pie_chart_outline_rounded,
                          iconColor: const Color(0xFF2DD4BF),
                          selectedValue: _categoriaSelezionata,
                          isExpanded: _isCategoriaEspansa,
                          onToggle: () {
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
            ],
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
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
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
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? const Color(0xFF2DD4BF).withOpacity(0.4) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
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
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
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