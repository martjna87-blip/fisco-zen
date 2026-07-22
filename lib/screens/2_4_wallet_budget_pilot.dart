import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class BudgetPilotSheet extends StatefulWidget {
  const BudgetPilotSheet({super.key});

  @override
  State<BudgetPilotSheet> createState() => _BudgetPilotSheetState();
}

class _BudgetPilotSheetState extends State<BudgetPilotSheet> {
  final ScrollController _scrollController = ScrollController();

  // NAVIGAZIONE TEMPORALE (Mese Corrente Selezionato)
  DateTime _meseSelezionato = DateTime(2026, 7); // Default: Luglio 2026

  // Percentuali OBIETTIVO ("Il Volere")
  double _percentFisse = 50.0;
  double _percentVariabili = 30.0;
  double _percentRisparmio = 20.0;
  double _entrateMensiliTotali = 2800.00;

  final List<String> _nomiMesi = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  // Lista delle voci di budget pianificate
  final List<Map<String, dynamic>> _vociPianificate = [
    {'nome': 'Affitto / Mutuo', 'categoria': '50% Spese Fisse', 'previsto': 600.00, 'speso': 600.00, 'ricorrente': true, 'meseSpecifico': null},
    {'nome': 'Bollette & Utenze', 'categoria': '50% Spese Fisse', 'previsto': 150.00, 'speso': 180.00, 'ricorrente': true, 'meseSpecifico': null},
    {'nome': 'Supermercato', 'categoria': '50% Spese Fisse', 'previsto': 350.00, 'speso': 340.00, 'ricorrente': true, 'meseSpecifico': null},
    {'nome': 'Bar & Ristoranti', 'categoria': '30% Spese Variabili', 'previsto': 100.00, 'speso': 120.00, 'ricorrente': true, 'meseSpecifico': null},
    {'nome': 'Svago & Hobby', 'categoria': '30% Spese Variabili', 'previsto': 150.00, 'speso': 80.00, 'ricorrente': true, 'meseSpecifico': null},
    {'nome': 'Tagliando Auto (Puntuale)', 'categoria': '50% Spese Fisse', 'previsto': 300.00, 'speso': 0.00, 'ricorrente': false, 'meseSpecifico': 'Novembre 2026'},
    {'nome': 'Regali di Natale (Puntuale)', 'categoria': '30% Spese Variabili', 'previsto': 250.00, 'speso': 0.00, 'ricorrente': false, 'meseSpecifico': 'Dicembre 2026'},
    {'nome': 'Idraulico (Extra)', 'categoria': '50% Spese Fisse', 'previsto': 0.00, 'speso': 100.00, 'ricorrente': false, 'meseSpecifico': 'Luglio 2026'},
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _stringaMeseAnno(DateTime dt) {
    return '${_nomiMesi[dt.month - 1]} ${dt.year}';
  }

  void _cambiaMese(int delta) {
    setState(() {
      _meseSelezionato = DateTime(_meseSelezionato.year, _meseSelezionato.month + delta);
    });
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

  // POPUP 1: IMPOSIZIONE OBIETTIVO PERCENTUALI & ENTRATE
  void _mostraDialogPersonalizzaPercentuali() {
    double tempFisse = _percentFisse;
    double tempVariabili = _percentVariabili;
    double tempRisparmio = _percentRisparmio;
    final TextEditingController entrateController = TextEditingController(text: _entrateMensiliTotali.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totale = tempFisse + tempVariabili + tempRisparmio;
          final bool isValid = (totale == 100.0);

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Obiettivo Ripartizione %', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: entrateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Entrate Mensili Stimate (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF2DD4BF), size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('REGOLA OBIETTIVO (%)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Text('Spese Fisse Target: ${tempFisse.toInt()}%', style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 12)),
                  Slider(
                    value: tempFisse,
                    min: 10,
                    max: 80,
                    divisions: 14,
                    activeColor: const Color(0xFF2DD4BF),
                    onChanged: (val) => setDialogState(() => tempFisse = val),
                  ),

                  Text('Spese Variabili Target: ${tempVariabili.toInt()}%', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                  Slider(
                    value: tempVariabili,
                    min: 10,
                    max: 80,
                    divisions: 14,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (val) => setDialogState(() => tempVariabili = val),
                  ),

                  Text('Risparmio Target: ${tempRisparmio.toInt()}%', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                  Slider(
                    value: tempRisparmio,
                    min: 0,
                    max: 50,
                    divisions: 10,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (val) => setDialogState(() => tempRisparmio = val),
                  ),

                  const Divider(color: Colors.white12),
                  Center(
                    child: Text(
                      'Totale %: ${totale.toInt()}%',
                      style: TextStyle(
                        color: isValid ? Colors.white70 : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
                onPressed: isValid
                    ? () {
                        setState(() {
                          _percentFisse = tempFisse;
                          _percentVariabili = tempVariabili;
                          _percentRisparmio = tempRisparmio;
                          _entrateMensiliTotali = double.tryParse(entrateController.text) ?? _entrateMensiliTotali;
                        });
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salva Obiettivo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // POPUP 2: AGGIUNGI VOCE SPECIFICA CON SELETTORE MESE ROBUSTO E VISIBILE
  void _mostraDialogAggiungiVoceBudget() {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController importoController = TextEditingController();
    String categoriaSelezionata = '50% Spese Fisse';
    bool isCategoriaEspansa = false;
    bool isRicorrente = true;
    bool isMeseEspanso = false;

    final int annoCorrente = _meseSelezionato.year;
    final bool includeAnnoSuccessivo = _meseSelezionato.month >= 10;

    final List<String> opzioniMesiPuntuali = [
      ..._nomiMesi.map((m) => '$m $annoCorrente'),
      if (includeAnnoSuccessivo)
        ..._nomiMesi.map((m) => '$m ${annoCorrente + 1}'),
    ];

    String meseSpecificoSelezionato = _stringaMeseAnno(_meseSelezionato);
    final List<String> categorie = ['50% Spese Fisse', '30% Spese Variabili', '20% Risparmio'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Pianifica Voce di Spesa', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nomeController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Nome voce (es. Tagliando Auto, Regali)',
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: importoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Budget Previsto (€)',
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('CATEGORIA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),

                    // SELETTORE IN-LINE CATEGORIA
                    _buildDialogInlineSelector(
                      selectedValue: categoriaSelezionata,
                      isExpanded: isCategoriaEspansa,
                      items: categorie,
                      onToggle: () => setDialogState(() {
                        isCategoriaEspansa = !isCategoriaEspansa;
                        if (isCategoriaEspansa) isMeseEspanso = false;
                      }),
                      onSelect: (val) {
                        setDialogState(() {
                          categoriaSelezionata = val;
                          isCategoriaEspansa = false;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    const Text('QUANDO APPLICARE?', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Ogni Mese', style: TextStyle(fontSize: 11)),
                            selected: isRicorrente,
                            selectedColor: const Color(0xFF2DD4BF),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            labelStyle: TextStyle(color: isRicorrente ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  isRicorrente = true;
                                  isMeseEspanso = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Solo 1 Mese', style: TextStyle(fontSize: 11)),
                            selected: !isRicorrente,
                            selectedColor: const Color(0xFF2DD4BF),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            labelStyle: TextStyle(color: !isRicorrente ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  isRicorrente = false;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // SELETTORE MESE IN-LINE
                    if (!isRicorrente) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DESTINAZIONE SPESA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                          if (includeAnnoSuccessivo)
                            Text('Mostra fino al ${annoCorrente + 1}', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildDialogInlineSelector(
                        selectedValue: meseSpecificoSelezionato,
                        isExpanded: isMeseEspanso,
                        items: opzioniMesiPuntuali,
                        maxHeight: 150, // Permette uno scroll morbido e sicuro
                        onToggle: () => setDialogState(() {
                          isMeseEspanso = !isMeseEspanso;
                          if (isMeseEspanso) isCategoriaEspansa = false;
                        }),
                        onSelect: (val) {
                          setDialogState(() {
                            meseSpecificoSelezionato = val;
                            isMeseEspanso = false;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  final nome = nomeController.text.trim();
                  final previsto = double.tryParse(importoController.text.replaceAll(',', '.')) ?? 0.0;

                  if (nome.isNotEmpty && previsto > 0) {
                    setState(() {
                      _vociPianificate.add({
                        'nome': nome,
                        'categoria': categoriaSelezionata,
                        'previsto': previsto,
                        'speso': 0.0,
                        'ricorrente': isRicorrente,
                        'meseSpecifico': isRicorrente ? null : meseSpecificoSelezionato,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aggiungi al Piano', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // DIALOG DETTAGLIO PER CATEGORIA
  void _mostraDettaglioCategoria(String categoria, Color colore) {
    final stringaMeseCorrente = _stringaMeseAnno(_meseSelezionato);

    final vociCategoria = _vociPianificate.where((v) {
      final matchesCategory = v['categoria'] == categoria;
      final isRicorrente = v['ricorrente'] == true;
      final isStessoMese = v['meseSpecifico'] == stringaMeseCorrente;
      return matchesCategory && (isRicorrente || isStessoMese);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Dettaglio $categoria ($stringaMeseCorrente)',
          style: TextStyle(color: colore, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: vociCategoria.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Nessuna voce pianificata per questo mese.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: vociCategoria.length,
                  itemBuilder: (context, index) {
                    final item = vociCategoria[index];
                    final double speso = item['speso'];
                    final double previsto = item['previsto'];
                    final bool isSforato = speso > previsto && previsto > 0;
                    final bool isNonPrevisto = previsto == 0;
                    final bool isPuntuale = item['ricorrente'] == false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSforato || isNonPrevisto ? const Color(0xFFEF4444).withOpacity(0.4) : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['nome'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              if (isPuntuale)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Solo questo mese', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Speso: ${speso.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  color: isSforato || isNonPrevisto ? const Color(0xFFEF4444) : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Previsto: ${previsto.toStringAsFixed(2)} €',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
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

  // COMPONENTE PERFETTAMENTE IN-LINE (ZERO PANELLI GRIGI VUOTI)
  Widget _buildDialogInlineSelector({
    required String selectedValue,
    required bool isExpanded,
    required List<String> items,
    required VoidCallback onToggle,
    required Function(String) onSelect,
    double maxHeight = 200,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? const Color(0xFF2DD4BF).withOpacity(0.4) : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
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
            Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((item) {
                    final bool isSelected = item == selectedValue;
                    return InkWell(
                      onTap: () => onSelect(item),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.12) : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: isSelected ? const Color(0xFF2DD4BF) : Colors.white24,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final stringaMeseCorrente = _stringaMeseAnno(_meseSelezionato);

    final targetMaxFisse = _entrateMensiliTotali * (_percentFisse / 100);
    final targetMaxVariabili = _entrateMensiliTotali * (_percentVariabili / 100);
    final targetMaxRisparmio = _entrateMensiliTotali * (_percentRisparmio / 100);

    // FILTRAGGIO DINAMICO PER IL MESE SELEZIONATO
    double spesoFisse = 0;
    double previstoFisse = 0;
    double spesoVariabili = 0;
    double previstoVariabili = 0;
    double spesoRisparmio = 0;
    double previstoRisparmio = 0;

    for (var item in _vociPianificate) {
      final isRicorrente = item['ricorrente'] == true;
      final isStessoMese = item['meseSpecifico'] == stringaMeseCorrente;

      if (isRicorrente || isStessoMese) {
        if (item['categoria'] == '50% Spese Fisse') {
          spesoFisse += item['speso'];
          previstoFisse += item['previsto'];
        } else if (item['categoria'] == '30% Spese Variabili') {
          spesoVariabili += item['speso'];
          previstoVariabili += item['previsto'];
        } else if (item['categoria'] == '20% Risparmio') {
          spesoRisparmio += item['speso'];
          previstoRisparmio += item['previsto'];
        }
      }
    }

    final double totaleSpesoReale = spesoFisse + spesoVariabili + spesoRisparmio;

    final double pctRealeFisse = totaleSpesoReale > 0 ? (spesoFisse / totaleSpesoReale) * 100 : 0;
    final double pctRealeVariabili = totaleSpesoReale > 0 ? (spesoVariabili / totaleSpesoReale) * 100 : 0;
    final double pctRealeRisparmio = totaleSpesoReale > 0 ? (spesoRisparmio / totaleSpesoReale) * 100 : 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SFONDO FOTOGRAFICO CLICCABILE PER CHIUDERE
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: screenHeight * 0.76,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.80),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CARD SCURA IN VETRO TRASPARENTE
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 18),
              child: Container(
                height: screenHeight * 0.72,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417).withOpacity(0.68),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INTESTAZIONE CON CHIUSURA (X) E TASTI AZIONE
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
                              tooltip: 'Chiudi',
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pilotaggio Budget',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: _mostraDialogPersonalizzaPercentuali,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _mostraDialogAggiungiVoceBudget,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.add_rounded, color: Color(0xFF2DD4BF), size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Voce',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // NAVIGATORE MESE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
                            onPressed: () => _cambiaMese(-1),
                            tooltip: 'Mese Precedente',
                          ),
                          Text(
                            stringaMeseCorrente.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                            onPressed: () => _cambiaMese(1),
                            tooltip: 'Mese Successivo',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // CONTENUTO SCROLLABILE
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CIAMBELLA REALE VS OBIETTIVO
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CustomPaint(
                                      painter: _BudgetDonutPainter(
                                        pctFisse: pctRealeFisse,
                                        pctVariabili: pctRealeVariabili,
                                        pctRisparmio: pctRealeRisparmio,
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('SPESO', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                                            Text('${totaleSpesoReale.toInt()}€', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('RIPARTIZIONE REALE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        _buildLegendaItem('Fisse', pctRealeFisse, _percentFisse, const Color(0xFF2DD4BF)),
                                        const SizedBox(height: 4),
                                        _buildLegendaItem('Variabili', pctRealeVariabili, _percentVariabili, const Color(0xFFF59E0B)),
                                        const SizedBox(height: 4),
                                        _buildLegendaItem('Risparmio', pctRealeRisparmio, _percentRisparmio, const Color(0xFF3B82F6)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),
                            const Text('CATEGORIE DI PILOTAGGIO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            const SizedBox(height: 8),

                            // CARDE CATEGORIE
                            _buildBudgetProgressCard(
                              categoriaKey: '50% Spese Fisse',
                              titolo: '${_percentFisse.toInt()}% Spese Fisse',
                              speso: spesoFisse,
                              pianificato: previstoFisse,
                              targetMaxPct: targetMaxFisse,
                              colore: const Color(0xFF2DD4BF),
                              icona: Icons.home_outlined,
                            ),
                            const SizedBox(height: 8),
                            _buildBudgetProgressCard(
                              categoriaKey: '30% Spese Variabili',
                              titolo: '${_percentVariabili.toInt()}% Spese Variabili',
                              speso: spesoVariabili,
                              pianificato: previstoVariabili,
                              targetMaxPct: targetMaxVariabili,
                              colore: const Color(0xFFF59E0B),
                              icona: Icons.shopping_bag_outlined,
                            ),
                            const SizedBox(height: 8),
                            _buildBudgetProgressCard(
                              categoriaKey: '20% Risparmio',
                              titolo: '${_percentRisparmio.toInt()}% Risparmio',
                              speso: spesoRisparmio,
                              pianificato: previstoRisparmio,
                              targetMaxPct: targetMaxRisparmio,
                              colore: const Color(0xFF3B82F6),
                              icona: Icons.savings_outlined,
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // PULSANTE CONFERMA BIANCO PIENO
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: const Text('Salva e Chiudi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _buildLegendaItem(String label, double pctReale, double pctTarget, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const Spacer(),
        Text('${pctReale.toInt()}% ', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        Text('(Target ${pctTarget.toInt()}%)', style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  Widget _buildBudgetProgressCard({
    required String categoriaKey,
    required String titolo,
    required double speso,
    required double pianificato,
    required double targetMaxPct,
    required Color colore,
    required IconData icona,
  }) {
    final double pctProgresso = targetMaxPct > 0 ? (speso / targetMaxPct).clamp(0.0, 1.0) : 0.0;
    final bool isSforatoPct = speso > targetMaxPct;

    return GestureDetector(
      onTap: () {
        _mostraDettaglioCategoria(categoriaKey, colore);
        _scrollToOffset(60);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colore.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icona, color: colore, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titolo, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      const Text('Tocca per dettaglio voci', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Speso: ${speso.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: isSforatoPct ? const Color(0xFFEF4444) : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pianificato: ${pianificato.toStringAsFixed(2)} €',
                      style: const TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pctProgresso,
                minHeight: 5,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(isSforatoPct ? const Color(0xFFEF4444) : colore),
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(pctProgresso * 100).toInt()}% del Tetto Max',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                Text(
                  isSforatoPct
                      ? 'Sforato di +${(speso - targetMaxPct).toStringAsFixed(2)} €'
                      : 'Capienza: ${(targetMaxPct - speso).toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: isSforatoPct ? const Color(0xFFEF4444) : colore,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetDonutPainter extends CustomPainter {
  final double pctFisse;
  final double pctVariabili;
  final double pctRisparmio;

  _BudgetDonutPainter({
    required this.pctFisse,
    required this.pctVariabili,
    required this.pctRisparmio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 6;
    final strokeWidth = 8.0;

    final paintBg = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    final totale = pctFisse + pctVariabili + pctRisparmio;
    if (totale <= 0) return;

    double startAngle = -pi / 2;

    final sweepFisse = (pctFisse / totale) * 2 * pi;
    final paintFisse = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepFisse, false, paintFisse);
    startAngle += sweepFisse;

    final sweepVariabili = (pctVariabili / totale) * 2 * pi;
    final paintVariabili = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepVariabili, false, paintVariabili);
    startAngle += sweepVariabili;

    final sweepRisparmio = (pctRisparmio / totale) * 2 * pi;
    final paintRisparmio = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepRisparmio, false, paintRisparmio);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}