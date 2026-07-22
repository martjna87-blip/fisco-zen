import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class AddMovementSheet extends StatefulWidget {
  const AddMovementSheet({super.key});

  @override
  State<AddMovementSheet> createState() => _AddMovementSheetState();
}

class _AddMovementSheetState extends State<AddMovementSheet> {
  String _tipoMovimento = 'riepilogo'; // 'riepilogo', 'spesa' o 'entrata'
  String _vistaRiepilogo = 'categoria'; // 'categoria' o 'data'
  int? _categoriaEspansaIndex; 

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _giornoRicorrenzaController = TextEditingController(text: '1');
  
  final ScrollController _scrollController = ScrollController();

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

  final List<Map<String, dynamic>> _movimentiReali = [];

  bool _isCategoriaEspansa = false;
  bool _isSottocategoriaEspansa = false;
  bool _isContoEspanso = false;
  bool _isFrequenzaEspansa = false;
  bool _isMeseEspanso = false;

  bool _isRicorrente = false;
  String _frequenzaSelezionata = 'Ogni mese';
  String _meseRicorrenzaSelezionato = 'Gennaio';

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
    _noteController.addListener(_suggerisciCategoriaAuto);
  }

  @override
  void dispose() {
    _noteController.removeListener(_suggerisciCategoriaAuto);
    _amountController.dispose();
    _noteController.dispose();
    _giornoRicorrenzaController.dispose();
    _scrollController.dispose();
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

  void _salvaMovimento() {
    final importo = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (importo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido!'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    final bool isSpesa = _tipoMovimento == 'spesa';
    final String descrizione = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : (isSpesa ? 'Nuova Spesa' : 'Nuova Entrata');

    String categoriaProvider = 'Bisogni';
    if (isSpesa) {
      if (_categoriaSelezionata.contains('30%')) {
        categoriaProvider = 'Svago';
      } else if (_categoriaSelezionata.contains('20%')) {
        categoriaProvider = 'Risparmi';
      } else {
        categoriaProvider = 'Bisogni';
      }
    } else {
      categoriaProvider = 'P.IVA';
    }

    String? accountId;
    if (_contoSelezionato.contains('Carta Spese')) {
      accountId = '2';
    } else if (_contoSelezionato.contains('Salvadanaio')) {
      accountId = '3';
    } else {
      accountId = '1';
    }

    context.read<WalletProvider>().addTransaction(
      title: descrizione,
      amount: importo,
      isIncome: !isSpesa,
      category: categoriaProvider,
      accountId: accountId,
    );

    setState(() {
      _movimentiReali.add({
        'desc': descrizione,
        'imp': importo,
        'cat': isSpesa ? _sottocategoriaSelezionata : 'Entrate',
        'macroCat': isSpesa ? _categoriaSelezionata : 'Entrate',
        'conto': _contoSelezionato,
        'data': _dataSelezionata,
        'isSpesa': isSpesa,
      });

      _amountController.clear();
      _noteController.clear();
      _meseSelezionatoRiepilogo = DateTime(_dataSelezionata.year, _dataSelezionata.month);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Movimento "$descrizione" registrato con successo!'),
        backgroundColor: const Color(0xFF2DD4BF),
      ),
    );

    Navigator.pop(context);
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
            title: Text(isExpense ? 'Crea Spesa Frequente' : 'Crea Entrata Frequente', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: isExpense ? 'Nome spesa (es. Idraulico)' : 'Nome entrata (es. Dividendi)',
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
    Future.delayed(const Duration(milliseconds: 180), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          (_scrollController.offset + deltaPixels).clamp(0.0, _scrollController.position.maxScrollExtent),
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
    
    final bool isSpesa = _tipoMovimento == 'spesa';

    final bool mostraMeseInizio = [
      'Ogni 2 mesi',
      'Ogni 3 mesi (Trimestrale)',
      'Ogni 6 mesi (Semestrale)',
      'Ogni anno (Annuale)',
    ].contains(_frequenzaSelezionata);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 10, 
        vertical: isKeyboardOpen ? 10 : 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: double.infinity,
          height: screenSize.height * 0.88,
          child: Stack(
            children: [
              // 1. IMMAGINE SFONDO ATMOSFERICA
              Positioned.fill(
                child: Image.network(
                  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),

              // 2. OVERLAY SCURO SFUMATO
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                ),
              ),

              // 3. CONTENUTO CON HEADER CIRCOLARE E SCHEDE GLASS
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // --- HEADER CON BOTTONE (X) CIRCOLARE IDENTICO A REGISTRA FATTURA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            Text(
                              _tipoMovimento == 'riepilogo'
                                  ? 'Riepilogo Movimenti'
                                  : (_tipoMovimento == 'spesa' ? 'Registra Spesa' : 'Registra Entrata'),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_tipoMovimento != 'riepilogo')
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Apertura fotocamera...'),
                                  backgroundColor: Color(0xFF2DD4BF),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Scansiona', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // 🔲 RIQUADRO 1: CORPO PRINCIPALE GLASSMORPHIC
                    // ==========================================
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
                                // SELETTORE TAB: RIEPILOGO | SPESA | ENTRATA
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
                                          label: 'Spesa',
                                          isSelected: _tipoMovimento == 'spesa',
                                          color: const Color(0xFFEF4444),
                                          onTap: () => setState(() => _tipoMovimento = 'spesa'),
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

                                // CONTENUTO FORM O RIEPILOGO
                                Expanded(
                                  child: _tipoMovimento == 'riepilogo'
                                      ? _buildSchermataRiepilogo()
                                      : SingleChildScrollView(
                                          controller: _scrollController,
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
                                                // IMPORTO
                                                Center(
                                                  child: IntrinsicWidth(
                                                    child: TextField(
                                                      controller: _amountController,
                                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                      autofocus: false,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                        fontSize: 34,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      decoration: InputDecoration(
                                                        hintText: '0,00 €',
                                                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 34),
                                                        border: InputBorder.none,
                                                        prefixText: isSpesa ? '- ' : '+ ',
                                                        prefixStyle: TextStyle(
                                                          color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                          fontSize: 34,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(height: 10),

                                                // DESCRIZIONE
                                                TextField(
                                                  controller: _noteController,
                                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                                  decoration: InputDecoration(
                                                    labelText: isSpesa ? 'Descrizione' : 'Descrizione (es. Stipendio)',
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

                                                // PREFERITI
                                                const SizedBox(height: 10),
                                                const Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text('PREFERITI', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                                    Text('Tieni premuto per eliminare', style: TextStyle(color: Colors.white38, fontSize: 8, fontStyle: FontStyle.italic)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  height: 36,
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

                                                const SizedBox(height: 12),

                                                // DATA MOVIMENTO
                                                const Text('DATA MOVIMENTO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                                const SizedBox(height: 4),
                                                InkWell(
                                                  onTap: () => _selezionaData(context),
                                                  borderRadius: BorderRadius.circular(14),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.35),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
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

                                                const SizedBox(height: 12),

                                                // SOTTOCATEGORIA SPECIFICA
                                                if (isSpesa) ...[
                                                  const Text('CATEGORIA SPECIFICA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  _buildInlineSelector(
                                                    icon: Icons.category_outlined,
                                                    iconColor: const Color(0xFF2DD4BF),
                                                    selectedValue: _sottocategoriaSelezionata,
                                                    isExpanded: _isSottocategoriaEspansa,
                                                    onToggle: () {
                                                      setState(() {
                                                        _isSottocategoriaEspansa = !_isSottocategoriaEspansa;
                                                      });
                                                      if (_isSottocategoriaEspansa) _scrollToOffset(120);
                                                    },
                                                    items: _sottocategorieSpesa,
                                                    onSelect: (val) {
                                                      setState(() {
                                                        _sottocategoriaSelezionata = val;
                                                        _isSottocategoriaEspansa = false;
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],

                                                // CATEGORIA BUDGET
                                                if (isSpesa) ...[
                                                  const Text('REGOLE BUDGET', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  _buildInlineSelector(
                                                    icon: Icons.pie_chart_outline_rounded,
                                                    iconColor: const Color(0xFF2DD4BF),
                                                    selectedValue: _categoriaSelezionata,
                                                    isExpanded: _isCategoriaEspansa,
                                                    onToggle: () {
                                                      setState(() {
                                                        _isCategoriaEspansa = !_isCategoriaEspansa;
                                                      });
                                                      if (_isCategoriaEspansa) _scrollToOffset(120);
                                                    },
                                                    items: _categorieSpesa,
                                                    onSelect: (val) {
                                                      setState(() {
                                                        _categoriaSelezionata = val;
                                                        _isCategoriaEspansa = false;
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],

                                                // SELEZIONE CONTO
                                                const Text('SELEZIONA CONTO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                _buildInlineSelector(
                                                  icon: Icons.account_balance_wallet_outlined,
                                                  iconColor: Colors.white54,
                                                  selectedValue: _contoSelezionato,
                                                  isExpanded: _isContoEspanso,
                                                  onToggle: () {
                                                    setState(() {
                                                      _isContoEspanso = !_isContoEspanso;
                                                    });
                                                    if (_isContoEspanso) _scrollToOffset(140);
                                                  },
                                                  items: [..._contiDisponibili, '+ Aggiungi nuovo conto...'],
                                                  onSelect: (val) {
                                                    if (val == '+ Aggiungi nuovo conto...') {
                                                      _mostraDialogNuovoConto();
                                                    } else {
                                                      setState(() {
                                                        _contoSelezionato = val;
                                                        _isContoEspanso = false;
                                                      });
                                                    }
                                                  },
                                                ),

                                                const SizedBox(height: 12),

                                                // SEZIONE MOVIMENTO RICORRENTE
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
                                                      SwitchListTile(
                                                        contentPadding: EdgeInsets.zero,
                                                        title: const Text('Movimento Ricorrente', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                                        subtitle: const Text('Es. Abbonamento mensile, affitto o stipendio', style: TextStyle(color: Colors.white38, fontSize: 9)),
                                                        activeColor: const Color(0xFF2DD4BF),
                                                        value: _isRicorrente,
                                                        onChanged: (val) {
                                                          setState(() {
                                                            _isRicorrente = val;
                                                          });
                                                          if (val) _scrollToOffset(200);
                                                        },
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
                                                                setState(() {
                                                                  _isFrequenzaEspansa = !_isFrequenzaEspansa;
                                                                });
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
                                                                        setState(() {
                                                                          _isMeseEspanso = !_isMeseEspanso;
                                                                        });
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
                                                              flex: 1,
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  const Text('GIORNO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
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
                                                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
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

                                                const SizedBox(height: 14),

                                                // PULSANTE SALVA VERDE ACQUA IDENTICO A "REGISTRA E SALVA FATTURA"
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 44,
                                                  child: ElevatedButton(
                                                    onPressed: _salvaMovimento,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF2DD4BF),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      elevation: 0,
                                                    ),
                                                    child: const Text(
                                                      'Salva Movimento',
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
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (!isKeyboardOpen) ...[
                      const SizedBox(height: 12),

                      // ==========================================
                      // 🔲 RIQUADRO 2: TASTO CHIUDI BOTTOM GLASS
                      // ==========================================
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B).withOpacity(0.65),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Annulla e Chiudi',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SCHERMATA RIEPILOGO DINAMICA
  Widget _buildSchermataRiepilogo() {
    final movimentiMeseSelezionato = _movimentiReali.where((m) {
      final dt = m['data'] as DateTime;
      return dt.year == _meseSelezionatoRiepilogo.year && dt.month == _meseSelezionatoRiepilogo.month;
    }).toList();

    final double totaleSpese = movimentiMeseSelezionato
        .where((m) => m['isSpesa'] == true)
        .fold(0.0, (sum, m) => sum + (m['imp'] as double));

    final double totaleEntrate = movimentiMeseSelezionato
        .where((m) => m['isSpesa'] == false)
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2DD4BF), size: 16),
                    onPressed: () {
                      setState(() {
                        _meseSelezionatoRiepilogo = DateTime(_meseSelezionatoRiepilogo.year, _meseSelezionatoRiepilogo.month - 1);
                        _categoriaEspansaIndex = null;
                      });
                    },
                  ),
                  Text(
                    _formattaMeseAnno(_meseSelezionatoRiepilogo),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF2DD4BF), size: 16),
                    onPressed: () {
                      setState(() {
                        _meseSelezionatoRiepilogo = DateTime(_meseSelezionatoRiepilogo.year, _meseSelezionatoRiepilogo.month + 1);
                        _categoriaEspansaIndex = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Entrate: +${_formatValuta(totaleEntrate)}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('•', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Spese: -${_formatValuta(totaleSpese)}',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),

        Expanded(
          child: movimentiMeseSelezionato.isEmpty
              ? const Center(
                  child: Text('Nessun movimento registrato in questo mese.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                )
              : _vistaRiepilogo == 'categoria'
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: perCategoria.keys.length,
                      itemBuilder: (context, index) {
                        final catName = perCategoria.keys.elementAt(index);
                        final listaMovs = perCategoria[catName]!;
                        final double totCat = listaMovs.fold(0.0, (sum, m) => sum + (m['imp'] as double));
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
                                        _formatValuta(totCat),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${m['desc']} (${dt.day}/${dt.month})', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                            Text(
                                              '${isSpesa ? '-' : '+'}${_formatValuta(imp)}',
                                              style: TextStyle(
                                                color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                                      final isSpesa = m['isSpesa'] as bool;
                                      final imp = m['imp'] as double;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${m['desc']} (${m['cat']})', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                            Text(
                                              '${isSpesa ? '-' : '+'}${_formatValuta(imp)}',
                                              style: TextStyle(
                                                color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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

        const SizedBox(height: 8),

        // SWITCH IN BASSO [ Per Categoria ] | [ Per Data ]
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _vistaRiepilogo = 'categoria';
                  _categoriaEspansaIndex = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _vistaRiepilogo == 'categoria' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
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
              GestureDetector(
                onTap: () => setState(() {
                  _vistaRiepilogo = 'data';
                  _categoriaEspansaIndex = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _vistaRiepilogo == 'data' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
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
            ],
          ),
        ),
      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedValue,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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