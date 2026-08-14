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

  // 🎨 COLORI
  static const Color _colorBisogni = Color(0xFF38BDF8); // Celeste Sky 50%
  static const Color _colorSvago = Color(0xFFF59E0B);   // Ambra 30%
  static const Color _colorRisparmio = Color(0xFFC084FC); // Viola Lilla 20%

  final List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
  ];

  final List<String> _sottocategorieDisponibili = [
    'Casa/Affitto', 'Canoni/Bollette', 'Alimentari', 'Acquisti',
    'Divertimento', 'Auto', 'Viaggi', 'Salute & Benessere', 'Altro',
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

  double _getPrevistoPerMese(Map<String, dynamic> voce, DateTime meseObiettivo) {
    final double importoBase = (voce['previsto'] as num).toDouble();
    final String tipo = voce['tipo'] ?? 'mensile';
    final String freq = voce['frequenzaMensile'] ?? 'tutti';
    final String? meseScadenzaStr = voce['meseScadenza'] ?? voce['meseSpecifico'];

    if (freq == 'tutti' || tipo == 'annuale_spalmata') return importoBase;

    int targetMonth = 1;
    if (meseScadenzaStr != null) {
      targetMonth = _nomiMesiBrevi.indexOf(meseScadenzaStr) + 1;
    }

    if (freq == 'specifico' || tipo == 'annuale_unico') {
      return (meseObiettivo.month == targetMonth) ? importoBase : 0.0;
    }

    if (freq == 'ogni_2_mesi') {
      int diff = (meseObiettivo.month - targetMonth).abs();
      return (diff % 2 == 0) ? importoBase : 0.0;
    }

    if (freq == 'ogni_3_mesi') {
      int diff = (meseObiettivo.month - targetMonth).abs();
      return (diff % 3 == 0) ? importoBase : 0.0;
    }

    return 0.0;
  }

  IconData _getIconaVoce(String nome, String? sottoCat) {
    final n = nome.toLowerCase();
    final s = (sottoCat ?? '').toLowerCase();
    if (n.contains('affitto') || n.contains('mutuo') || s.contains('casa')) return Icons.home_rounded;
    if (n.contains('bollet') || n.contains('utenze') || s.contains('canoni')) return Icons.bolt_rounded;
    if (n.contains('spesa') || n.contains('alimentar') || s.contains('alimentari')) return Icons.shopping_cart_rounded;
    if (n.contains('auto') || n.contains('trasporti') || s.contains('auto')) return Icons.directions_car_rounded;
    if (n.contains('ristorant') || n.contains('uscit') || s.contains('divertimento')) return Icons.restaurant_rounded;
    if (n.contains('abbonament') || n.contains('stream')) return Icons.live_tv_rounded;
    if (n.contains('palestra') || n.contains('sport') || n.contains('hobby')) return Icons.fitness_center_rounded;
    if (n.contains('vacanz') || n.contains('viagg') || s.contains('viaggi')) return Icons.flight_takeoff_rounded;
    if (n.contains('fondo') || n.contains('risparm')) return Icons.savings_rounded;
    if (s.contains('salute') || n.contains('medico')) return Icons.medical_services_rounded;
    return Icons.receipt_long_rounded;
  }

  void _azzeraPianificazione(WalletProvider provider) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx1) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Azzera Pianificazione', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Vuoi davvero cancellare tutte le ${provider.vociPianificate.length} spese pianificate?',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx1), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(ctx1); _confermaDefinitivaAzzeramento(provider); },
            child: const Text('Procedi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confermaDefinitivaAzzeramento(WalletProvider provider) {
    showDialog(
      context: context,
      builder: (ctx2) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Conferma Definitiva', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('L\'azione è irreversibile. Tutte le voci verranno rimosse.', style: TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Annulla', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              provider.azzeraPianificazioneSpese();
              Navigator.pop(ctx2);
              AppNotifications.mostraInAlto(context, 'Pianificazione azzerata con successo! 🧹', type: NotificationType.warning);
            },
            child: const Text('SÌ, AZZERA TUTTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              labelText: 'Importo Base (€)',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              context.read<WalletProvider>().rimuoviSpesaPianificata(voce['id']);
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

    String categoriaSel = '50';
    String sottoCatSel = _sottocategorieDisponibili.first;
    
    String frequenzaSel = '1_mese'; 
    String meseTargetSel = _nomiMesiBrevi[_meseSelezionato.month - 1];
    String modalitaAnnualeSel = 'spalmata_12';

    bool isTendinaRegolaAperta = false;
    bool isTendinaFrequenzaAperta = false;
    bool isTendinaMeseAperta = false;

    final List<Map<String, dynamic>> suggerimentiRapidi = [
      {'nome': 'Affitto / Mutuo', 'icon': Icons.home_rounded, 'cat': '50', 'color': _colorBisogni},
      {'nome': 'Spesa Alimentare', 'icon': Icons.shopping_cart_rounded, 'cat': '50', 'color': _colorBisogni},
      {'nome': 'Bollette & Utenze', 'icon': Icons.bolt_rounded, 'cat': '50', 'color': _colorBisogni},
      {'nome': 'Auto / Trasporti', 'icon': Icons.directions_car_rounded, 'cat': '50', 'color': _colorBisogni},
      {'nome': 'Ristoranti & Uscite', 'icon': Icons.restaurant_rounded, 'cat': '30', 'color': _colorSvago},
      {'nome': 'Abbonamenti', 'icon': Icons.live_tv_rounded, 'cat': '30', 'color': _colorSvago},
      {'nome': 'Sport / Palestra', 'icon': Icons.fitness_center_rounded, 'cat': '30', 'color': _colorSvago},
      {'nome': 'Fondo Emergenze', 'icon': Icons.savings_rounded, 'cat': '20', 'color': _colorRisparmio},
      {'nome': 'Fondo Vacanze', 'icon': Icons.flight_takeoff_rounded, 'cat': '20', 'color': _colorRisparmio},
    ];

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Pianifica Spesa',
      testoConferma: 'Aggiungi al Piano',
      onConferma: () {
        final nome = nomeCtrl.text.trim();
        final importoInserito = double.tryParse(importoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

        if (nome.isNotEmpty && importoInserito > 0) {
          double quotaMensileCalcolata = importoInserito;
          String tipoDb = 'mensile';
          String freqDb = 'tutti';

          if (frequenzaSel == '12_mesi') {
            if (modalitaAnnualeSel == 'spalmata_12') {
              tipoDb = 'annuale_spalmata';
              quotaMensileCalcolata = importoInserito / 12;
            } else {
              tipoDb = 'annuale_unico';
              freqDb = 'ogni_12_mesi';
            }
          } else if (frequenzaSel == 'una_tantum') {
            freqDb = 'specifico';
          } else if (frequenzaSel == '2_mesi') {
            freqDb = 'ogni_2_mesi';
          } else if (frequenzaSel == '3_mesi') {
            freqDb = 'ogni_3_mesi';
          }

          context.read<WalletProvider>().aggiungiSpesaPianificata({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'nome': nome,
            'categoria': categoriaSel == '50' ? 'Bisogni (50%)' : (categoriaSel == '30' ? 'Svago (30%)' : 'Risparmio (20%)'),
            'sottocategoria': sottoCatSel,
            'previsto': quotaMensileCalcolata,
            'tipo': tipoDb,
            'frequenzaMensile': freqDb,
            'meseSpecifico': meseTargetSel,
            if (frequenzaSel == '12_mesi') 'totaleAnnuale': importoInserito,
            if (frequenzaSel != '1_mese') 'meseScadenza': meseTargetSel,
            'frequenzaUX': frequenzaSel,
          });

          Navigator.pop(context);
          AppNotifications.mostraInAlto(context, 'Spesa "$nome" aggiunta! 🎯');
        } else {
          AppNotifications.mostraInAlto(context, 'Inserisci nome e importo', type: NotificationType.warning);
        }
      },
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final double importoVal = double.tryParse(importoCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
          
          String nomeRegola = 'Spese Fisse & Bisogni (50%)';
          if (categoriaSel == '30') nomeRegola = 'Spese Variabili & Tempo Libero (30%)';
          if (categoriaSel == '20') nomeRegola = 'Risparmi & Futuro (20%)';

          String labelFrequenza = 'Ogni Mese';
          IconData iconaFrequenza = Icons.autorenew_rounded;
          if (frequenzaSel == '2_mesi') labelFrequenza = 'Ogni 2 Mesi (Bimestrale)';
          if (frequenzaSel == '3_mesi') labelFrequenza = 'Ogni 3 Mesi (Trimestrale)';
          if (frequenzaSel == '12_mesi') { labelFrequenza = 'Ogni Anno (Annuale)'; iconaFrequenza = Icons.event_repeat_rounded; }
          if (frequenzaSel == 'una_tantum') { labelFrequenza = 'Solo una volta (Una Tantum)'; iconaFrequenza = Icons.push_pin_rounded; }

          final bool richiedeMese = frequenzaSel != '1_mese';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: suggerimentiRapidi.map((sug) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 12),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setDialogState(() {
                              nomeCtrl.text = sug['nome'];
                              categoriaSel = sug['cat'];
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: (sug['color'] as Color).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: (sug['color'] as Color).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(sug['icon'], color: sug['color'], size: 12),
                                const SizedBox(width: 4),
                                Text(sug['nome'], style: TextStyle(color: sug['color'], fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                TextField(
                  controller: nomeCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Che spesa è?',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: importoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setDialogState(() {}),
                  style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Importo della Rata/Spesa (€)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('QUANDO DEVI PAGARLA?', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isTendinaFrequenzaAperta ? Colors.white54 : Colors.white12),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setDialogState(() => isTendinaFrequenzaAperta = !isTendinaFrequenzaAperta),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(iconaFrequenza, color: Colors.white70, size: 16),
                                  const SizedBox(width: 10),
                                  Text(labelFrequenza, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Icon(isTendinaFrequenzaAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),
                      if (isTendinaFrequenzaAperta) ...[
                        const Divider(color: Colors.white12, height: 1),
                        _buildOptionFreq('1_mese', 'Ogni Mese', Icons.autorenew_rounded, frequenzaSel, (v) => setDialogState((){ frequenzaSel = v; isTendinaFrequenzaAperta = false;})),
                        _buildOptionFreq('2_mesi', 'Ogni 2 Mesi (Bimestrale)', Icons.sync_rounded, frequenzaSel, (v) => setDialogState((){ frequenzaSel = v; isTendinaFrequenzaAperta = false;})),
                        _buildOptionFreq('3_mesi', 'Ogni 3 Mesi (Trimestrale)', Icons.sync_rounded, frequenzaSel, (v) => setDialogState((){ frequenzaSel = v; isTendinaFrequenzaAperta = false;})),
                        _buildOptionFreq('12_mesi', 'Ogni Anno (Annuale)', Icons.event_repeat_rounded, frequenzaSel, (v) => setDialogState((){ frequenzaSel = v; isTendinaFrequenzaAperta = false;})),
                        _buildOptionFreq('una_tantum', 'Solo una volta (Una Tantum)', Icons.push_pin_rounded, frequenzaSel, (v) => setDialogState((){ frequenzaSel = v; isTendinaFrequenzaAperta = false;})),
                      ],
                    ],
                  ),
                ),

                if (richiedeMese) ...[
                  const SizedBox(height: 12),
                  Text(
                    frequenzaSel == '12_mesi' ? 'MESE DI SCADENZA' : 'MESE DEL PRIMO PAGAMENTO', 
                    style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isTendinaMeseAperta ? Colors.white54 : Colors.white12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setDialogState(() => isTendinaMeseAperta = !isTendinaMeseAperta),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 16),
                                    const SizedBox(width: 10),
                                    Text('Selezionato: $meseTargetSel', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Icon(isTendinaMeseAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (isTendinaMeseAperta) ...[
                          const Divider(color: Colors.white12, height: 1),
                          Wrap(
                            spacing: 4, runSpacing: 4,
                            children: _nomiMesiBrevi.map((m) {
                              final isSelected = m == meseTargetSel;
                              return ChoiceChip(
                                label: Text(m, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                selectedColor: Colors.white24,
                                backgroundColor: Colors.transparent,
                                onSelected: (_) => setDialogState((){ meseTargetSel = m; isTendinaMeseAperta = false; }),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],

                if (frequenzaSel == '12_mesi' && importoVal > 0) ...[
                  const SizedBox(height: 12),
                  const Text('COME VUOI GESTIRLA NEL BUDGET?', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: const Color(0xFF2DD4BF),
                    title: const Text('Spalta su 12 mesi', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    subtitle: Text('Accantoni ${_formattaValuta(importoVal / 12)} al mese nel budget', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    value: 'spalmata_12',
                    groupValue: modalitaAnnualeSel,
                    onChanged: (val) => setDialogState(() => modalitaAnnualeSel = val!),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: const Color(0xFF2DD4BF),
                    title: const Text('Addebito Unico', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    subtitle: Text('0 € nei mesi ordinari, intera cifra a $meseTargetSel', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    value: 'addebito_unico',
                    groupValue: modalitaAnnualeSel,
                    onChanged: (val) => setDialogState(() => modalitaAnnualeSel = val!),
                  ),
                ],

                const SizedBox(height: 16),

                const Text('IN CHE CATEGORIA RIENTRA?', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isTendinaRegolaAperta ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setDialogState(() => isTendinaRegolaAperta = !isTendinaRegolaAperta),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.pie_chart_outline_rounded, color: categoriaSel == '50' ? _colorBisogni : (categoriaSel == '30' ? _colorSvago : _colorRisparmio), size: 16),
                                  const SizedBox(width: 10),
                                  Text(nomeRegola, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Icon(isTendinaRegolaAperta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF2DD4BF), size: 18),
                            ],
                          ),
                        ),
                      ),
                      if (isTendinaRegolaAperta) ...[
                        const Divider(color: Colors.white12, height: 1),
                        _buildOptionRegola('50', 'Spese Fisse & Bisogni (50%)', _colorBisogni, categoriaSel, (val) => setDialogState((){ categoriaSel = val; isTendinaRegolaAperta = false; })),
                        _buildOptionRegola('30', 'Spese Variabili & Tempo Libero (30%)', _colorSvago, categoriaSel, (val) => setDialogState((){ categoriaSel = val; isTendinaRegolaAperta = false; })),
                        _buildOptionRegola('20', 'Risparmi & Futuro (20%)', _colorRisparmio, categoriaSel, (val) => setDialogState((){ categoriaSel = val; isTendinaRegolaAperta = false; })),
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

  Widget _buildOptionFreq(String valKey, String label, IconData icon, String currentSel, Function(String) onSelect) {
    final bool isSelected = valKey == currentSel;
    return InkWell(
      onTap: () => onSelect(valKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white38, size: 15),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
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

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Regola di Budget',
      testoConferma: 'Salva Regola',
      onConferma: () {
        final int totale = (tempBisogni + tempSvago + tempRisparmio).round();
        if (totale == 100) {
          setState(() {
            _percentBisogni = tempBisogni;
            _percentSvago = tempSvago;
            _percentRisparmio = tempRisparmio;
          });
          Navigator.pop(context);
        } else {
          AppNotifications.mostraInAlto(context, 'La somma deve fare 100%!', type: NotificationType.warning);
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
                const Text('Adatta le percentuali al tuo stile di vita. Le entrate di riferimento sono calcolate in automatico dal tuo profilo fiscale.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
                const SizedBox(height: 18),
                Text('Spese Fisse & Bisogni: ${tempBisogni.toInt()}%', style: const TextStyle(color: _colorBisogni, fontWeight: FontWeight.bold, fontSize: 11)),
                Slider(value: tempBisogni, min: 10, max: 80, divisions: 14, activeColor: _colorBisogni, onChanged: (val) => setDialogState(() => tempBisogni = val)),
                Text('Spese Variabili & Tempo Libero: ${tempSvago.toInt()}%', style: const TextStyle(color: _colorSvago, fontWeight: FontWeight.bold, fontSize: 11)),
                Slider(value: tempSvago, min: 10, max: 80, divisions: 14, activeColor: _colorSvago, onChanged: (val) => setDialogState(() => tempSvago = val)),
                Text('Risparmi & Futuro: ${tempRisparmio.toInt()}%', style: const TextStyle(color: _colorRisparmio, fontWeight: FontWeight.bold, fontSize: 11)),
                Slider(value: tempRisparmio, min: 0, max: 50, divisions: 10, activeColor: _colorRisparmio, onChanged: (val) => setDialogState(() => tempRisparmio = val)),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Totale Ripartizione: $totaleCorrente%',
                    style: TextStyle(color: eValido ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
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
    final vociPianificate = walletProvider.vociPianificate; 
    final stringaMeseCorrente = _stringaMeseAnno(_meseSelezionato);

    final verdetto = walletProvider.calcolaVerdettoFiscale();
    double entrateMensili = verdetto['stipendioMensile12Mesi'] ?? 0.0;
    if (entrateMensili <= 0) entrateMensili = walletProvider.nettoTargetMensile;
    if (entrateMensili <= 0) entrateMensili = 2500.0;

    final double targetBisogni = (entrateMensili * _percentBisogni) / 100;
    final double targetSvago = (entrateMensili * _percentSvago) / 100;
    final double targetRisparmio = (entrateMensili * _percentRisparmio) / 100;

    double pianificatoBisogni = vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').fold(0.0, (sum, v) => sum + _getPrevistoPerMese(v, _meseSelezionato));
    double pianificatoSvago = vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').fold(0.0, (sum, v) => sum + _getPrevistoPerMese(v, _meseSelezionato));
    double pianificatoRisparmio = vociPianificate.where((v) => v['categoria'] == 'Risparmio (20%)').fold(0.0, (sum, v) => sum + _getPrevistoPerMese(v, _meseSelezionato));

    double spesoBisogni = 0;
    double spesoSvago = 0;
    double spesoRisparmio = 0;

    for (var v in vociPianificate) {
      final double spesoReale = _calcolaSpesoReale(walletProvider, v['nome'], v['sottocategoria'] ?? '');
      if (v['categoria'] == 'Bisogni (50%)') spesoBisogni += spesoReale;
      if (v['categoria'] == 'Svago (30%)') spesoSvago += spesoReale;
      if (v['categoria'] == 'Risparmio (20%)') spesoRisparmio += spesoReale;
    }

    return AppBottomSheet(
      title: 'Pianificazione Spese',
      badgeText: 'Wallet',
      badgeColor: const Color(0xFF2DD4BF),
      child: Container(
        height: screenHeight * 0.55, 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      InkWell(onTap: () => _cambiaMese(-1), child: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 18)),
                      const SizedBox(width: 8),
                      Text(stringaMeseCorrente.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      InkWell(onTap: () => _cambiaMese(1), child: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (vociPianificate.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _azzeraPianificazione(walletProvider),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3))),
                          child: const Icon(Icons.restart_alt_rounded, color: Color(0xFFEF4444), size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    InkWell(
                      onTap: _mostraDialogAggiungiSpesa,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF2DD4BF).withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4))),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Color(0xFF2DD4BF), size: 14),
                            SizedBox(width: 4),
                            Text('Spesa', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BUDGET MENSILE NETTO
            InkWell(
              onTap: _mostraDialogModificaRegola,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('BUDGET MENSILE NETTO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        Text('+ ${_formattaInt(entrateMensili)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          Expanded(flex: _percentBisogni.toInt(), child: Container(height: 6, color: _colorBisogni)),
                          Expanded(flex: _percentSvago.toInt(), child: Container(height: 6, color: _colorSvago)),
                          Expanded(flex: _percentRisparmio.toInt(), child: Container(height: 6, color: _colorRisparmio)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTargetEuroText('Bisogni (${_percentBisogni.toInt()}%)', targetBisogni, _colorBisogni),
                        _buildTargetEuroText('Svago (${_percentSvago.toInt()}%)', targetSvago, _colorSvago),
                        _buildTargetEuroText('Risparmio (${_percentRisparmio.toInt()}%)', targetRisparmio, _colorRisparmio),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // LISTA CATEGORIE E ROADMAP
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryCardPulita(
                      provider: walletProvider, categoriaKey: '50', title: 'Spese Fisse & Bisogni', icon: Icons.home_rounded, targetEuro: targetBisogni,
                      pianificatoTotale: pianificatoBisogni, spesoRealeTotale: spesoBisogni, color: _colorBisogni, 
                      voci: vociPianificate.where((v) => v['categoria'] == 'Bisogni (50%)').toList(),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCardPulita(
                      provider: walletProvider, categoriaKey: '30', title: 'Spese Variabili & Tempo Libero', icon: Icons.explore_rounded, targetEuro: targetSvago,
                      pianificatoTotale: pianificatoSvago, spesoRealeTotale: spesoSvago, color: _colorSvago, 
                      voci: vociPianificate.where((v) => v['categoria'] == 'Svago (30%)').toList(),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCardPulita(
                      provider: walletProvider, categoriaKey: '20', title: 'Risparmi & Futuro', icon: Icons.trending_up_rounded, targetEuro: targetRisparmio,
                      pianificatoTotale: pianificatoRisparmio, spesoRealeTotale: spesoRisparmio, color: _colorRisparmio, 
                      voci: vociPianificate.where((v) => v['categoria'] == 'Risparmio (20%)').toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 🌟 SWITCH AUTOMATICO PRO O FREE 🌟
                    _buildRoadmapSection(walletProvider),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetEuroText(String label, double importo, Color colore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colore.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(_formattaInt(importo), style: TextStyle(color: colore, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRoadmapSection(WalletProvider provider) {
    if (provider.isProUser) {
      return _buildActiveRoadmap(provider);
    } else {
      return _buildTeaserRoadmapPRO(provider);
    }
  }

  // 🚀 PROPOSTA #1: BARRE IMPILATE A 3 COLORI (BISOGNI / SVAGO / RISPARMIO)
  Widget _buildActiveRoadmap(WalletProvider provider) {
    final DateTime dataAttualeReale = DateTime.now();
    final List<DateTime> prossimiMesi = List.generate(12, (i) => DateTime(dataAttualeReale.year, dataAttualeReale.month + i));

    // Trova il mese con la spesa totale massima per calcolare le altezze proporzionali delle barre
    double maxSpesaAnno = 0;
    for (var m in prossimiMesi) {
      double totMese = 0;
      for (var v in provider.vociPianificate) {
        totMese += _getPrevistoPerMese(v, m);
      }
      if (totMese > maxSpesaAnno) maxSpesaAnno = totMese;
    }
    if (maxSpesaAnno == 0) maxSpesaAnno = 1000; // Fallback visivo

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: Color(0xFF2DD4BF), size: 18),
                SizedBox(width: 8),
                Text('ANALISI ANNUALE PER CATEGORIA', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
              ),
              child: const Text('PRO ATTIVO', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Grafico scorrevole a barre impilate
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: prossimiMesi.map((meseTarget) {
              final bool isSelected = meseTarget.year == _meseSelezionato.year && meseTarget.month == _meseSelezionato.month;

              // Calcola il peso di ogni singola categoria per il mese corrente
              double pBisogni = 0;
              double pSvago = 0;
              double pRisparmio = 0;

              for (var v in provider.vociPianificate) {
                double prev = _getPrevistoPerMese(v, meseTarget);
                if (v['categoria'] == 'Bisogni (50%)') pBisogni += prev;
                if (v['categoria'] == 'Svago (30%)') pSvago += prev;
                if (v['categoria'] == 'Risparmio (20%)') pRisparmio += prev;
              }

              double totaleMese = pBisogni + pSvago + pRisparmio;
              // Altezza della colonna proporzionale al massimo dell'anno (min 20px, max 90px)
              double altezzaBarra = (totaleMese / maxSpesaAnno * 70).clamp(10.0, 70.0);

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _meseSelezionato = meseTarget;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2DD4BF).withOpacity(0.12) : const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2DD4BF) : Colors.white12,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Cifra totale mese
                        Text(
                          _formattaInt(totaleMese),
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // BARRA IMPILATA A 3 COLORI
                        Container(
                          width: 24,
                          height: altezzaBarra,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white10,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Column(
                              children: [
                                // Svago (Ambra) in alto
                                if (totaleMese > 0)
                                  Expanded(
                                    flex: (pSvago * 100).round() + 1,
                                    child: Container(color: _colorSvago),
                                  ),
                                // Bisogni (Celeste) al centro
                                if (totaleMese > 0)
                                  Expanded(
                                    flex: (pBisogni * 100).round() + 1,
                                    child: Container(color: _colorBisogni),
                                  ),
                                // Risparmio (Viola) in basso
                                if (totaleMese > 0)
                                  Expanded(
                                    flex: (pRisparmio * 100).round() + 1,
                                    child: Container(color: _colorRisparmio),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        // Nome Mese
                        Text(
                          _nomiMesiBrevi[meseTarget.month - 1],
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 🔮 ROADMAP BLOCCATA (TEASER PER GLI UTENTI FREE)
  Widget _buildTeaserRoadmapPRO(WalletProvider provider) {
    final DateTime oggi = DateTime.now();
    final List<Map<String, dynamic>> mappaMesi = [];
    double piccoMassimo = 0.0;
    String mesePiccoNome = '';

    for (int i = 1; i <= 6; i++) {
      final meseFuturo = DateTime(oggi.year, oggi.month + i);
      double totaleMese = 0;
      for (var v in provider.vociPianificate) {
        totaleMese += _getPrevistoPerMese(v, meseFuturo);
      }
      if (totaleMese > piccoMassimo) {
        piccoMassimo = totaleMese;
        mesePiccoNome = _nomiMesiBrevi[meseFuturo.month - 1];
      }
      mappaMesi.add({
        'nome': _nomiMesiBrevi[meseFuturo.month - 1],
        'totale': totaleMese,
      });
    }

    final bool usaDatiFinti = piccoMassimo == 0;
    if (usaDatiFinti) {
      piccoMassimo = 1000;
      mesePiccoNome = _nomiMesiBrevi[DateTime(oggi.year, oggi.month + 3).month - 1];
      mappaMesi.clear();
      for (int i = 1; i <= 6; i++) {
        mappaMesi.add({
          'nome': _nomiMesiBrevi[DateTime(oggi.year, oggi.month + i).month - 1],
          'totale': i == 3 ? 1000.0 : (i % 2 == 0 ? 300.0 : 500.0),
        });
      }
    }

    return InkWell(
      onTap: () {
        HapticFeedback.heavyImpact();
        AppNotifications.mostraInAlto(context, 'Passa al piano PRO per sbloccare la Roadmap!');
      },
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 60, left: 16, right: 16, bottom: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: mappaMesi.map((mese) {
                    final double altezzaRelativa = (mese['totale'] / piccoMassimo).clamp(0.1, 1.0);
                    Color coloreSfera = const Color(0xFF38BDF8);
                    if (altezzaRelativa > 0.6) coloreSfera = const Color(0xFFF59E0B);
                    if (altezzaRelativa > 0.85) coloreSfera = const Color(0xFFEF4444);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 12 + (altezzaRelativa * 12),
                          height: 12 + (altezzaRelativa * 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: coloreSfera,
                            boxShadow: [
                              BoxShadow(color: coloreSfera.withOpacity(0.6), blurRadius: 15, spreadRadius: 2 + (altezzaRelativa * 5))
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(mese['nome'], style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    );
                  }).toList(),
                ),
              ),

              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.65), Colors.black.withOpacity(0.35)],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route_rounded, color: Color(0xFF2DD4BF), size: 18),
                        const SizedBox(width: 8),
                        const Text('Roadmap Annuale', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(6)),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_rounded, color: Colors.black, size: 10),
                              SizedBox(width: 4),
                              Text('PRO', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
                        children: [
                          const TextSpan(text: 'Abbiamo simulato il tuo piano finanziario. '),
                          if (!usaDatiFinti) ...[
                            const TextSpan(text: 'Il tuo prossimo grande picco di uscite sarà a '),
                            TextSpan(text: '$mesePiccoNome. ', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                          ],
                          const TextSpan(text: 'Sblocca la mappa temporale per prepararti in anticipo ai mesi più difficili.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Esplora Roadmap', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Color(0xFF2DD4BF), size: 14),
                          ],
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

  Widget _buildCategoryCardPulita({
    required WalletProvider provider, required String categoriaKey, required String title, required IconData icon, 
    required double targetEuro, required double pianificatoTotale, required double spesoRealeTotale, 
    required Color color, required List<Map<String, dynamic>> voci,
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
                if (isEspansa) _categorieEspanse.remove(categoriaKey);
                else _categorieEspanse.add(categoriaKey);
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Limite Consigliato: ${_formattaInt(targetEuro)}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                        ],
                      ),
                      const Spacer(),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formattaInt(spesoRealeTotale),
                            style: TextStyle(color: isSforato ? const Color(0xFFEF4444) : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' / ${_formattaInt(pianificatoTotale)}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(isEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 18),
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
                children: voci.map((v) => _buildVoceTilePulita(provider, v, color)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoceTilePulita(WalletProvider provider, Map<String, dynamic> v, Color colorCategoria) {
    final double previstoNelMese = _getPrevistoPerMese(v, _meseSelezionato);
    final double spesoReale = _calcolaSpesoReale(provider, v['nome'], v['sottocategoria'] ?? '');
    final String tipo = v['tipo'] ?? 'mensile';
    final String? meseScadenza = v['meseScadenza'];

    final double differenza = spesoReale - previstoNelMese;
    final bool isSforato = differenza > 0.01 && previstoNelMese > 0;
    final bool isSaldata = spesoReale >= previstoNelMese && previstoNelMese > 0;
    final bool isPausaInQuestoMese = previstoNelMese == 0 && spesoReale == 0;

    if (_filtroVisualizzazione == 'da_saldare' && (isSaldata || isPausaInQuestoMese)) {
      return const SizedBox.shrink();
    }

    Widget badgeStato;
    Color coloreImporto = Colors.white;

    if (isPausaInQuestoMese) {
      badgeStato = _buildBadgeTag('In Pausa a ${_nomiMesiBrevi[_meseSelezionato.month - 1]}', Colors.white38, null);
      coloreImporto = Colors.white38;
    } else if (tipo == 'annuale_spalmata') {
      final String etichetta = meseScadenza != null ? 'Accantonata • Scade a $meseScadenza' : 'Accantonata';
      badgeStato = _buildBadgeTag(etichetta, _colorRisparmio, Icons.savings_rounded);
      coloreImporto = _colorRisparmio;
    } else if (isSforato) {
      badgeStato = _buildBadgeTag('+${_formattaInt(differenza)} Fuori Budget', const Color(0xFFEF4444), Icons.warning_amber_rounded);
      coloreImporto = const Color(0xFFEF4444);
    } else if (isSaldata) {
      badgeStato = _buildBadgeTag('Saldata', const Color(0xFF10B981), Icons.check_circle_rounded);
      coloreImporto = const Color(0xFF10B981);
    } else {
      badgeStato = _buildBadgeTag('In Attesa', _colorSvago, Icons.hourglass_bottom_rounded);
      coloreImporto = _colorSvago;
    }

    final IconData iconaVoce = _getIconaVoce(v['nome'], v['sottocategoria']);

    return Opacity(
      opacity: isPausaInQuestoMese ? 0.4 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () => _gestisciSpesaDialog(v),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSforato ? const Color(0xFFEF4444).withOpacity(0.4) : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colorCategoria.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconaVoce, color: colorCategoria, size: 16),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['nome'], 
                        style: TextStyle(
                          color: isPausaInQuestoMese ? Colors.white54 : Colors.white, 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 4),
                      badgeStato,
                    ],
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(_formattaInt(spesoReale), style: TextStyle(color: coloreImporto, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(' / ${_formattaInt(previstoNelMese)}', style: TextStyle(color: isPausaInQuestoMese ? Colors.white24 : Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeTag(String text, Color color, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 9),
            const SizedBox(width: 3),
          ],
          Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}