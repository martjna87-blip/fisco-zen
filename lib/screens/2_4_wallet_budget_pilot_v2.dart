import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_notifications.dart';

class PianoSpesaSheet extends StatefulWidget {
  const PianoSpesaSheet({super.key});

  @override
  State<PianoSpesaSheet> createState() => _PianoSpesaSheetState();
}

class _PianoSpesaSheetState extends State<PianoSpesaSheet> {
  final ScrollController _scrollController = ScrollController();

  DateTime _meseSelezionato = DateTime(2026, 8);
  String _filtroVisualizzazione = 'tutti';

  // 🎯 STATO ACCORDION: di default lasciamo aperte Bisogni e Svago
  final Set<String> _categorieEspanse = {'Bisogni (50%)', 'Svago (30%)'};

  // REGOLA DI RIFERIMENTO (TARGET IDEALE)
  double _percentBisogni = 50.0;
  double _percentSvago = 30.0;
  double _percentRisparmio = 20.0;
  double _entrateMensiliRiferimento = 2500.00;

  final List<String> _nomiMesi = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  final List<String> _sottocategorieDisponibili = [
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

  final List<Map<String, dynamic>> _vociPianificate = [
    {
      'id': '1',
      'nome': 'Affitto / Mutuo',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Casa/Affitto',
      'previsto': 650.00,
      'tipo': 'mensile',
    },
    {
      'id': '2',
      'nome': 'Bollette & Utenze',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Canoni/Bollette',
      'previsto': 140.00,
      'tipo': 'mensile',
    },
    {
      'id': '3',
      'nome': 'Spesa Alimentare',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Alimentari',
      'previsto': 350.00,
      'tipo': 'variabile',
    },
    {
      'id': '4',
      'nome': 'Assicurazione Auto',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Auto',
      'previsto': 120.00,
      'tipo': 'annuale_spalmata',
      'totaleAnnuale': 1440.00,
    },
    {
      'id': '5',
      'nome': 'Ristoranti & Uscite',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Divertimento',
      'previsto': 200.00,
      'tipo': 'variabile',
    },
    {
      'id': '6',
      'nome': 'Hobby & Palestra',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Divertimento',
      'previsto': 80.00,
      'tipo': 'mensile',
    },
    {
      'id': '7',
      'nome': 'Abbonamenti Streaming',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Canoni/Bollette',
      'previsto': 30.00,
      'tipo': 'mensile',
    },
    {
      'id': '8',
      'nome': 'Fondo Emergenze',
      'categoria': 'Risparmio (20%)',
      'sottocategoria': 'Altro',
      'previsto': 300.00,
      'tipo': 'mensile',
    },
    {
      'id': '9',
      'nome': 'Accantonamento Vacanze',
      'categoria': 'Risparmio (20%)',
      'sottocategoria': 'Viaggi',
      'previsto': 200.00,
      'tipo': 'mensile',
    },
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
    HapticFeedback.lightImpact();
    setState(() {
      _meseSelezionato = DateTime(_meseSelezionato.year, _meseSelezionato.month + delta);
    });
  }

  double _calcolaSpesoReale(WalletProvider provider, String nomeVoce, String sottoCat) {
    return provider.transactions.where((tx) {
      final isSameMonth = tx.date.year == _meseSelezionato.year && tx.date.month == _meseSelezionato.month;
      if (!isSameMonth || tx.isIncome) return false;

      final matchCat = tx.category.toLowerCase() == sottoCat.toLowerCase();
      final matchTitle = tx.title.toLowerCase().contains(nomeVoce.toLowerCase()) || 
                         nomeVoce.toLowerCase().contains(tx.title.toLowerCase());

      return matchCat || matchTitle;
    }).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  void _gestisciSpesaDialog(Map<String, dynamic> voce) {
    HapticFeedback.heavyImpact();
    final TextEditingController nomeCtrl = TextEditingController(text: voce['nome']);
    final TextEditingController previstoCtrl = TextEditingController(text: (voce['previsto'] as num).toStringAsFixed(2));
    String sottoCatSel = voce['sottocategoria'] ?? 'Alimentari';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C21),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Modifica "${voce['nome']}"', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nomeCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Nome Spesa',
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: previstoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Budget Previsto (€)',
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              const Text('SOTTOCATEGORIA ASSOCIATA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _sottocategorieDisponibili.contains(sottoCatSel) ? sottoCatSel : _sottocategorieDisponibili.first,
                dropdownColor: const Color(0xFF1C1C21),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _sottocategorieDisponibili.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => sottoCatSel = val!),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              onPressed: () {
                setState(() {
                  _vociPianificate.removeWhere((item) => item['id'] == voce['id']);
                });
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(context, 'Voce rimossa dal piano', type: NotificationType.warning);
              },
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final nuovoNome = nomeCtrl.text.trim();
                final nuovoPrevisto = double.tryParse(previstoCtrl.text.replaceAll(',', '.')) ?? voce['previsto'];

                if (nuovoNome.isNotEmpty) {
                  setState(() {
                    voce['nome'] = nuovoNome;
                    voce['previsto'] = nuovoPrevisto;
                    voce['sottocategoria'] = sottoCatSel;
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostraDialogAggiungiSpesa() {
    final TextEditingController nomeCtrl = TextEditingController();
    final TextEditingController importoCtrl = TextEditingController();
    final TextEditingController nuovaSottoCatCtrl = TextEditingController();

    String categoriaSel = 'Bisogni (50%)';
    String sottoCatSel = _sottocategorieDisponibili.first;
    String tipoSpesaSel = 'mensile';
    bool creaNuovaSottoCat = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isAnnuale = tipoSpesaSel == 'annuale';

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Pianifica Spesa', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Nome della spesa (es. Palestra, Conad)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Mensile', style: TextStyle(fontSize: 10)),
                          selected: tipoSpesaSel == 'mensile',
                          selectedColor: const Color(0xFF2DD4BF),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          labelStyle: TextStyle(color: tipoSpesaSel == 'mensile' ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
                          onSelected: (s) => setDialogState(() => tipoSpesaSel = 'mensile'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Annuale 📅', style: TextStyle(fontSize: 10)),
                          selected: tipoSpesaSel == 'annuale',
                          selectedColor: const Color(0xFF3B82F6),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          labelStyle: TextStyle(color: tipoSpesaSel == 'annuale' ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                          onSelected: (s) => setDialogState(() => tipoSpesaSel = 'annuale'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: importoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: isAnnuale ? 'Importo Annuale (€)' : 'Costo Mensile (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('CATEGORIA BUDGET', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: categoriaSel,
                    dropdownColor: const Color(0xFF1C1C21),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Bisogni (50%)', child: Text('📌 Bisogni Fissi (50%)')),
                      DropdownMenuItem(value: 'Svago (30%)', child: Text('🎉 Svago & Vita (30%)')),
                      DropdownMenuItem(value: 'Risparmio (20%)', child: Text('🐷 Risparmi & Futuro (20%)')),
                    ],
                    onChanged: (val) => setDialogState(() => categoriaSel = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SOTTOCATEGORIA MATCHING', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => setDialogState(() => creaNuovaSottoCat = !creaNuovaSottoCat),
                        child: Text(
                          creaNuovaSottoCat ? 'Scegli da lista' : '+ Nuova',
                          style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (creaNuovaSottoCat)
                    TextField(
                      controller: nuovaSottoCatCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Inserisci nuova categoria (es. Animali)',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: sottoCatSel,
                      dropdownColor: const Color(0xFF1C1C21),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _sottocategorieDisponibili.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setDialogState(() => sottoCatSel = val!),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  final nome = nomeCtrl.text.trim();
                  final importo = double.tryParse(importoCtrl.text.replaceAll(',', '.')) ?? 0.0;
                  final nomeSottoCatFinale = creaNuovaSottoCat && nuovaSottoCatCtrl.text.trim().isNotEmpty
                      ? nuovaSottoCatCtrl.text.trim()
                      : sottoCatSel;

                  if (creaNuovaSottoCat && nuovaSottoCatCtrl.text.trim().isNotEmpty) {
                    if (!_sottocategorieDisponibili.contains(nomeSottoCatFinale)) {
                      _sottocategorieDisponibili.add(nomeSottoCatFinale);
                    }
                  }

                  if (nome.isNotEmpty && importo > 0) {
                    setState(() {
                      _vociPianificate.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'nome': nome,
                        'categoria': categoriaSel,
                        'sottocategoria': nomeSottoCatFinale,
                        'previsto': isAnnuale ? importo / 12 : importo,
                        'tipo': isAnnuale ? 'annuale_spalmata' : 'mensile',
                        if (isAnnuale) 'totaleAnnuale': importo,
                      });
                    });
                    Navigator.pop(ctx);
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

  void _mostraDialogModificaRegola() {
    double tempBisogni = _percentBisogni;
    double tempSvago = _percentSvago;
    double tempRisparmio = _percentRisparmio;
    final TextEditingController entrateCtrl = TextEditingController(text: _entrateMensiliRiferimento.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totale = tempBisogni + tempSvago + tempRisparmio;
          final bool isValid = (totale == 100.0);

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF2DD4BF), size: 20),
                SizedBox(width: 8),
                Text('Personalizza Target IDEALE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: entrateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Entrate Mensili di Riferimento (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF2DD4BF), size: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('📌 Target Bisogni Fissi: ${tempBisogni.toInt()}%',
                      style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 11)),
                  Slider(
                    value: tempBisogni,
                    min: 10, max: 80, divisions: 14,
                    activeColor: const Color(0xFF2DD4BF),
                    onChanged: (val) => setDialogState(() => tempBisogni = val),
                  ),
                  Text('🎉 Target Svago: ${tempSvago.toInt()}%',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 11)),
                  Slider(
                    value: tempSvago,
                    min: 10, max: 80, divisions: 14,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (val) => setDialogState(() => tempSvago = val),
                  ),
                  Text('🐷 Target Risparmi: ${tempRisparmio.toInt()}%',
                      style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11)),
                  Slider(
                    value: tempRisparmio,
                    min: 0, max: 50, divisions: 10,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (val) => setDialogState(() => tempRisparmio = val),
                  ),
                  const Divider(color: Colors.white12),
                  Center(
                    child: Text(
                      'Totale Ripartizione: ${totale.toInt()}%',
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isValid
                    ? () {
                        setState(() {
                          _percentBisogni = tempBisogni;
                          _percentSvago = tempSvago;
                          _percentRisparmio = tempRisparmio;
                          _entrateMensiliRiferimento = double.tryParse(entrateCtrl.text) ?? _entrateMensiliRiferimento;
                        });
                        Navigator.pop(ctx);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salva Target', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final stringaMeseCorrente = _stringaMeseAnno(_meseSelezionato);

    // CALCOLI DI PIANIFICAZIONE (CHE INCIDENZA HANNO LE VOCI PIANIFICATE SULLE ENTRATE?)
    double pianificatoBisogni = _vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').fold(0.0, (sum, v) => sum + (v['previsto'] as num));
    double pianificatoSvago = _vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').fold(0.0, (sum, v) => sum + (v['previsto'] as num));
    double pianificatoRisparmio = _vociPianificate.where((v) => v['categoria'] == 'Risparmio (20%)').fold(0.0, (sum, v) => sum + (v['previsto'] as num));

    double totalePianificatoSpese = pianificatoBisogni + pianificatoSvago;
    double percentualePianoRisparmio = (_entrateMensiliRiferimento > 0)
        ? ((_entrateMensiliRiferimento - totalePianificatoSpese) / _entrateMensiliRiferimento * 100)
        : 0.0;

    // CALCOLI SPESO REALE
    double spesoBisogni = 0;
    double spesoSvago = 0;
    double spesoRisparmio = 0;

    for (var v in _vociPianificate) {
      final double spesoReale = _calcolaSpesoReale(walletProvider, v['nome'], v['sottocategoria'] ?? '');
      if (v['categoria'] == 'Bisogni (50%)') spesoBisogni += spesoReale;
      if (v['categoria'] == 'Svago (30%)') spesoSvago += spesoReale;
      if (v['categoria'] == 'Risparmio (20%)') spesoRisparmio += spesoReale;
    }

    return AppPopupWrapper(
      title: 'Pilotaggio Budget & Previsioni',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER SELETTORE MESE & NUOVA SPESA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _cambiaMese(-1),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stringaMeseCorrente.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _cambiaMese(1),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _mostraDialogModificaRegola,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          Text('Target ${_percentBisogni.toInt()}/${_percentSvago.toInt()}/${_percentRisparmio.toInt()}', 
                               style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _mostraDialogAggiungiSpesa,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF2DD4BF), size: 14),
                          SizedBox(width: 3),
                          Text('+ Spesa', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. 🛡️ BANNER COACH FINANZIARIO (AVVISO SOSTENIBILITÀ DEL PIANO)
          _buildCoachFinanziarioBanner(percentualePianoRisparmio),

          const SizedBox(height: 10),

          // 3. FILTRO VISTE
          Row(
            children: [
              FilterChip(
                selected: _filtroVisualizzazione == 'tutti',
                label: const Text('Tutte le Voci', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: const Color(0xFF2DD4BF).withOpacity(0.25),
                side: BorderSide(color: _filtroVisualizzazione == 'tutti' ? const Color(0xFF2DD4BF) : Colors.white12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (_) => setState(() => _filtroVisualizzazione = 'tutti'),
              ),
              const SizedBox(width: 6),
              FilterChip(
                selected: _filtroVisualizzazione == 'da_saldare',
                avatar: const Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFF59E0B)),
                label: const Text('Solo Da Saldare ⏳', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: const Color(0xFFF59E0B).withOpacity(0.25),
                side: BorderSide(color: _filtroVisualizzazione == 'da_saldare' ? const Color(0xFFF59E0B) : Colors.white12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (_) => setState(() => _filtroVisualizzazione = 'da_saldare'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4. ELENCO ACCORDION CON LE % DI PIANO VS % TARGET
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExpandableCategoryCard(
                    provider: walletProvider,
                    categoriaKey: 'Bisogni (50%)',
                    title: '📌 Bisogni Fissi',
                    targetPct: _percentBisogni,
                    pianificatoTotale: pianificatoBisogni,
                    spesoRealeTotale: spesoBisogni,
                    color: const Color(0xFF2DD4BF),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildExpandableCategoryCard(
                    provider: walletProvider,
                    categoriaKey: 'Svago (30%)',
                    title: '🎉 Svago & Tempo Libero',
                    targetPct: _percentSvago,
                    pianificatoTotale: pianificatoSvago,
                    spesoRealeTotale: spesoSvago,
                    color: const Color(0xFFF59E0B),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildExpandableCategoryCard(
                    provider: walletProvider,
                    categoriaKey: 'Risparmio (20%)',
                    title: '✈️ Risparmi & Futuro',
                    targetPct: _percentRisparmio,
                    pianificatoTotale: pianificatoRisparmio,
                    spesoRealeTotale: spesoRisparmio,
                    color: const Color(0xFF3B82F6),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Risparmio (20%)').toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🚨 BANNER DI ALLERTA INTELLIGENTE SULLA TENUTA DEL PIANO
  Widget _buildCoachFinanziarioBanner(double percentualeRisparmioStimata) {
    final bool aRischio = percentualeRisparmioStimata < _percentRisparmio;
    final Color coloreBanner = aRischio ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: coloreBanner.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: coloreBanner.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            aRischio ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
            color: coloreBanner,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aRischio ? 'ATTENZIONE: PIANO SQUILIBRATO' : 'PIANO SOSTENIBILE AL 100%',
                  style: TextStyle(color: coloreBanner, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  aRischio
                      ? 'Le spese pianificate assorbono troppo: riuscirai a mettere da parte solo il ${percentualeRisparmioStimata.toStringAsFixed(0)}% (Target: ${_percentRisparmio.toInt()}%).'
                      : 'Le spese pianificate rispettano le entrate. Ti garantisci il ${percentualeRisparmioStimata.toStringAsFixed(0)}% di risparmi!',
                  style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🧩 ACCORDION CON % DI PIANO BEN CHIARA E PROGRESO REALE SU PIANIFICATO
  Widget _buildExpandableCategoryCard({
    required WalletProvider provider,
    required String categoriaKey,
    required String title,
    required double targetPct,
    required double pianificatoTotale,
    required double spesoRealeTotale,
    required Color color,
    required List<Map<String, dynamic>> voci,
  }) {
    final bool isEspansa = _categorieEspanse.contains(categoriaKey);
    final double pctProgresso = pianificatoTotale > 0 ? (spesoRealeTotale / pianificatoTotale).clamp(0.0, 1.0) : 0.0;
    final bool isSforato = spesoRealeTotale > pianificatoTotale && pianificatoTotale > 0;

    // Quanto pesa questo PIANO sulle entrate?
    final double pctPianoSuEntrate = (_entrateMensiliRiferimento > 0)
        ? (pianificatoTotale / _entrateMensiliRiferimento * 100)
        : 0.0;

    int saldateCount = 0;
    for (var v in voci) {
      final double spesoReale = _calcolaSpesoReale(provider, v['nome'], v['sottocategoria'] ?? '');
      final double previsto = (v['previsto'] as num).toDouble();
      if (spesoReale >= previsto && previsto > 0) saldateCount++;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isEspansa) {
                  _categorieEspanse.remove(categoriaKey);
                } else {
                  _categorieEspanse.add(categoriaKey);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEspansa ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Target ${targetPct.toInt()}%',
                                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pianificato: ${pctPianoSuEntrate.toStringAsFixed(0)}% delle entrate (${pianificatoTotale.toStringAsFixed(0)} €) • $saldateCount/${voci.length} Saldate',
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${spesoRealeTotale.toStringAsFixed(0)} € / ${pianificatoTotale.toStringAsFixed(0)} €',
                            style: TextStyle(
                              color: isSforato ? const Color(0xFFEF4444) : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Reale vs Piano',
                            style: TextStyle(color: isSforato ? const Color(0xFFEF4444) : Colors.white38, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pctProgresso,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(isSforato ? const Color(0xFFEF4444) : color),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isEspansa) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: voci.map((v) => _buildVoceTile(provider, v)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🧩 RIGA DEL SINGOLO MOVIMENTO CON SFORAMENTO ESPLICITO E CIFRA COMPARATA (es. 700€ / 650€)
  Widget _buildVoceTile(WalletProvider provider, Map<String, dynamic> v) {
    final double previsto = (v['previsto'] as num).toDouble();
    final double spesoReale = _calcolaSpesoReale(provider, v['nome'], v['sottocategoria'] ?? '');
    final String tipo = v['tipo'] ?? 'mensile';
    
    final double differenza = spesoReale - previsto;
    final bool isSforato = differenza > 0.01 && previsto > 0;
    final bool isSaldataEsatta = (differenza.abs() <= 0.01) && previsto > 0;
    final bool isSaldata = spesoReale >= previsto && previsto > 0;

    if (_filtroVisualizzazione == 'da_saldare' && isSaldata) {
      return const SizedBox.shrink();
    }

    Widget badgeStato;
    String testoDestra = '${spesoReale.toStringAsFixed(0)} € / ${previsto.toStringAsFixed(0)} €';
    Color coloreDestra = Colors.white;

    if (tipo == 'annuale_spalmata') {
      final double totaleAnnuale = (v['totaleAnnuale'] as num?)?.toDouble() ?? (previsto * 12);
      badgeStato = _buildBadgeTag('Accantonata (${totaleAnnuale.toInt()}€/anno)', const Color(0xFF3B82F6));
      coloreDestra = const Color(0xFF3B82F6);
    } else if (isSforato) {
      // 🚨 SFORAMENTO: Non nascondiamo nulla, diciamo di quanto ha superato
      badgeStato = _buildBadgeTag('⚠️ Sforato di +${differenza.toStringAsFixed(0)} €', const Color(0xFFEF4444));
      coloreDestra = const Color(0xFFEF4444);
    } else if (isSaldataEsatta) {
      badgeStato = _buildBadgeTag('✓ Saldata', const Color(0xFF10B981));
      coloreDestra = const Color(0xFF10B981);
    } else if (spesoReale == 0) {
      badgeStato = _buildBadgeTag('⏳ In Attesa', const Color(0xFFF59E0B));
      coloreDestra = const Color(0xFFF59E0B);
    } else {
      final double rimasto = previsto - spesoReale;
      badgeStato = _buildBadgeTag('Restano ${rimasto.toStringAsFixed(0)} €', const Color(0xFF2DD4BF));
      coloreDestra = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _gestisciSpesaDialog(v),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSforato 
                  ? const Color(0xFFEF4444).withOpacity(0.5) 
                  : (spesoReale == 0 ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
              width: isSforato ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['nome'],
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    badgeStato,
                  ],
                ),
              ),
              Text(
                testoDestra,
                style: TextStyle(color: coloreDestra, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}