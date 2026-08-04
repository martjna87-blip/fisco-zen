import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 Motore Haptic Feedback
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_notifications.dart';

class PianoSpesaSheet extends StatefulWidget {
  const PianoSpesaSheet({super.key});

  @override
  State<PianoSpesaSheet> createState() => _PianoSpesaSheetState();
}

class _PianoSpesaSheetState extends State<PianoSpesaSheet> {
  final ScrollController _scrollController = ScrollController();

  // NAVIGAZIONE TEMPORALE & FILTRI
  DateTime _meseSelezionato = DateTime(2026, 8);
  String _filtroVisualizzazione = 'tutti'; // 'tutti' | 'da_saldare'

  // REGOLA OBIETTIVO 50/30/20
  double _percentBisogni = 50.0;
  double _percentSvago = 30.0;
  double _percentRisparmio = 20.0;
  double _entrateMensiliRiferimento = 2500.00;

  final List<String> _nomiMesi = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  // 📝 LISTA VOCI DI SPESA
  final List<Map<String, dynamic>> _vociPianificate = [
    {
      'id': '1',
      'nome': 'Affitto / Mutuo',
      'categoria': 'Bisogni (50%)',
      'previsto': 650.00,
      'speso': 650.00,
      'tipo': 'mensile',
      'stato': 'pagato'
    },
    {
      'id': '2',
      'nome': 'Bollette & Utenze',
      'categoria': 'Bisogni (50%)',
      'previsto': 140.00,
      'speso': 0.00,
      'tipo': 'mensile',
      'stato': 'in_attesa'
    },
    {
      'id': '3',
      'nome': 'Spesa Alimentare',
      'categoria': 'Bisogni (50%)',
      'previsto': 350.00,
      'speso': 410.00,
      'tipo': 'variabile',
      'stato': 'in_corso'
    },
    {
      'id': '4',
      'nome': 'Assicurazione Auto',
      'categoria': 'Bisogni (50%)',
      'previsto': 120.00,
      'speso': 120.00,
      'tipo': 'annuale_spalmata',
      'totaleAnnuale': 1440.00,
      'stato': 'accantonato'
    },
    {
      'id': '5',
      'nome': 'Ristoranti & Uscite',
      'categoria': 'Svago (30%)',
      'previsto': 200.00,
      'speso': 160.00,
      'tipo': 'variabile',
      'stato': 'in_corso'
    },
    {
      'id': '6',
      'nome': 'Hobby & Palestra',
      'categoria': 'Svago (30%)',
      'previsto': 80.00,
      'speso': 80.00,
      'tipo': 'mensile',
      'stato': 'pagato'
    },
    {
      'id': '7',
      'nome': 'Abbonamenti Streaming',
      'categoria': 'Svago (30%)',
      'previsto': 30.00,
      'speso': 30.00,
      'tipo': 'mensile',
      'stato': 'pagato'
    },
    {
      'id': '8',
      'nome': 'Fondo Emergenze',
      'categoria': 'Risparmio (20%)',
      'previsto': 300.00,
      'speso': 300.00,
      'tipo': 'mensile',
      'stato': 'accantonato'
    },
    {
      'id': '9',
      'nome': 'Accantonamento Vacanze',
      'categoria': 'Risparmio (20%)',
      'previsto': 200.00,
      'speso': 200.00,
      'tipo': 'mensile',
      'stato': 'accantonato'
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

  // ⚡ TAP DIRTETTO PER CAMBIARE STATO SPESA
  void _toggleStatoSpesa(Map<String, dynamic> voce) {
    HapticFeedback.mediumImpact();
    setState(() {
      final double previsto = (voce['previsto'] as num).toDouble();
      if (voce['stato'] == 'in_attesa') {
        voce['stato'] = 'pagato';
        if ((voce['speso'] as num) == 0) voce['speso'] = previsto;
        AppNotifications.mostraInAlto(context, 'Spesa "${voce['nome']}" saldata! 🎉');
      } else if (voce['stato'] == 'pagato') {
        voce['stato'] = 'in_attesa';
        voce['speso'] = 0.0;
        AppNotifications.mostraInAlto(
          context, 
          'Spesa "${voce['nome']}" riportata in attesa',
          type: NotificationType.warning,
        );
      } else if (voce['stato'] == 'in_corso') {
        voce['stato'] = 'pagato';
        AppNotifications.mostraInAlto(context, 'Spesa "${voce['nome']}" completata! 🎉');
      }
    });
  }

  // 📝 LONG PRESS PER EDITARE O ELIMINARE
  void _gestisciSpesaDialog(Map<String, dynamic> voce) {
    HapticFeedback.heavyImpact();
    final TextEditingController nomeCtrl = TextEditingController(text: voce['nome']);
    final TextEditingController spesoCtrl = TextEditingController(text: (voce['speso'] as num).toStringAsFixed(2));
    final TextEditingController previstoCtrl = TextEditingController(text: (voce['previsto'] as num).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifica "${voce['nome']}"', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
            TextField(
              controller: spesoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Attualmente Speso (€)',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
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
              final nuovoSpeso = double.tryParse(spesoCtrl.text.replaceAll(',', '.')) ?? voce['speso'];

              if (nuovoNome.isNotEmpty) {
                setState(() {
                  voce['nome'] = nuovoNome;
                  voce['previsto'] = nuovoPrevisto;
                  voce['speso'] = nuovoSpeso;
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
                Text('Personalizza Regola 50/30/20', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  Text('📌 Bisogni Fissi: ${tempBisogni.toInt()}% (${(_entrateMensiliRiferimento * tempBisogni / 100).toStringAsFixed(0)} €)',
                      style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 11)),
                  Slider(
                    value: tempBisogni,
                    min: 10, max: 80, divisions: 14,
                    activeColor: const Color(0xFF2DD4BF),
                    onChanged: (val) => setDialogState(() => tempBisogni = val),
                  ),
                  Text('🎉 Svago & Tempo Libero: ${tempSvago.toInt()}% (${(_entrateMensiliRiferimento * tempSvago / 100).toStringAsFixed(0)} €)',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 11)),
                  Slider(
                    value: tempSvago,
                    min: 10, max: 80, divisions: 14,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (val) => setDialogState(() => tempSvago = val),
                  ),
                  Text('🐷 Risparmi & Futuro: ${tempRisparmio.toInt()}% (${(_entrateMensiliRiferimento * tempRisparmio / 100).toStringAsFixed(0)} €)',
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
                child: const Text('Salva Regola', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostraDialogAggiungiSpesa() {
    final TextEditingController nomeCtrl = TextEditingController();
    final TextEditingController importoCtrl = TextEditingController();
    String categoriaSel = 'Bisogni (50%)';
    String tipoSpesaSel = 'mensile';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isAnnuale = tipoSpesaSel == 'annuale';
          final importoInserito = double.tryParse(importoCtrl.text.replaceAll(',', '.')) ?? 0.0;
          final quotaMensileCalcolata = isAnnuale ? importoInserito / 12 : importoInserito;

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
                      labelText: 'Nome della spesa (es. Affitto, Assicurazione)',
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
                          label: const Text('Spesa Mensile', style: TextStyle(fontSize: 10)),
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
                          label: const Text('Spesa Annuale 📅', style: TextStyle(fontSize: 10)),
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
                    onChanged: (_) => setDialogState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: isAnnuale ? 'Importo Totale Annuale (€)' : 'Costo Mensile (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
                    ),
                  ),
                  if (isAnnuale && importoInserito > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF3B82F6), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Impatto reale: accantonerai ${quotaMensileCalcolata.toStringAsFixed(2)} € / mese',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('CATEGORIA BUDGET', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
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

                  if (nome.isNotEmpty && importo > 0) {
                    setState(() {
                      _vociPianificate.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'nome': nome,
                        'categoria': categoriaSel,
                        'previsto': isAnnuale ? importo / 12 : importo,
                        'speso': isAnnuale ? importo / 12 : 0.0,
                        'tipo': isAnnuale ? 'annuale_spalmata' : 'mensile',
                        'stato': isAnnuale ? 'accantonato' : 'in_attesa',
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

  @override
  Widget build(BuildContext context) {
    final stringaMeseCorrente = _stringaMeseAnno(_meseSelezionato);

    final tettoBisogni = _entrateMensiliRiferimento * (_percentBisogni / 100);
    final tettoSvago = _entrateMensiliRiferimento * (_percentSvago / 100);
    final tettoRisparmio = _entrateMensiliRiferimento * (_percentRisparmio / 100);

    double spesoBisogni = 0;
    double spesoSvago = 0;
    double spesoRisparmio = 0;

    for (var v in _vociPianificate) {
      final double importo = (v['speso'] as num).toDouble();
      if (v['categoria'] == 'Bisogni (50%)') spesoBisogni += importo;
      if (v['categoria'] == 'Svago (30%)') spesoSvago += importo;
      if (v['categoria'] == 'Risparmio (20%)') spesoRisparmio += importo;
    }

    final residuoSvago = tettoSvago - spesoSvago;

    return AppPopupWrapper(
      title: 'Piano di Spesa & Obiettivi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 BARRA SUPERIORE CON AZIONI
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
                      child: const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.white70, size: 13),
                          SizedBox(width: 4),
                          Text('50/30/20', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _mostraDialogAggiungiSpesa,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

          // 💡 BANNER CAPIENZA SPENDIBILE SVAGO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  residuoSvago >= 0 ? const Color(0xFFF59E0B).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: residuoSvago >= 0 ? const Color(0xFFF59E0B).withOpacity(0.4) : const Color(0xFFEF4444).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (residuoSvago >= 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    residuoSvago >= 0 ? Icons.celebration_rounded : Icons.warning_amber_rounded,
                    color: residuoSvago >= 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Budget Svago & Tempo Libero',
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        residuoSvago >= 0
                            ? 'Ancora ${residuoSvago.toStringAsFixed(0)} € spendibili'
                            : 'Sforato di ${(-residuoSvago).toStringAsFixed(0)} €!',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Target (${_percentSvago.toInt()}%):', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                    Text('${tettoSvago.toStringAsFixed(0)} €', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔍 FILTRO RAPIDO VISTE ("TUTTI" VS "DA SALDARE")
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

          // 📌 CONTENUTO SCROLLABILE CON MACRO CATEGORIE
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryCard(
                    title: '📌 Bisogni Fissi (${_percentBisogni.toInt()}%)',
                    speso: spesoBisogni,
                    tettoMax: tettoBisogni,
                    color: const Color(0xFF2DD4BF),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').toList(),
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryCard(
                    title: '🎉 Svago & Tempo Libero (${_percentSvago.toInt()}%)',
                    speso: spesoSvago,
                    tettoMax: tettoSvago,
                    color: const Color(0xFFF59E0B),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').toList(),
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryCard(
                    title: '🐷 Risparmi & Futuro (${_percentRisparmio.toInt()}%)',
                    speso: spesoRisparmio,
                    tettoMax: tettoRisparmio,
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

  Widget _buildCategoryCard({
    required String title,
    required double speso,
    required double tettoMax,
    required Color color,
    required List<Map<String, dynamic>> voci,
  }) {
    // Filtro dinamico per la lista
    final vociFiltrate = _filtroVisualizzazione == 'da_saldare'
        ? voci.where((v) => v['stato'] == 'in_attesa').toList()
        : voci;

    if (_filtroVisualizzazione == 'da_saldare' && vociFiltrate.isEmpty) {
      return const SizedBox.shrink();
    }

    final int saldateCount = voci.where((v) => v['stato'] == 'pagato' || v['stato'] == 'accantonato').length;
    final double pctProgresso = tettoMax > 0 ? (speso / tettoMax).clamp(0.0, 1.0) : 0.0;
    final bool isSforato = speso > tettoMax;

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '$saldateCount / ${voci.length} Voci Saldate',
                    style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                '${speso.toStringAsFixed(0)} € / ${tettoMax.toStringAsFixed(0)} €',
                style: TextStyle(
                  color: isSforato ? const Color(0xFFEF4444) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
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
          const SizedBox(height: 10),
          Column(
            children: vociFiltrate.map((v) => _buildVoceTile(v)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoceTile(Map<String, dynamic> v) {
    final double previsto = (v['previsto'] as num).toDouble();
    final double speso = (v['speso'] as num).toDouble();
    final String tipo = v['tipo'] ?? 'mensile';
    final String stato = v['stato'] ?? 'in_corso';
    final double rimasto = previsto - speso;
    final bool sforato = rimasto < 0;

    Widget badgeStato;
    String testoDestra;
    Color coloreDestra = Colors.white;

    if (tipo == 'annuale_spalmata') {
      final double totaleAnnuale = (v['totaleAnnuale'] as num?)?.toDouble() ?? (previsto * 12);
      badgeStato = _buildBadgeTag('Accantonata (${totaleAnnuale.toInt()}€/anno)', const Color(0xFF3B82F6));
      testoDestra = '${speso.toStringAsFixed(0)} € / mese';
      coloreDestra = const Color(0xFF3B82F6);
    } else if (stato == 'pagato') {
      badgeStato = _buildBadgeTag('✓ Saldata', const Color(0xFF10B981));
      testoDestra = '${speso.toStringAsFixed(0)} €';
      coloreDestra = const Color(0xFF10B981);
    } else if (stato == 'in_attesa') {
      badgeStato = _buildBadgeTag('⏳ In Attesa (Tap per Saldare)', const Color(0xFFF59E0B));
      testoDestra = '0 € / ${previsto.toStringAsFixed(0)} €';
      coloreDestra = const Color(0xFFF59E0B);
    } else {
      badgeStato = _buildBadgeTag(
        sforato ? '⚠️ Sforato di ${(-rimasto).toInt()}€' : 'Restano ${rimasto.toInt()}€',
        sforato ? const Color(0xFFEF4444) : const Color(0xFF2DD4BF),
      );
      testoDestra = '${speso.toStringAsFixed(0)} € di ${previsto.toStringAsFixed(0)} €';
      coloreDestra = sforato ? const Color(0xFFEF4444) : Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleStatoSpesa(v),
        onLongPress: () => _gestisciSpesaDialog(v),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sforato 
                  ? const Color(0xFFEF4444).withOpacity(0.5) 
                  : (stato == 'in_attesa' ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
              width: sforato ? 1.2 : 1,
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
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
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