import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets_shared/app_popup_wrapper.dart';

class PianoSpesaSheet extends StatefulWidget {
  const PianoSpesaSheet({super.key});

  @override
  State<PianoSpesaSheet> createState() => _PianoSpesaSheetState();
}

class _PianoSpesaSheetState extends State<PianoSpesaSheet> {
  final ScrollController _scrollController = ScrollController();

  // NAVIGAZIONE TEMPORALE
  DateTime _meseSelezionato = DateTime(2026, 8); // Agosto 2026

  // REGOLA OBIETTIVO 50/30/20
  double _percentBisogni = 50.0;
  double _percentSvago = 30.0;
  double _percentRisparmio = 20.0;
  double _entrateMensiliRiferimento = 2500.00;

  final List<String> _nomiMesi = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  // 📝 LISTA VOCI DI SPESA & PIANIFICAZIONE
  final List<Map<String, dynamic>> _vociPianificate = [
    // 📌 BISOGNI FISSI (50%)
    {'nome': 'Affitto / Mutuo', 'categoria': 'Bisogni (50%)', 'previsto': 650.00, 'speso': 650.00, 'tipo': 'mensile'},
    {'nome': 'Bollette & Utenze', 'categoria': 'Bisogni (50%)', 'previsto': 140.00, 'speso': 110.00, 'tipo': 'mensile'},
    {'nome': 'Spesa Alimentare', 'categoria': 'Bisogni (50%)', 'previsto': 350.00, 'speso': 280.00, 'tipo': 'mensile'},
    
    // 📅 SPESE ANNALI SPALMATE (Il visualizzatore di sicurezza)
    {'nome': 'Assicurazione Auto', 'categoria': 'Bisogni (50%)', 'previsto': 120.00, 'speso': 120.00, 'tipo': 'annuale_spalmata', 'totaleAnnuale': 1440.00, 'scadenza': 'Novembre'},
    {'nome': 'Bollo Auto & Tagliando', 'categoria': 'Bisogni (50%)', 'previsto': 40.00, 'speso': 40.00, 'tipo': 'annuale_spalmata', 'totaleAnnuale': 480.00, 'scadenza': 'Maggio'},

    // 🎉 SVAGO & VITA (30%)
    {'nome': 'Ristoranti & Uscite', 'categoria': 'Svago (30%)', 'previsto': 200.00, 'speso': 160.00, 'tipo': 'mensile'},
    {'nome': 'Hobby & Palestra', 'categoria': 'Svago (30%)', 'previsto': 80.00, 'speso': 80.00, 'tipo': 'mensile'},
    {'nome': 'Abbonamenti Streaming', 'categoria': 'Svago (30%)', 'previsto': 30.00, 'speso': 30.00, 'tipo': 'mensile'},

    // 🐷 RISPARMI & FUTURO (20%)
    {'nome': 'Fondo Emergenze', 'categoria': 'Risparmio (20%)', 'previsto': 300.00, 'speso': 300.00, 'tipo': 'mensile'},
    {'nome': 'Accantonamento Vacanze', 'categoria': 'Risparmio (20%)', 'previsto': 200.00, 'speso': 200.00, 'tipo': 'mensile'},
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

  // 🎛️ DIALOG MODIFICA OBIETTIVI (50/30/20)
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

  // ➕ DIALOG NUOVA SPESA (CON OPZIONE SPESA ANNUALE SPALMATA)
  void _mostraDialogAggiungiSpesa() {
    final TextEditingController nomeCtrl = TextEditingController();
    final TextEditingController importoCtrl = TextEditingController();
    String categoriaSel = 'Bisogni (50%)';
    String tipoSpesaSel = 'mensile'; // 'mensile' oppure 'annuale'

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
                        'nome': nome,
                        'categoria': categoriaSel,
                        'previsto': isAnnuale ? importo / 12 : importo,
                        'speso': isAnnuale ? importo / 12 : importo,
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

  @override
  Widget build(BuildContext context) {
    final stringaMeseCorrente = _stringaMeseAnno(_meseSelezionato);

    // CALCOLI DI BUDGET
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
              // 📅 SELETTORE MESE ELEGANTE
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

          const SizedBox(height: 12),

          // 💡 BANNER ANSIA-FREE: CAPIENZA SPENDIBILE SVAGO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  residuoSvago >= 0 ? const Color(0xFFF59E0B).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: residuoSvago >= 0 ? const Color(0xFFF59E0B).withOpacity(0.4) : const Color(0xFFEF4444).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (residuoSvago >= 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    residuoSvago >= 0 ? Icons.celebration_rounded : Icons.warning_amber_rounded,
                    color: residuoSvago >= 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Budget Svago & Tempo Libero',
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        residuoSvago >= 0
                            ? 'Ancora ${residuoSvago.toStringAsFixed(0)} € spendibili'
                            : 'Sforato di ${(-residuoSvago).toStringAsFixed(0)} €!',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

          const SizedBox(height: 14),

          // 📌 CONTENUTO SCROLLABILE
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LE 3 MACRO CATEGORIE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),

                  // 1. BISOGNI FISSI (50%)
                  _buildCategoryCard(
                    title: '📌 Bisogni Fissi (${_percentBisogni.toInt()}%)',
                    speso: spesoBisogni,
                    tettoMax: tettoBisogni,
                    color: const Color(0xFF2DD4BF),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').toList(),
                  ),
                  const SizedBox(height: 10),

                  // 2. SVAGO & VITA (30%)
                  _buildCategoryCard(
                    title: '🎉 Svago & Tempo Libero (${_percentSvago.toInt()}%)',
                    speso: spesoSvago,
                    tettoMax: tettoSvago,
                    color: const Color(0xFFF59E0B),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').toList(),
                  ),
                  const SizedBox(height: 10),

                  // 3. RISPARMI & FUTURO (20%)
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
    final double pctProgresso = tettoMax > 0 ? (speso / tettoMax).clamp(0.0, 1.0) : 0.0;
    final bool isSforato = speso > tettoMax;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(isSforato ? const Color(0xFFEF4444) : color),
            ),
          ),

          const SizedBox(height: 12),

          // ELENCO VOCI INCLUSE NELLA CATEGORIA
          Column(
            children: voci.map((v) {
              final isAnnuale = v['tipo'] == 'annuale_spalmata';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAnnuale ? Icons.calendar_month_rounded : Icons.fiber_manual_record_rounded,
                          color: isAnnuale ? const Color(0xFF3B82F6) : Colors.white38,
                          size: isAnnuale ? 13 : 8,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          v['nome'],
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        if (isAnnuale) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Spalmata (${(v['totaleAnnuale'] as double).toInt()}€/anno)',
                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${(v['speso'] as double).toStringAsFixed(2)} €/mese',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}