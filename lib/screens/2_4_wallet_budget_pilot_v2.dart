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

  // 🔒 STATO INIZIALE: TUTTI I TRE ELEMENTI SONO CHIUSI ALL'APERTURA
  final Set<String> _categorieEspanse = {};

  double _percentBisogni = 50.0;
  double _percentSvago = 30.0;
  double _percentRisparmio = 20.0;
  double _entrateMensiliRiferimento = 2500.00;

  // 🇮🇹 MESI A 3 LETTERE PER NON OCCUPARE SPAZIO
  final List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
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
      'meseScadenza': 'SET',
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

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  String _formattaInt(double importo) {
    final intVal = importo.round();
    final strVal = intVal.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$strVal €';
  }

  String _stringaMeseAnno(DateTime dt) {
    return '${_nomiMesiBrevi[dt.month - 1]} ${dt.year}';
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
    final TextEditingController previstoCtrl = TextEditingController(
      text: (voce['previsto'] as num).toStringAsFixed(2).replaceAll('.', ','),
    );
    String sottoCatSel = voce['sottocategoria'] ?? 'Alimentari';

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.edit_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Modifica Spesa',
      testoConferma: 'Salva',
      onConferma: () {
        final nuovoNome = nomeCtrl.text.trim();
        final nuovoPrevisto = double.tryParse(previstoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? voce['previsto'];

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
            style: const TextStyle(color: Colors.white, fontSize: 13),
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
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Budget Previsto (€)',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 16),
            ),
          ),
          const SizedBox(height: 12),
          const Text('CATEGORIA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
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
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
            label: const Text('Elimina questa spesa', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostraDialogAggiungiSpesa() {
    final TextEditingController nomeCtrl = TextEditingController();
    final TextEditingController importoCtrl = TextEditingController();
    final TextEditingController quotaManualeCtrl = TextEditingController();

    String categoriaSel = '50';
    String sottoCatSel = _sottocategorieDisponibili.first;
    String tipoSpesaSel = 'mensile'; 
    String modalitaAccantonamento = 'spalmata_12';
    String meseScadenzaSel = _nomiMesiBrevi[_meseSelezionato.month - 1];

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.add_circle_outline_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Nuova Spesa Pianificata',
      testoConferma: 'Aggiungi',
      onConferma: () {
        final nome = nomeCtrl.text.trim();
        final importoTotale = double.tryParse(importoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
        final quotaManuale = double.tryParse(quotaManualeCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

        if (nome.isNotEmpty && importoTotale > 0) {
          double quotaMensileCalcolata = importoTotale;

          if (tipoSpesaSel == 'annuale') {
            if (modalitaAccantonamento == 'spalmata_12') {
              quotaMensileCalcolata = importoTotale / 12;
            } else if (modalitaAccantonamento == 'addebito_unico') {
              final bool eMeseDiScadenza = _nomiMesiBrevi[_meseSelezionato.month - 1] == meseScadenzaSel;
              quotaMensileCalcolata = eMeseDiScadenza ? importoTotale : 0.0;
            } else if (modalitaAccantonamento == 'manuale') {
              quotaMensileCalcolata = quotaManuale;
            }
          }

          setState(() {
            _vociPianificate.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'nome': nome,
              'categoria': categoriaSel == '50' 
                  ? 'Bisogni (50%)' 
                  : (categoriaSel == '30' ? 'Svago (30%)' : 'Risparmio (20%)'),
              'sottocategoria': sottoCatSel,
              'previsto': quotaMensileCalcolata,
              'tipo': tipoSpesaSel == 'annuale' ? 'annuale_spalmata' : 'mensile',
              'modalitaAccantonamento': modalitaAccantonamento,
              if (tipoSpesaSel == 'annuale') 'totaleAnnuale': importoTotale,
              if (tipoSpesaSel == 'annuale') 'meseScadenza': meseScadenzaSel,
            });
          });
          Navigator.pop(context);
          AppNotifications.mostraInAlto(context, 'Spesa "$nome" aggiunta alla pianificazione! 🎉');
        } else {
          AppNotifications.mostraInAlto(
            context,
            'Inserisci un nome e un importo valido',
            type: NotificationType.warning,
          );
        }
      },
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final bool isAnnuale = tipoSpesaSel == 'annuale';
          final double importoTotale = double.tryParse(importoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Nome spesa (es. Assicurazione, TARI)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
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
                        label: const Text('Spesa Mensile', style: TextStyle(fontSize: 11)),
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
                        label: const Text('Annuale', style: TextStyle(fontSize: 11)),
                        selected: isAnnuale,
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(color: isAnnuale ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                        onSelected: (_) => setDialogState(() => tipoSpesaSel = 'annuale'),
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
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 16),
                  ),
                ),

                if (isAnnuale) ...[
                  const SizedBox(height: 12),
                  const Text('MESE DI SCADENZA', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: meseScadenzaSel,
                    dropdownColor: const Color(0xFF1C1C21),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF3B82F6), size: 16),
                    ),
                    items: _nomiMesiBrevi.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setDialogState(() => meseScadenzaSel = val!),
                  ),
                  const SizedBox(height: 12),
                  const Text('COME VUOI GESTIRLA NEL BUDGET?', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  
                  Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFF2DD4BF),
                        title: const Text('Spalma su 12 mesi', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        subtitle: Text('Accantoni ${_formattaValuta(importoTotale / 12)} al mese', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        value: 'spalmata_12',
                        groupValue: modalitaAccantonamento,
                        onChanged: (val) => setDialogState(() => modalitaAccantonamento = val!),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFF2DD4BF),
                        title: const Text('Addebito Unico a Scadenza', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        subtitle: Text('0 € nei mesi ordinari, ${_formattaValuta(importoTotale)} solo a $meseScadenzaSel', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        value: 'addebito_unico',
                        groupValue: modalitaAccantonamento,
                        onChanged: (val) => setDialogState(() => modalitaAccantonamento = val!),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFF2DD4BF),
                        title: const Text('Quota Mensile Personalizzata', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Decidi tu quanti euro mettere via al mese', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        value: 'manuale',
                        groupValue: modalitaAccantonamento,
                        onChanged: (val) => setDialogState(() => modalitaAccantonamento = val!),
                      ),
                    ],
                  ),

                  if (modalitaAccantonamento == 'manuale') ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: quotaManualeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Quota Mensile da Accantonare (€)',
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 12),
                const Text('REGOLA DI BUDGET (50/30/20)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    DropdownMenuItem(value: '50', child: Text('Spese Fisse & Bisogni (50%)')),
                    DropdownMenuItem(value: '30', child: Text('Spese Variabili & Tempo Libero (30%)')),
                    DropdownMenuItem(value: '20', child: Text('Risparmi & Futuro (20%)')),
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
    final TextEditingController entrateCtrl = TextEditingController(
      text: _entrateMensiliRiferimento.toStringAsFixed(0),
    );

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Regola 50 / 30 / 20',
      testoConferma: 'Salva Regola',
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Entrate Mensili Nette di Riferimento (€)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF2DD4BF), size: 16),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Spese Fisse & Bisogni: ${tempBisogni.toInt()}%', style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 12)),
                Slider(
                  value: tempBisogni,
                  min: 10, max: 80, divisions: 14,
                  activeColor: const Color(0xFF2DD4BF),
                  onChanged: (val) => setDialogState(() => tempBisogni = val),
                ),
                Text('Spese Variabili & Tempo Libero: ${tempSvago.toInt()}%', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                Slider(
                  value: tempSvago,
                  min: 10, max: 80, divisions: 14,
                  activeColor: const Color(0xFFF59E0B),
                  onChanged: (val) => setDialogState(() => tempSvago = val),
                ),
                Text('Risparmi & Futuro: ${tempRisparmio.toInt()}%', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
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
                      fontSize: 11,
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
      title: 'Pianificazione Spese', // 👈 TITOLO ELEGANTE E PERSONALE
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BARRA MESI COMPATTA CON MESI A 3 LETTERE + TASTI AZIONE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _cambiaMese(-1),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stringaMeseCorrente.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _cambiaMese(1),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _mostraDialogModificaRegola,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text('Modifica 50/30/20', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _mostraDialogAggiungiSpesa,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF2DD4BF), size: 14),
                          SizedBox(width: 2),
                          Text('Spesa', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. FILTRI COMPATTI
          Row(
            children: [
              FilterChip(
                selected: _filtroVisualizzazione == 'tutti',
                label: const Text('Tutte le Voci', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: const Color(0xFF2DD4BF).withOpacity(0.25),
                side: BorderSide(color: _filtroVisualizzazione == 'tutti' ? const Color(0xFF2DD4BF) : Colors.white12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() => _filtroVisualizzazione = 'tutti'),
              ),
              const SizedBox(width: 6),
              FilterChip(
                selected: _filtroVisualizzazione == 'da_saldare',
                avatar: const Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFF59E0B)),
                label: const Text('Da Saldare', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: const Color(0xFFF59E0B).withOpacity(0.25),
                side: BorderSide(color: _filtroVisualizzazione == 'da_saldare' ? const Color(0xFFF59E0B) : Colors.white12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() => _filtroVisualizzazione = 'da_saldare'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. CATEGORIE (INIZIALMENTE TUTTE CHIUSE)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryCardPulita(
                    provider: walletProvider,
                    categoriaKey: '50',
                    title: 'Spese Fisse & Bisogni',
                    icon: Icons.home_rounded,
                    targetPct: _percentBisogni,
                    pianificatoTotale: pianificatoBisogni,
                    spesoRealeTotale: spesoBisogni,
                    color: const Color(0xFF2DD4BF),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryCardPulita(
                    provider: walletProvider,
                    categoriaKey: '30',
                    title: 'Spese Variabili & Tempo Libero',
                    icon: Icons.explore_rounded,
                    targetPct: _percentSvago,
                    pianificatoTotale: pianificatoSvago,
                    spesoRealeTotale: spesoSvago,
                    color: const Color(0xFFF59E0B),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryCardPulita(
                    provider: walletProvider,
                    categoriaKey: '20',
                    title: 'Risparmi & Futuro',
                    icon: Icons.trending_up_rounded,
                    targetPct: _percentRisparmio,
                    pianificatoTotale: pianificatoRisparmio,
                    spesoRealeTotale: spesoRisparmio,
                    color: const Color(0xFF3B82F6),
                    voci: _vociPianificate.where((v) => v['categoria'] == 'Risparmio (20%)').toList(),
                  ),
                  const SizedBox(height: 12),

                  // 💡 SUGGERIMENTO COERENTE IN STILE LAMPADINA DISCRETA
                  _buildNotaDiscreta(percentualeRisparmioStimata),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 NOTA ELEGANTE E DISCRETA IN STILE BUSSOLA FISCON
  Widget _buildNotaDiscreta(double pctRisparmio) {
    final bool ok = pctRisparmio >= _percentRisparmio;
    final Color colore = ok ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B);

    return Row(
      children: [
        Icon(
          ok ? Icons.lightbulb_outline_rounded : Icons.info_outline_rounded,
          color: colore,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ok
                ? 'Ottimo! Stai mantenendo una quota risparmio stimata del ${pctRisparmio.toStringAsFixed(0)}% per il tuo futuro.'
                : 'Consiglio: le spese pianificate riducono il risparmio al ${pctRisparmio.toStringAsFixed(0)}% (Target ${_percentRisparmio.toInt()}%).',
            style: TextStyle(
              color: ok ? Colors.white70 : const Color(0xFFF59E0B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCardPulita({
    required WalletProvider provider,
    required String categoriaKey,
    required String title,
    required IconData icon,
    required double targetPct,
    required double pianificatoTotale,
    required double spesoRealeTotale,
    required Color color,
    required List<Map<String, dynamic>> voci,
  }) {
    final bool isEspansa = _categorieEspanse.contains(categoriaKey);
    final double pctProgresso = pianificatoTotale > 0 ? (spesoRealeTotale / pianificatoTotale).clamp(0.0, 1.0) : 0.0;
    final bool isSforato = spesoRealeTotale > pianificatoTotale && pianificatoTotale > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
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
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 8),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(5)),
                        child: Text('${targetPct.toInt()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text(
                        '${_formattaInt(spesoRealeTotale)} / ${_formattaInt(pianificatoTotale)}',
                        style: TextStyle(
                          color: isSforato ? const Color(0xFFEF4444) : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pctProgresso,
                      minHeight: 4,
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
              padding: const EdgeInsets.all(8),
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
    final String? meseScadenza = v['meseScadenza'];

    final double differenza = spesoReale - previsto;
    final bool isSforato = differenza > 0.01 && previsto > 0;
    final bool isSaldata = spesoReale >= previsto && previsto > 0;

    if (_filtroVisualizzazione == 'da_saldare' && isSaldata) {
      return const SizedBox.shrink();
    }

    Widget badgeStato;
    Color coloreImporto = Colors.white;

    if (tipo == 'annuale_spalmata') {
      final String etichetta = meseScadenza != null 
          ? 'Accantonata • Scade a $meseScadenza' 
          : 'Accantonata';
      badgeStato = _buildBadgeTag(etichetta, const Color(0xFF3B82F6));
      coloreImporto = const Color(0xFF3B82F6);
    } else if (isSforato) {
      badgeStato = _buildBadgeTag('+${_formattaInt(differenza)} Fuori Budget', const Color(0xFFEF4444));
      coloreImporto = const Color(0xFFEF4444);
    } else if (isSaldata) {
      badgeStato = _buildBadgeTag('Saldata', const Color(0xFF10B981));
      coloreImporto = const Color(0xFF10B981);
    } else {
      badgeStato = _buildBadgeTag('In Attesa', const Color(0xFFF59E0B));
      coloreImporto = const Color(0xFFF59E0B);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _gestisciSpesaDialog(v),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
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
                    Text(v['nome'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    badgeStato,
                  ],
                ),
              ),
              Text(
                '${_formattaInt(spesoReale)} / ${_formattaInt(previsto)}',
                style: TextStyle(color: coloreImporto, fontSize: 12, fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}