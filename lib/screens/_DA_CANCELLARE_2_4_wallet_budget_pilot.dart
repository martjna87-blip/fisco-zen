import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_bottom_sheet.dart';
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

  final Set<String> _categorieEspanse = {};

  double _percentBisogni = 50.0;
  double _percentSvago = 30.0;
  double _percentRisparmio = 20.0;
  double _entrateMensiliRiferimento = 2500.00;

  // 🎨 COLORI ALLINEATI ALLA BUSSOLA SPESE
  static const Color _colorBisogni = Color(0xFF38BDF8); // Celeste Sky 50%
  static const Color _colorSvago = Color(0xFFF59E0B);   // Ambra 30%
  static const Color _colorRisparmio = Color(0xFFC084FC); // Viola Lilla 20%

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
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '2',
      'nome': 'Bollette & Utenze',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Canoni/Bollette',
      'previsto': 140.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '3',
      'nome': 'Spesa Alimentare',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Alimentari',
      'previsto': 350.00,
      'tipo': 'variabile',
      'frequenzaMensile': 'tutti',
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
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '6',
      'nome': 'Hobby & Palestra',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Divertimento',
      'previsto': 80.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '7',
      'nome': 'Abbonamenti Streaming',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Canoni/Bollette',
      'previsto': 30.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '8',
      'nome': 'Fondo Emergenze',
      'categoria': 'Risparmio (20%)',
      'sottocategoria': 'Altro',
      'previsto': 300.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '9',
      'nome': 'Accantonamento Vacanze',
      'categoria': 'Risparmio (20%)',
      'sottocategoria': 'Viaggi',
      'previsto': 200.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
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
      iconColor: _colorBisogni,
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
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
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
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.euro_symbol_rounded, color: _colorBisogni, size: 16),
            ),
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

  // 🚀 POPUP NUOVA SPESA CON TENDINE CUSTOM IN STILE "CREA NUOVO CONTO"
  void _mostraDialogAggiungiSpesa() {
    final TextEditingController nomeCtrl = TextEditingController();
    final TextEditingController importoCtrl = TextEditingController();
    final TextEditingController quotaManualeCtrl = TextEditingController();

    String categoriaSel = '50';
    String sottoCatSel = _sottocategorieDisponibili.first;
    String tipoSpesaSel = 'mensile'; 
    String frequenzaMensileSel = 'tutti'; // 'tutti' oppure 'specifico'
    String meseSpecificoSel = _nomiMesiBrevi[_meseSelezionato.month - 1];
    String modalitaAccantonamento = 'spalmata_12';
    String meseScadenzaSel = _nomiMesiBrevi[_meseSelezionato.month - 1];

    bool isTendinaRegolaAperta = false;
    bool isTendinaMeseScadenzaAperta = false;
    bool isTendinaMeseSpecificoAperta = false;

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.add_circle_outline_rounded,
      iconColor: _colorBisogni,
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
              'frequenzaMensile': frequenzaMensileSel,
              'meseSpecifico': meseSpecificoSel,
              'modalitaAccantonamento': modalitaAccantonamento,
              if (tipoSpesaSel == 'annuale') 'totaleAnnuale': importoTotale,
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
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final bool isAnnuale = tipoSpesaSel == 'annuale';
          final double importoTotale = double.tryParse(importoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

          String nomeRegolaSelezionata = 'Spese Fisse & Bisogni (50%)';
          if (categoriaSel == '30') nomeRegolaSelezionata = 'Spese Variabili & Tempo Libero (30%)';
          if (categoriaSel == '20') nomeRegolaSelezionata = 'Risparmi & Futuro (20%)';

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. NOME SPESA
                TextField(
                  controller: nomeCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Nome Spesa (es. Affitto, Assicurazione, TARI)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. TIPO SPESA (MENSILE VS ANNUALE)
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Spesa Mensile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        selected: !isAnnuale,
                        selectedColor: _colorBisogni,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(color: !isAnnuale ? Colors.black : Colors.white70),
                        onSelected: (_) => setDialogState(() => tipoSpesaSel = 'mensile'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Spesa Annuale', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        selected: isAnnuale,
                        selectedColor: _colorRisparmio,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(color: isAnnuale ? Colors.white : Colors.white70),
                        onSelected: (_) => setDialogState(() => tipoSpesaSel = 'annuale'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. FREQUENZA PER SPESA MENSILE (TUTTI I MESI O MESE SPECIFICO)
                if (!isAnnuale) ...[
                  const Text('FREQUENZA PIANIFICAZIONE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Tutti i Mesi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          selected: frequenzaMensileSel == 'tutti',
                          selectedColor: Colors.white24,
                          backgroundColor: Colors.white.withOpacity(0.03),
                          labelStyle: TextStyle(color: frequenzaMensileSel == 'tutti' ? Colors.white : Colors.white54),
                          onSelected: (_) => setDialogState(() => frequenzaMensileSel = 'tutti'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Solo Mese Specifico', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          selected: frequenzaMensileSel == 'specifico',
                          selectedColor: Colors.white24,
                          backgroundColor: Colors.white.withOpacity(0.03),
                          labelStyle: TextStyle(color: frequenzaMensileSel == 'specifico' ? Colors.white : Colors.white54),
                          onSelected: (_) => setDialogState(() => frequenzaMensileSel = 'specifico'),
                        ),
                      ),
                    ],
                  ),

                  if (frequenzaMensileSel == 'specifico') ...[
                    const SizedBox(height: 10),
                    // TENDINA MESE SPECIFICO IN STILE CUSTOM
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTendinaMeseSpecificoAperta ? _colorBisogni : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setDialogState(() => isTendinaMeseSpecificoAperta = !isTendinaMeseSpecificoAperta),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, color: _colorBisogni, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Pianifica solo a: $meseSpecificoSel', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Icon(isTendinaMeseSpecificoAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _colorBisogni, size: 18),
                                ],
                              ),
                            ),
                          ),
                          if (isTendinaMeseSpecificoAperta) ...[
                            const Divider(color: Colors.white12, height: 1),
                            Column(
                              children: _nomiMesiBrevi.map((m) {
                                final bool isSelected = m == meseSpecificoSel;
                                return InkWell(
                                  onTap: () => setDialogState(() {
                                    meseSpecificoSel = m;
                                    isTendinaMeseSpecificoAperta = false;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    color: isSelected ? _colorBisogni.withOpacity(0.15) : Colors.transparent,
                                    child: Row(
                                      children: [
                                        Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? _colorBisogni : Colors.white38, size: 14),
                                        const SizedBox(width: 8),
                                        Text(m, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],

                // 4. IMPORTO
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
                    prefixIcon: const Icon(Icons.euro_symbol_rounded, color: _colorBisogni, size: 16),
                  ),
                ),

                // 5. SE E' ANNUALE
                if (isAnnuale) ...[
                  const SizedBox(height: 12),
                  const Text('MESE DI SCADENZA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  
                  // TENDINA CUSTOM MESE DI SCADENZA
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTendinaMeseScadenzaAperta ? _colorRisparmio : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setDialogState(() => isTendinaMeseScadenzaAperta = !isTendinaMeseScadenzaAperta),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, color: _colorRisparmio, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Scadenza: $meseScadenzaSel', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Icon(isTendinaMeseScadenzaAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _colorRisparmio, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (isTendinaMeseScadenzaAperta) ...[
                          const Divider(color: Colors.white12, height: 1),
                          Column(
                            children: _nomiMesiBrevi.map((m) {
                              final bool isSelected = m == meseScadenzaSel;
                              return InkWell(
                                onTap: () => setDialogState(() {
                                  meseScadenzaSel = m;
                                  isTendinaMeseScadenzaAperta = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  color: isSelected ? _colorRisparmio.withOpacity(0.15) : Colors.transparent,
                                  child: Row(
                                    children: [
                                      Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? _colorRisparmio : Colors.white38, size: 14),
                                      const SizedBox(width: 8),
                                      Text(m, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text('COME VUOI GESTIRLA NEL BUDGET?', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: _colorBisogni,
                    title: const Text('Spalma su 12 mesi', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    subtitle: Text('Accantoni ${_formattaValuta(importoTotale / 12)} al mese', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    value: 'spalmata_12',
                    groupValue: modalitaAccantonamento,
                    onChanged: (val) => setDialogState(() => modalitaAccantonamento = val!),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: _colorBisogni,
                    title: const Text('Addebito Unico a Scadenza', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    subtitle: Text('0 € nei mesi ordinari, ${_formattaValuta(importoTotale)} solo a $meseScadenzaSel', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    value: 'addebito_unico',
                    groupValue: modalitaAccantonamento,
                    onChanged: (val) => setDialogState(() => modalitaAccantonamento = val!),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: _colorBisogni,
                    title: const Text('Quota Mensile Personalizzata', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Decidi tu quanti euro mettere via al mese', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    value: 'manuale',
                    groupValue: modalitaAccantonamento,
                    onChanged: (val) => setDialogState(() => modalitaAccantonamento = val!),
                  ),

                  if (modalitaAccantonamento == 'manuale') ...[
                    const SizedBox(height: 4),
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
                const Text('REGOLA DI BUDGET (50/30/20)', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 6),

                // 6. TENDINA CUSTOM REGOLA DI BUDGET (IN STILE CREA NUOVO CONTO)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTendinaRegolaAperta ? _colorBisogni : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setDialogState(() => isTendinaRegolaAperta = !isTendinaRegolaAperta),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.pie_chart_outline_rounded, color: categoriaSel == '50' ? _colorBisogni : (categoriaSel == '30' ? _colorSvago : _colorRisparmio), size: 16),
                                  const SizedBox(width: 8),
                                  Text(nomeRegolaSelezionata, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Icon(isTendinaRegolaAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _colorBisogni, size: 18),
                            ],
                          ),
                        ),
                      ),
                      if (isTendinaRegolaAperta) ...[
                        const Divider(color: Colors.white12, height: 1),
                        Column(
                          children: [
                            _buildOptionRegola('50', 'Spese Fisse & Bisogni (50%)', _colorBisogni, categoriaSel, (val) {
                              setDialogState(() {
                                categoriaSel = val;
                                isTendinaRegolaAperta = false;
                              });
                            }),
                            _buildOptionRegola('30', 'Spese Variabili & Tempo Libero (30%)', _colorSvago, categoriaSel, (val) {
                              setDialogState(() {
                                categoriaSel = val;
                                isTendinaRegolaAperta = false;
                              });
                            }),
                            _buildOptionRegola('20', 'Risparmi & Futuro (20%)', _colorRisparmio, categoriaSel, (val) {
                              setDialogState(() {
                                categoriaSel = val;
                                isTendinaRegolaAperta = false;
                              });
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionRegola(String valKey, String label, Color color, String currentSel, Function(String) onSelect) {
    final bool isSelected = valKey == currentSel;
    return InkWell(
      onTap: () => onSelect(valKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? color : Colors.white38, size: 15),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
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
      iconColor: _colorBisogni,
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
                    prefixIcon: const Icon(Icons.payments_outlined, color: _colorBisogni, size: 16),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Spese Fisse & Bisogni: ${tempBisogni.toInt()}%', style: const TextStyle(color: _colorBisogni, fontWeight: FontWeight.bold, fontSize: 11)),
                Slider(
                  value: tempBisogni,
                  min: 10, max: 80, divisions: 14,
                  activeColor: _colorBisogni,
                  onChanged: (val) => setDialogState(() => tempBisogni = val),
                ),
                Text('Spese Variabili & Tempo Libero: ${tempSvago.toInt()}%', style: const TextStyle(color: _colorSvago, fontWeight: FontWeight.bold, fontSize: 11)),
                Slider(
                  value: tempSvago,
                  min: 10, max: 80, divisions: 14,
                  activeColor: _colorSvago,
                  onChanged: (val) => setDialogState(() => tempSvago = val),
                ),
                Text('Risparmi & Futuro: ${tempRisparmio.toInt()}%', style: const TextStyle(color: _colorRisparmio, fontWeight: FontWeight.bold, fontSize: 11)),
                Slider(
                  value: tempRisparmio,
                  min: 0, max: 50, divisions: 10,
                  activeColor: _colorRisparmio,
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
    final screenHeight = MediaQuery.of(context).size.height;
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

    return AppBottomSheet(
      title: 'Pianificazione Spese',
      badgeText: 'Wallet',
      badgeColor: _colorBisogni,
      child: Container(
        height: screenHeight * 0.55, // 🔒 55% FISSO
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BARRA MESI MIGLIORATA CON BORDER PERCEPICILE + PULSANTI PULITI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _cambiaMese(-1),
                        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stringaMeseCorrente.toUpperCase(),
                        style: const TextStyle(color: _colorBisogni, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _cambiaMese(1),
                        child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, color: Colors.white, size: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _colorBisogni.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _colorBisogni.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: _colorBisogni, size: 14),
                            SizedBox(width: 2),
                            Text('Spesa', style: TextStyle(color: _colorBisogni, fontSize: 10, fontWeight: FontWeight.bold)),
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
                  selectedColor: _colorBisogni.withOpacity(0.25),
                  side: BorderSide(color: _filtroVisualizzazione == 'tutti' ? _colorBisogni : Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _filtroVisualizzazione = 'tutti'),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  selected: _filtroVisualizzazione == 'da_saldare',
                  avatar: const Icon(Icons.hourglass_top_rounded, size: 12, color: _colorSvago),
                  label: const Text('Da Saldare', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  selectedColor: _colorSvago.withOpacity(0.25),
                  side: BorderSide(color: _filtroVisualizzazione == 'da_saldare' ? _colorSvago : Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _filtroVisualizzazione = 'da_saldare'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 3. CATEGORIE CON COLORI BUSSOLA E GERARCHIA NUMERICA PERFETTA
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
                      color: _colorBisogni, // 🩵 Celeste Sky
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
                      color: _colorSvago, // 🧡 Ambra
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
                      color: _colorRisparmio, // 💜 Viola Lilla
                      voci: _vociPianificate.where((v) => v['categoria'] == 'Risparmio (20%)').toList(),
                    ),
                    const SizedBox(height: 12),

                    _buildNotaDiscreta(percentualeRisparmioStimata),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotaDiscreta(double pctRisparmio) {
    final bool ok = pctRisparmio >= _percentRisparmio;
    final Color colore = ok ? _colorBisogni : _colorSvago;

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
              color: ok ? Colors.white70 : _colorSvago,
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
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(5)),
                        child: Text('${targetPct.toInt()}%', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),

                      // 🌟 GERARCHIA NUMERICA PERFETTA (Speso luminoso / Previsto sobrio)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formattaInt(spesoRealeTotale),
                            style: TextStyle(
                              color: isSforato ? const Color(0xFFEF4444) : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${_formattaInt(pianificatoTotale)}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
      badgeStato = _buildBadgeTag(etichetta, _colorRisparmio);
      coloreImporto = _colorRisparmio;
    } else if (isSforato) {
      badgeStato = _buildBadgeTag('+${_formattaInt(differenza)} Fuori Budget', const Color(0xFFEF4444));
      coloreImporto = const Color(0xFFEF4444);
    } else if (isSaldata) {
      badgeStato = _buildBadgeTag('Saldata', const Color(0xFF10B981));
      coloreImporto = const Color(0xFF10B981);
    } else {
      badgeStato = _buildBadgeTag('In Attesa', _colorSvago);
      coloreImporto = _colorSvago;
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
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formattaInt(spesoReale),
                    style: TextStyle(color: coloreImporto, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' / ${_formattaInt(previsto)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
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