import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_secondary_popup.dart';
import '../widgets_shared/app_datepicker.dart';
import '../widgets_shared/app_image_picker.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '../screens/0_1_pro_upgrade.dart';
import '../services/document_scanner_service.dart';
import 'package:flutter/services.dart';

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
    'Ristoranti & Bar',
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
    {'label': 'Supermercato', 'icon': Icons.shopping_cart_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Alimentari'},
    {'label': 'Affitto', 'icon': Icons.home_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Casa/Affitto'},
    {'label': 'Mutuo', 'icon': Icons.account_balance_outlined, 'cat': '50% Spese Fisse', 'sottoCat': 'Casa/Affitto'},
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
      tipo: tipo, // Passa se scontrino o fattura
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

      // 🎯 Auto-compilazione Categoria Specifica
      if (result.categoriaSuggerita != null && result.categoriaSuggerita!.isNotEmpty) {
        if (_sottocategorieSpesa.contains(result.categoriaSuggerita)) {
          _sottocategoriaSelezionata = result.categoriaSuggerita!;
        }
      }

      // 🎯 Auto-compilazione Bussola Spese (50%, 30%, 20%)
      if (result.bussolaSuggerita != null && result.bussolaSuggerita!.isNotEmpty) {
        if (_categorieSpesa.contains(result.bussolaSuggerita)) {
          _categoriaSelezionata = result.bussolaSuggerita!;
        }
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

  // ⚠️ POP-UP ALERT DI SICUREZZA PRIMA DELL'ELIMINAZIONE TOTALE DELLO STORICO
  void _mostraAlertConfermaEliminazioneTotale(BuildContext context, String id, String desc, VoidCallback onConcluso) {
    showDialog(
      context: context,
      builder: (ctxAlert) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.warning_rounded,
        iconColor: const Color(0xFFEF4444),
        titolo: '⚠️ ELIMINAZIONE TOTALE',
        testoAnnulla: 'Annulla',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sei sicuro di voler eliminare TUTTI i movimenti di "$desc"?\n\n'
              '🚨 Verrà cancellato anche lo STORICO PASSATO nei mesi precedenti. L\'operazione è irreversibile.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
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
                  Navigator.pop(ctxAlert);
                  onConcluso();
                  AppNotifications.mostraInAlto(
                    context,
                    'Intera serie di "$desc" eliminata (compreso lo storico passato)',
                    type: NotificationType.error,
                  );
                },
                child: const Text(
                  'SÌ, ELIMINA ANCHE LO STORICO PASSATO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛑 POP-UP ELIMINAZIONE MOVIMENTI REALI/PASSATI
  void _confermaEliminazioneMovimento(BuildContext context, String id, String desc, bool isRecurrent) {
    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
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
                      side: const BorderSide(color: Color(0xFF2DD4BF)),
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
                    child: const Text('Mantieni questa, cancella le future', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2DD4BF)),
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
                    child: const Text('Elimina questa, mantieni le future', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 11)),
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
                      context.read<WalletProvider>().stopRecurrence(id);
                      context.read<WalletProvider>().deleteTransaction(id);
                      Navigator.pop(ctx);
                      setState(() {});
                      AppNotifications.mostraInAlto(
                        context, 'Movimento "$desc" e futuri eliminati! (Storico passato salvo)',
                      );
                    },
                    child: const Text('Elimina questa e le future (Salva il passato)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                    label: const Text(
                      'Elimina TUTTE (comprese le passate)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mostraAlertConfermaEliminazioneTotale(context, id, desc, () {
                        setState(() {});
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 🔮 POP-UP ELIMINAZIONE PREVISIONI FUTURE
  void _confermaEliminazioneMovimentoFuturo(BuildContext context, String predictionId, String parentId, String desc, DateTime meseRiferimento) {
    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
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
                'Stai modificando la previsione per "$desc".\nScegli come procedere:',
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
                    provider.stopRecurrenceFromDate(parentId, meseRiferimento);
                    Navigator.pop(ctx);
                    setState(() {});

                    AppNotifications.mostraInAlto(
                      context,
                      'Ricorrenza disdetta da questo mese in poi! Lo storico passato è salvo.',
                      type: NotificationType.warning,
                    );
                  },
                  child: const Text('Elimina questa e tutte le future (Salva il passato)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text(
                    'Elimina TUTTE (comprese le passate)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _mostraAlertConfermaEliminazioneTotale(context, parentId, desc, () {
                      setState(() {});
                    });
                  },
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
    String sottoCatTemp = item['sottoCat'] ?? (isExpense ? 'Alimentari' : 'Stipendio');

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
                    DropdownButtonFormField<String>(
                      value: catTemp,
                      dropdownColor: const Color(0xFF121214),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
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
                    dropdownColor: const Color(0xFF121214),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
                    ),
                    items: (isExpense ? _sottocategorieSpesa : _sottocategorieEntrata)
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => sottoCatTemp = v);
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
                    DropdownButtonFormField<String>(
                      value: categoriaNuova,
                      dropdownColor: const Color(0xFF121214),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
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
                    dropdownColor: const Color(0xFF121214),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final String titoloModal = _tipoMovimento == 'riepilogo'
        ? 'Riepilogo Movimenti'
        : (_tipoMovimento == 'uscita' || _tipoMovimento == 'spesa' ? 'Registra Uscita' : 'Registra Entrata');

    return AppBottomSheet(
      title: titoloModal,
      badgeText: 'Wallet',
      badgeColor: const Color(0xFF2DD4BF),
      child: Container(
        height: screenHeight * 0.55, 
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
                      onTap: () => setState(() => _tipoMovimento = 'riepilogo'),
                    ),
                  ),
                  Expanded(
                    child: _buildTypeTab(
                      label: 'Uscita',
                      isSelected: _tipoMovimento == 'uscita' || _tipoMovimento == 'spesa',
                      color: const Color(0xFFEF4444),
                      onTap: () => setState(() => _tipoMovimento = 'uscita'),
                    ),
                  ),
                  Expanded(
                    child: _buildTypeTab(
                      label: 'Entrata',
                      isSelected: _tipoMovimento == 'entrata',
                      color: const Color(0xFF10B981),
                      onTap: () => setState(() => _tipoMovimento = 'entrata'),
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
        'isPrevisto': true, // 👈 Identifica che la fonte è una regola di previsione
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
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2DD4BF), size: 16),
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
                              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2DD4BF), size: 20),
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
                              color: const Color(0xFF2DD4BF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.5)),
                            ),
                            child: const Text(
                              'Oggi',
                              style: TextStyle(
                                color: Color(0xFF2DD4BF),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 12,
                                color: _vistaRiepilogo == 'categoria' ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Categoria',
                                style: TextStyle(
                                  color: _vistaRiepilogo == 'categoria' ? Colors.black : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.explore_outlined,
                                size: 12,
                                color: _vistaRiepilogo == 'bussola' ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Bussola',
                                style: TextStyle(
                                  color: _vistaRiepilogo == 'bussola' ? Colors.black : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: _vistaRiepilogo == 'data' ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Data',
                                style: TextStyle(
                                  color: _vistaRiepilogo == 'data' ? Colors.black : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                      onPressed: () => setState(() => _tipoMovimento = 'uscita'),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                      label: const Text(
                        'Registra primo movimento',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

                    final double totGruppo = listaMovs.fold(0.0, (sum, m) {
                      final imp = m['imp'] as double;
                      final isSpesa = m['isSpesa'] as bool;
                      final isGiroconto = m['isGiroconto'] as bool? ?? false;
                      if (isGiroconto) return sum;
                      return sum + (isSpesa ? -imp : imp);
                    });
                    final bool isEspansa = _categoriaEspansaIndex == index;

                    final bool isGruppoSpesa = listaMovs.any((m) => m['isSpesa'] == true);
                    final String segnoGruppo = isCategoriaGiroconto 
                        ? '⇄ ' 
                        : (totGruppo < 0 
                            ? '-' 
                            : (totGruppo > 0 
                                ? '+' 
                                : (isGruppoSpesa ? '-' : '+')));

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
                                    '$segnoGruppo${_formatValuta(totGruppo)}',
                                    style: TextStyle(
                                      color: isCategoriaGiroconto 
                                          ? const Color(0xFF3B82F6)
                                          : (segnoGruppo == '+' ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
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

                                  // 💡 DETERMINA LO STILE VISIVO IN BASE ALLA DATA CORRENTE
                                  final bool isFuturo = dt.isAfter(DateTime.now());

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
                                                  color: isFuturo ? Colors.white38 : const Color(0xFF2DD4BF),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  _vistaRiepilogo == 'bussola'
                                                      ? '$desc ($catSpecifica)'
                                                      : (isPrevisto ? '$desc (Previsto il ${dt.day}/${dt.month})' : '$desc (${dt.day}/${dt.month})'),
                                                  style: TextStyle(
                                                    color: isFuturo 
                                                        ? Colors.white38 
                                                        : (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
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
                                          isGiroconto 
                                              ? _formatValuta(imp)
                                              : '${isSpesa ? '-' : '+'}${_formatValuta(imp)}',
                                          style: TextStyle(
                                            color: isGiroconto
                                                ? const Color(0xFF3B82F6)
                                                : (isFuturo 
                                                  ? (isSpesa ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFF10B981).withOpacity(0.4))
                                                  : (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (isFattura) return rowContent;

                                  return Dismissible(
                                    key: Key('riepilogo_dismiss_${id}_$parentId'),
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
                                        _confermaEliminazioneMovimento(context, id, desc, isRecurrent);
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
            
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _amountFocusNode.hasFocus && _amountController.text.isNotEmpty
                    ? [
                        BoxShadow(
                          color: (isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.18),
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
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          ThousandsSeparatorInputFormatter(), // 👈 AGGIUNTA QUESTA RIGA
                        ],
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

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TERMINE RICORRENZA (OPZIONALE)', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final picked = await AppDatePicker.selezionaData(
                              context,
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
                  backgroundColor: isSpesa 
                      ? const Color(0xFFEF4444) 
                      : const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
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
                        fontWeight: _isPreferitoSelezionato ? FontWeight.w600 : FontWeight.w600,
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
} // 👈 Questa parentesi chiude _AddMovementSheetState

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