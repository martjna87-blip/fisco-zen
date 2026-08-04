import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_secondary_popup.dart';

class PianoSpesaSheet extends StatefulWidget {
  const PianoSpesaSheet({super.key});

  @override
  State<PianoSpesaSheet> createState() => _PianoSpesaSheetState();
}

class _PianoSpesaSheetState extends State<PianoSpesaSheet> {
  final ScrollController _scrollController = ScrollController();

  DateTime _meseSelezionato = DateTime(2026, 8);
  String _filtroVisualizzazione = 'tutti';

  final Set<String> _categorieEspanse = {'Bisogni (50%)', 'Svago (30%)'};

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

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.edit_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Modifica Spesa',
      testoConferma: 'Salva',
      onConferma: () {
        final nuovoNome = nomeCtrl.text.trim();
        final nuovoPrevisto = double.tryParse(previstoCtrl.text.replaceAll(',', '.')) ?? voce['previsto'];

        if (nuovoNome.isNotEmpty) {
          setState(() {
            voce['nome'] = nuovoNome;
            voce['previsto'] = nuovoPrevisto;
            voce['sottocategoria'] = sottoCatSel;
          });
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nomeCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Nome Spesa',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: previstoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Budget Previsto (€)',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          const Text('CATEGORIA', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _sottocategorieDisponibili.contains(sottoCatSel) ? sottoCatSel : _sottocategorieDisponibili.first,
            dropdownColor: const Color(0xFF1C1C21),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: _sottocategorieDisponibili.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => sottoCatSel = val!),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _vociPianificate.removeWhere((item) => item['id'] == voce['id']);
              });
              Navigator.pop(context);
              AppNotifications.mostraInAlto(context, 'Voce rimossa dal piano', type: NotificationType.warning);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
            label: const Text('Elimina questa spesa', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostraDialogAggiungiSpesa() {
    final TextEditingController nomeCtrl = TextEditingController();
    final TextEditingController importoCtrl = TextEditingController();

    String categoriaSel = 'Bisogni (50%)';
    String sottoCatSel = _sottocategorieDisponibili.first;
    String tipoSpesaSel = 'mensile';
    String meseScadenzaSel = _nomiMesi[_meseSelezionato.month - 1]; // Mese corrente come default

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.add_circle_outline_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Nuova Spesa Pianificata',
      testoConferma: 'Aggiungi',
      onConferma: () {
        final nome = nomeCtrl.text.trim();
        final importo = double.tryParse(importoCtrl.text.replaceAll(',', '.')) ?? 0.0;

        if (nome.isNotEmpty && importo > 0) {
          setState(() {
            _vociPianificate.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'nome': nome,
              'categoria': categoriaSel,
              'sottocategoria': sottoCatSel,
              'previsto': tipoSpesaSel == 'annuale' ? importo / 12 : importo,
              'tipo': tipoSpesaSel == 'annuale' ? 'annuale_spalmata' : 'mensile',
              if (tipoSpesaSel == 'annuale') 'totaleAnnuale': importo,
              if (tipoSpesaSel == 'annuale') 'meseScadenza': meseScadenzaSel,
            });
          });
          Navigator.pop(context);
          AppNotifications.mostraInAlto(context, 'Spesa "$nome" aggiunta al piano! 🎉');
        } else {
          AppNotifications.mostraInAlto(
            context,
            'Inserisci un nome e un importo valido',
            type: NotificationType.warning,
          );
        }
      },
      // 🚀 STATEFUL BUILDER FONDAMENTALE PER FAR CAMBIARE IL DIALOGO IN TEMPO REALE
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final bool isAnnuale = tipoSpesaSel == 'annuale';
          final double importoInserito = double.tryParse(importoCtrl.text.replaceAll(',', '.')) ?? 0.0;
          final double quotaMensile = isAnnuale ? (importoInserito / 12) : importoInserito;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Nome spesa (es. Affitto, Assicurazione Auto)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Spesa Mensile', style: TextStyle(fontSize: 12)),
                        selected: !isAnnuale,
                        selectedColor: const Color(0xFF2DD4BF),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(color: !isAnnuale ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
                        onSelected: (_) => setDialogState(() => tipoSpesaSel = 'mensile'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Annuale 📅', style: TextStyle(fontSize: 12)),
                        selected: isAnnuale,
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(color: isAnnuale ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                        onSelected: (_) => setDialogState(() => tipoSpesaSel = 'annuale'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: importoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setDialogState(() {}), // Ricalcola in tempo reale la quota mensile
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: isAnnuale ? 'Importo Totale Annuale (€)' : 'Costo Mensile (€)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
                  ),
                ),

                // 📌 SE È ANNUALE: MOSTRIAMO SELETTORE DEL MESE E CALCOLO QUOTA
                if (isAnnuale) ...[
                  const SizedBox(height: 14),
                  const Text('MESE DI SCADENZA (Quando dovrai pagare?)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: meseScadenzaSel,
                    dropdownColor: const Color(0xFF1C1C21),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF3B82F6), size: 18),
                    ),
                    items: _nomiMesi.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setDialogState(() => meseScadenzaSel = val!),
                  ),
                  if (importoInserito > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '💡 Impegno reale: accantonerai ${quotaMensile.toStringAsFixed(2)} € / mese per arrivare pronto a $meseScadenzaSel.',
                              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 14),
                const Text('MACRO CATEGORIA BUDGET', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: categoriaSel,
                  dropdownColor: const Color(0xFF1C1C21),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Bisogni (50%)', child: Text('📌 Bisogni Fissi (50%)')),
                    DropdownMenuItem(value: 'Svago (30%)', child: Text('🎉 Svago & Tempo Libero (30%)')),
                    DropdownMenuItem(value: 'Risparmio (20%)', child: Text('🐷 Risparmi & Futuro (20%)')),
                  ],
                  onChanged: (val) => setDialogState(() => categoriaSel = val!),
                ),
              ],
            ),
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

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Regola 50 / 30 / 20',
      testoConferma: 'Salva',
      onConferma: () {
        final int totale = (tempBisogni + tempSvago + tempRisparmio).round();
        if (totale == 100) {
          setState(() {
            _percentBisogni = tempBisogni;
            _percentSvago = tempSvago;
            _percentRisparmio = tempRisparmio;
            _entrateMensiliRiferimento = double.tryParse(entrateCtrl.text) ?? _entrateMensiliRiferimento;
          });
          Navigator.pop(context);
        } else {
          AppNotifications.mostraInAlto(
            context,
            'La somma delle percentuali deve fare 100%! (Attuale: $totale%)',
            type: NotificationType.warning,
          );
        }
      },
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final int totaleCorrente = (tempBisogni + tempSvago + tempRisparmio).round();
          final bool eValido = totaleCorrente == 100;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: entrateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Entrate Mensili Nette (€)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF2DD4BF), size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                Text('📌 Bisogni: ${tempBisogni.toInt()}%', style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: tempBisogni,
                  min: 10, max: 80, divisions: 14,
                  activeColor: const Color(0xFF2DD4BF),
                  onChanged: (val) => setDialogState(() => tempBisogni = val),
                ),
                Text('🎉 Svago: ${tempSvago.toInt()}%', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: tempSvago,
                  min: 10, max: 80, divisions: 14,
                  activeColor: const Color(0xFFF59E0B),
                  onChanged: (val) => setDialogState(() => tempSvago = val),
                ),
                Text('🐷 Risparmi: ${tempRisparmio.toInt()}%', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: tempRisparmio,
                  min: 0, max: 50, divisions: 10,
                  activeColor: const Color(0xFF3B82F6),
                  onChanged: (val) => setDialogState(() => tempRisparmio = val),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Totale Ripartizione: $totaleCorrente%',
                    style: TextStyle(
                      color: eValido ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final stringaMeseCorrente = _stringaMeseAnno(_meseSelezionato);

    double pianificatoBisogni = _vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').fold(0.0, (sum, v) => sum + (v['previsto'] as num));
    double pianificatoSvago = _vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').fold(0.0, (sum, v) => sum + (v['previsto'] as num));
    double pianificatoRisparmio = _vociPianificate.where((v) => v['categoria'] == 'Risparmio (20%)').fold(0.0, (sum, v) => sum + (v['previsto'] as num));

    double totaleSpesePianificate = pianificatoBisogni + pianificatoSvago;
    double percentualeRisparmioStimata = (_entrateMensiliRiferimento > 0)
        ? ((_entrateMensiliRiferimento - totaleSpesePianificate) / _entrateMensiliRiferimento * 100)
        : 0.0;

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
      title: 'Pilotaggio Budget',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BARRA MESI E PULSANTI D'AZIONE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _cambiaMese(-1),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stringaMeseCorrente.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _cambiaMese(1),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _mostraDialogModificaRegola,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Text('Target 50/30/20', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _mostraDialogAggiungiSpesa,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                      ),
                      child: const Text('+ Spesa', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. BANNER COMPATTO DEL COACH FINANZIARIO
          _buildCoachBannerPulito(percentualeRisparmioStimata),

          const SizedBox(height: 12),

          // 3. FILTRI
          Row(
            children: [
              FilterChip(
                selected: _filtroVisualizzazione == 'tutti',
                label: const Text('Tutte le Voci', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: const Color(0xFF2DD4BF).withOpacity(0.25),
                side: BorderSide(color: _filtroVisualizzazione == 'tutti' ? const Color(0xFF2DD4BF) : Colors.white12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (_) => setState(() => _filtroVisualizzazione = 'tutti'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _filtroVisualizzazione == 'da_saldare',
                avatar: const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFF59E0B)),
                label: const Text('Da Saldare ⏳', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: const Color(0xFFF59E0B).withOpacity(0.25),
                side: BorderSide(color: _filtroVisualizzazione == 'da_saldare' ? const Color(0xFFF59E0B) : Colors.white12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (_) => setState(() => _filtroVisualizzazione = 'da_saldare'),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. CATEGORIE ESPANDIBILI
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryCardPulita(
                    provider: walletProvider,
                    categoriaKey: 'Bisogni (50%)',
                    title: '📌 Bisogni Fissi',
                    targetPct: _percentBisogni,
                    pianificatoTotale: pianificatoBisogni,
                    spesoRealeTotale: spesoBisogni,
                    color: const Color(0xFF2DD4BF),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').toList(),
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryCardPulita(
                    provider: walletProvider,
                    categoriaKey: 'Svago (30%)',
                    title: '🎉 Svago & Tempo Libero',
                    targetPct: _percentSvago,
                    pianificatoTotale: pianificatoSvago,
                    spesoRealeTotale: spesoSvago,
                    color: const Color(0xFFF59E0B),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').toList(),
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryCardPulita(
                    provider: walletProvider,
                    categoriaKey: 'Risparmio (20%)',
                    title: '🐷 Risparmi & Futuro',
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

  Widget _buildCoachBannerPulito(double pctRisparmio) {
    final bool ok = pctRisparmio >= _percentRisparmio;
    final Color colore = ok ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colore.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colore.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: colore, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok
                  ? 'Piano ok! Risparmi stimati: ${pctRisparmio.toStringAsFixed(0)}%'
                  : 'Sforamento: risparmio stimato al ${pctRisparmio.toStringAsFixed(0)}% (Target ${_percentRisparmio.toInt()}%)',
              style: TextStyle(color: colore, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCardPulita({
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
                children: [
                  Row(
                    children: [
                      Icon(
                        isEspansa ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                        color: color,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
                        child: Text('${targetPct.toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text(
                        '${spesoRealeTotale.toStringAsFixed(0)} / ${pianificatoTotale.toStringAsFixed(0)} €',
                        style: TextStyle(
                          color: isSforato ? const Color(0xFFEF4444) : Colors.white,
                          fontSize: 14,
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
                ],
              ),
            ),
          ),
          if (isEspansa) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: voci.map((v) => _buildVoceTilePulita(provider, v)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoceTilePulita(WalletProvider provider, Map<String, dynamic> v) {
    final double previsto = (v['previsto'] as num).toDouble();
    final double spesoReale = _calcolaSpesoReale(provider, v['nome'], v['sottocategoria'] ?? '');
    final String tipo = v['tipo'] ?? 'mensile';
    final String? meseScadenza = v['meseScadenza']; // 👈 Legge il mese salvato

    final double differenza = spesoReale - previsto;
    final bool isSforato = differenza > 0.01 && previsto > 0;
    final bool isSaldata = spesoReale >= previsto && previsto > 0;

    if (_filtroVisualizzazione == 'da_saldare' && isSaldata) {
      return const SizedBox.shrink();
    }

    Widget badgeStato;
    Color coloreImporto = Colors.white;

    if (tipo == 'annuale_spalmata') {
      // 👈 Mostra chiaramente in quale mese scade la spesa annuale
      final String etichetta = meseScadenza != null 
          ? 'Accantonata • Scade a $meseScadenza' 
          : 'Accantonata';
      badgeStato = _buildBadgeTag(etichetta, const Color(0xFF3B82F6));
      coloreImporto = const Color(0xFF3B82F6);
    } else if (isSforato) {
      badgeStato = _buildBadgeTag('⚠️ +${differenza.toStringAsFixed(0)} €', const Color(0xFFEF4444));
      coloreImporto = const Color(0xFFEF4444);
    } else if (isSaldata) {
      badgeStato = _buildBadgeTag('✓ Saldata', const Color(0xFF10B981));
      coloreImporto = const Color(0xFF10B981);
    } else {
      badgeStato = _buildBadgeTag('⏳ In Attesa', const Color(0xFFF59E0B));
      coloreImporto = const Color(0xFFF59E0B);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _gestisciSpesaDialog(v),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSforato ? const Color(0xFFEF4444).withOpacity(0.5) : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['nome'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    badgeStato,
                  ],
                ),
              ),
              Text(
                '${spesoReale.toStringAsFixed(0)} / ${previsto.toStringAsFixed(0)} €',
                style: TextStyle(color: coloreImporto, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}