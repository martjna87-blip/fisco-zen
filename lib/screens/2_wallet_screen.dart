import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '2_1_wallet_add_movement.dart';
import '2_2_wallet_manage_accounts.dart';
import '2_5_wallet_annual_summary.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/serbatoio_tasse_widget.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '2_4_wallet_budget_pilot_v2.dart';
import '../widgets_shared/fiscon_logo.dart';
import '../widgets_shared/app_secondary_popup.dart';
import '../widgets_shared/app_action_card.dart';
import '../data/recurrence_manager.dart';
import '0_1_pro_upgrade.dart';

class WalletScreen extends StatefulWidget {
  final bool isPiva;

  const WalletScreen({super.key, this.isPiva = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _filtroMeseMovimenti = 'ultimi_5';
  bool _isFiltroMovimentiAperto = false;

  final Color oceanCyan   = const Color(0xFF38BDF8); 
  final Color goldAccent  = const Color(0xFFFBBF24); 
  final Color purpleZen   = const Color(0xFFC084FC); 
  final Color taxBlue     = const Color(0xFF60A5FA); 

  int _testIndex = 0;

  final List<String> _sfondiSettimanali = [
    'https://images.unsplash.com/photo-1505413687799-90481dfc0203?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fG1hcmV8ZW58MHx8MHx8fDA%3D',
    'https://images.unsplash.com/photo-1555412654-72a95a495858?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YWNxdWF8ZW58MHx8MHx8fDA%3D',
    'https://plus.unsplash.com/premium_photo-1674517879286-0ee281fc5262?w=700&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDR8fHxlbnwwfHx8fHw%3D',
    'https://images.unsplash.com/photo-1481819613568-3701cbc70156?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8cGlhbmV0aXxlbnwwfHwwfHx8MA%3D%3D',
    'https://plus.unsplash.com/premium_photo-1711434824963-ca894373272e?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8bmF0dXJhfGVufDB8fDB8fHww',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8bmF0dXJhfGVufDB8fDB8fHww',
  ];

  bool _isBussolaEspansa = false;
  bool _isTargetEspanso = false;
  DateTime _dataFiltroRipartizione = DateTime(2026, 8);
  bool _isVistaAnnuale = false;

  final List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
  ];

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  String _formattaInt(double importo) {
    final int intVal = importo.round();
    final String segno = intVal < 0 ? '-' : ''; // 👈 Controlla se è negativo
    final strVal = intVal.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$segno$strVal €'; // 👈 Riapplica il segno
  }

  void _cambiaPeriodoRipartizione(int delta) {
    setState(() {
      if (_isVistaAnnuale) {
        _dataFiltroRipartizione = DateTime(_dataFiltroRipartizione.year + delta, _dataFiltroRipartizione.month);
      } else {
        _dataFiltroRipartizione = DateTime(_dataFiltroRipartizione.year, _dataFiltroRipartizione.month + delta);
      }
    });
  }

  Widget _buildCustomSelectorMovimenti() {
    final Map<String, String> opzioni = {
      'ultimi_5': 'Ultimi 5 Movimenti',
      'ricorrenti': '🔄 Solo Ricorrenti',
      '8_2026': 'Agosto 2026',
      '7_2026': 'Luglio 2026',
      '6_2026': 'Giugno 2026',
      '5_2026': 'Maggio 2026',
    };

    final String etichettaCorrente = opzioni[_filtroMeseMovimenti] ?? 'Ultimi 5 Movimenti';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12161A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: oceanCyan.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isFiltroMovimentiAperto = !_isFiltroMovimentiAperto),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _filtroMeseMovimenti == 'ricorrenti' ? Icons.sync_rounded : Icons.filter_alt_rounded,
                    color: oceanCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      etichettaCorrente,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    _isFiltroMovimentiAperto ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isFiltroMovimentiAperto) ...[
            Divider(color: oceanCyan.withOpacity(0.2), height: 1),
            Column(
              children: opzioni.entries.map((entry) {
                final bool isSelected = _filtroMeseMovimenti == entry.key;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _filtroMeseMovimenti = entry.key;
                      _isFiltroMovimentiAperto = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isSelected ? oceanCyan.withOpacity(0.12) : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? oceanCyan : Colors.white24,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetECuscinettoGlass({required WalletProvider walletProvider}) {
    final double target = walletProvider.nettoTargetMensile;
    if (target <= 0) return const SizedBox.shrink();

    final DateTime ora = DateTime.now();
    final int meseCorrenteIndex = ora.month - 1;
    
    final double incassatoPivaMese = walletProvider.transactions.where((tx) {
      return tx.isIncome &&
             tx.date.year == ora.year &&
             tx.date.month == ora.month &&
             (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso'));
    }).fold(0.0, (sum, tx) => sum + tx.amount);

    final double stipendioRegistratoMese = walletProvider.transactions.where((tx) {
      return tx.isIncome &&
             tx.date.year == ora.year &&
             tx.date.month == ora.month &&
             tx.category != 'P.IVA' &&
             !tx.title.toLowerCase().contains('incasso') &&
             !tx.category.toLowerCase().contains('giroconto');
    }).fold(0.0, (sum, tx) => sum + tx.amount);

    final double nettoExtraMese = stipendioRegistratoMese > 0 
        ? stipendioRegistratoMese 
        : walletProvider.entrataExtraMensile;

    final bool isMeseLavorativo = walletProvider.mesiAttiviState.length > meseCorrenteIndex
        ? walletProvider.mesiAttiviState[meseCorrenteIndex]
        : true;

    double nettoPivaIncassato = 0.0;

    if (isMeseLavorativo) {
      final double fattoreMesiAttivi = (walletProvider.mesiAttivi / 12).clamp(0.0, 1.0);
      nettoPivaIncassato = incassatoPivaMese * (1 - walletProvider.aliquotaFiscaleReale) * fattoreMesiAttivi;
    } else {
      final double quotaCuscinettoMensile = (target - nettoExtraMese).clamp(0.0, double.infinity);
      nettoPivaIncassato = quotaCuscinettoMensile;
    }

    final double nettoRealizzatoMese = (walletProvider.isPartitaIVA ? nettoPivaIncassato : 0.0) + nettoExtraMese;

    final double gap = target - nettoRealizzatoMese;
    final bool isCoperto = gap <= 0;
    final double percentuale = (nettoRealizzatoMese / target).clamp(0.0, 1.0);
    final int mesiOff = 12 - walletProvider.mesiAttivi;

    final Color statusColor = isCoperto ? oceanCyan : const Color(0xFFF97316);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isTargetEspanso = !_isTargetEspanso),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCoperto ? Icons.flag_rounded : Icons.track_changes_rounded,
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Obiettivo Target Netto',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isTargetEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCoperto ? '100% OK' : 'Mancano ${_formattaInt(gap)}',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            if (_isTargetEspanso) ...[
              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 8,
                  color: Colors.white.withOpacity(0.1),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentuale,
                    child: Container(color: statusColor),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NETTO REALIZZATO (MESE)',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formattaInt(nettoRealizzatoMese),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TARGET DESIDERATO',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formattaInt(target),
                        style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),

              if (mesiOff > 0) ...[
                const SizedBox(height: 14),
                Divider(color: Colors.white.withOpacity(0.08), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.beach_access_rounded, color: oceanCyan, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMeseLavorativo
                            ? 'Cuscinetto Mesi OFF: $mesiOff mesi di pausa previsti (in accantonamento)'
                            : 'Cuscinetto Mesi OFF: Mese di pausa in corso (quota erogata)',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _mostraAlertConfermaEliminazioneTotale(BuildContext context, String id, String desc) {
    showDialog(
      context: context,
      builder: (ctxAlert) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('⚠️ ELIMINAZIONE TOTALE', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Sei sicuro di voler eliminare TUTTI i movimenti di "$desc"?\n\n🚨 Verrà cancellato anche lo STORICO PASSATO nei mesi precedenti. L\'operazione è irreversibile.',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctxAlert),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              context.read<WalletProvider>().deleteTransaction(id);
              Navigator.pop(ctxAlert);
              setState(() {});
              AppNotifications.mostraInAlto(
                context,
                'Intera serie di "$desc" eliminata (compreso lo storico passato)',
                type: NotificationType.error,
              );
            },
            child: const Text('SÌ, ELIMINA TUTTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _gestisciEliminazioneMovimento(BuildContext context, dynamic tx) {
    final String catLower = (tx.category ?? '').toString().toLowerCase();
    final String titleLower = (tx.title ?? '').toString().toLowerCase();
    final bool isFatturaPiva = catLower == 'p.iva' || titleLower.startsWith('incasso:') || titleLower.startsWith('fattura');

    if (isFatturaPiva) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 22),
              SizedBox(width: 8),
              Text('Fattura P.IVA Protetta', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Gli incassi delle fatture P.IVA regolano l\'accantonamento delle tasse e non possono essere eliminati dai movimenti comuni.\n\nPer annullare o gestire questa fattura, utilizza la sezione Gestione P.IVA.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Chiudi', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
      return;
    }

    final bool isRecurrent = tx.isRecurrent ?? false;
    final provider = context.read<WalletProvider>();

    // 🔒 GUARDRAIL DEMO/FREE: SE L'UTENTE NON È PRO APRE IL PAYWALL
    if (isRecurrent && !provider.isProUser) {
      AppBottomSheet.mostra(
        context: context,
        child: const ProUpgradeSheet(funzionalita: 'Gestione Ricorrenze'),
      );
      return;
    }

    final String desc = tx.title ?? 'Movimento';
    final String id = tx.id as String;
    final DateTime date = tx.date as DateTime;

    if (!isRecurrent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Text('Elimina Movimento', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Vuoi davvero eliminare "$desc"?\nIl saldo del conto verrà aggiornato.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                provider.deleteTransaction(id);
                Navigator.pop(ctx);
                setState(() {});
                AppNotifications.mostraInAlto(context, 'Movimento "$desc" eliminato 🎉');
              },
              child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // 🎯 MODALE RICORRENZA IDENTICA A 2.1 CON APPACTIONCARD
    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.event_repeat_rounded,
        iconColor: const Color(0xFF38BDF8),
        titolo: 'Gestisci Ricorrenza',
        testoAnnulla: 'Chiudi',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scegli come modificare la spesa/entrata per "$desc":',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // 1️⃣ ELIMINA SOLO QUESTO MESE
              AppActionCard(
                icon: Icons.event_busy_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Elimina solo per questo mese',
                subtitle: 'Cancella la singola registrazione. La spesa tornerà regolarmente il mese prossimo.',
                onTap: () {
                  provider.eliminaSoloQuestoMese(id, date);
                  Navigator.pop(ctx);
                  setState(() {});
                  AppNotifications.mostraInAlto(context, 'Movimento eliminato solo per questo mese 🎉');
                },
              ),
              const SizedBox(height: 10),

              // 2️⃣ ELIMINA QUESTO E I FUTURI
              AppActionCard(
                icon: Icons.block_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Elimina questo e i futuri',
                subtitle: 'Rimborsa questo mese e blocca la spesa per il futuro. Lo storico passato è salvo.',
                onTap: () {
                  provider.eliminaQuestoEFuturi(id, date);
                  Navigator.pop(ctx);
                  setState(() {});
                  AppNotifications.mostraInAlto(
                    context,
                    'Spesa interrotta da questo mese in poi! Storico passato salvato.',
                    type: NotificationType.warning,
                  );
                },
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 14),

              // 3️⃣ ELIMINA L'INTERA SERIE
              AppActionCard(
                icon: Icons.delete_forever_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Elimina l\'intera serie',
                subtitle: 'Cancella la regola e lo storico passato nei mesi precedenti. Irreversibile.',
                isDanger: true,
                onTap: () {
                  Navigator.pop(ctx);
                  final rootId = RecurrenceManager.getRootId(id);
                  _mostraAlertConfermaEliminazioneTotale(context, rootId, desc);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostraMovimentiConto(BuildContext context, dynamic acc) {
    AppBottomSheet.mostra(
      context: context,
      child: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final txsConto = walletProvider.transactions
              .where((tx) => tx.accountId == acc.id)
              .toList();
              
          txsConto.sort((a, b) => b.date.compareTo(a.date));

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (acc.color as Color).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: acc.color as Color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Movimenti: ${acc.title}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              acc.subtitle as String,
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (txsConto.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Nessun movimento registrato per questo conto.',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...txsConto.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final tx = entry.value;
                      final bool isIncome = tx.isIncome;
                      final Color color = isIncome ? oceanCyan : const Color(0xFFF43F5E);
                      final String sign = isIncome ? '+' : '-';
                      final String dateStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}';

                      return Dismissible(
                        key: Key('modal_dismiss_${tx.id}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                        ),
                        confirmDismiss: (direction) async {
                          _gestisciEliminazioneMovimento(context, tx);
                          return false; 
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: color,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            tx.title,
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (tx.isRecurrent ?? false) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.sync_rounded, color: oceanCyan.withOpacity(0.8), size: 13),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$dateStr • ${tx.category}',
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$sign${_formattaValuta(tx.amount)}',
                                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentBackgroundUrl = _sfondiSettimanali[_testIndex % _sfondiSettimanali.length];

    final double topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    final walletProvider = context.watch<WalletProvider>();
    final patrimonioNetto = walletProvider.patrimonioNetto;
    final movimenti = walletProvider.transactions.where((t) => !t.id.startsWith('rule_')).toList();
    final bool mostraPiva = widget.isPiva || walletProvider.isPartitaIVA;

    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    final double tasseDaAccantonare = walletProvider.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double residuoTasseDaCoprire = tasseDaAccantonare;

    final double sommaContiLiquidi = walletProvider.accounts
        .where((a) => !a.title.toLowerCase().contains('salvadanaio tasse') && !a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double postTasse = (sommaContiLiquidi - tasseDaAccantonare).clamp(0.0, double.infinity);
    final double cuscinettoFerie = walletProvider.cuscinettoResiduo;
    final double nettoRealeSpendibile = (postTasse - cuscinettoFerie).clamp(0.0, double.infinity);
    
    final bool isTasseCoperte = residuoTasseDaCoprire <= 0.01;

    final txsFiltrate = movimenti.where((tx) {
      if (tx.isIncome) return false;
      if (tx.category == 'Giroconto' || tx.title.toLowerCase().contains('giroconto')) return false;

      if (_isVistaAnnuale) {
        return tx.date.year == _dataFiltroRipartizione.year;
      } else {
        return tx.date.year == _dataFiltroRipartizione.year &&
               tx.date.month == _dataFiltroRipartizione.month;
      }
    }).toList();

    double spesoRealeBisogni = 0;
    double spesoRealeSvago = 0;
    double spesoRealeRisparmio = 0;

    for (var tx in txsFiltrate) {
      final bussola = walletProvider.ottieniBussolaSemplificata(tx);
      if (bussola == 'Svago') {
        spesoRealeSvago += tx.amount;
      } else if (bussola == 'Risparmi') {
        spesoRealeRisparmio += tx.amount;
      } else {
        spesoRealeBisogni += tx.amount;
      }
    }

    final double totaleSpeseReali = spesoRealeBisogni + spesoRealeSvago + spesoRealeRisparmio;

    final double entratePeriodo = movimenti.where((tx) {
      if (!tx.isIncome) return false;
      final titleLower = tx.title.toLowerCase();
      final catLower = tx.category.toLowerCase();

      if (catLower == 'giroconto' ||
          titleLower.contains('giroconto') ||
          titleLower.contains('saldo iniziale') ||
          catLower == 'risparmi') return false;

      if (_isVistaAnnuale) {
        return tx.date.year == _dataFiltroRipartizione.year;
      } else {
        return tx.date.year == _dataFiltroRipartizione.year &&
               tx.date.month == _dataFiltroRipartizione.month;
      }
    }).fold(0.0, (sum, tx) => sum + tx.amount);

    final double targetBase = _isVistaAnnuale ? (walletProvider.nettoTargetMensile * 12) : walletProvider.nettoTargetMensile;
    final double entrateRiferimento = entratePeriodo; 

    final double basePerTarget = entratePeriodo > targetBase ? entratePeriodo : (targetBase > 0 ? targetBase : 2500.0);
    final double targetBisogni = basePerTarget * 0.50;
    final double targetSvago = basePerTarget * 0.30;
    final double targetRisparmio = basePerTarget * 0.20;

    final List<dynamic> movimentiFiltrati = (() {
      final lista = List.from(movimenti);
      lista.sort((a, b) => b.date.compareTo(a.date));

      if (_filtroMeseMovimenti == 'ultimi_5') {
        return lista.take(5).toList();
      } else if (_filtroMeseMovimenti == 'ricorrenti') {
        final Map<String, dynamic> uniciRicorrenti = {};
        for (var tx in lista.where((t) => (t.isRecurrent ?? false) == true)) {
          final String chiaveUnica = (tx.title ?? '').toString().toLowerCase().trim();
          if (!uniciRicorrenti.containsKey(chiaveUnica)) {
            uniciRicorrenti[chiaveUnica] = tx;
          }
        }
        return uniciRicorrenti.values.toList();
      } else {
        final parts = _filtroMeseMovimenti.split('_');
        final m = int.tryParse(parts[0]) ?? 8;
        final y = int.tryParse(parts[1]) ?? 2026;
        return lista.where((tx) => tx.date.month == m && tx.date.year == y).toList();
      }
    })();

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.75,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _testIndex++;
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  key: ValueKey<String>(currentBackgroundUrl),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(currentBackgroundUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.99),
                          Colors.black.withOpacity(0.4),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 16, left: 20, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _testIndex++;
                          });
                        },
                        child: const FiscOnLogo(fontSize: 22, sottotitolo: 'Portafoglio Personale'),
                      ),
                      
                      _buildGlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => AppBottomSheet.mostra(context: context, child: const AnnualSummarySheet()),
                          child: Row(
                            children: [
                              Icon(Icons.show_chart_rounded, size: 14, color: oceanCyan),
                              const SizedBox(width: 6),
                              const Text('RIEPILOGO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 45),

                Center(
                  child: InkWell(
                    onLongPress: () {
                      AppPopupWrapper.mostraInfo(
                        context: context,
                        icon: Icons.account_balance_rounded,
                        color: Colors.white,
                        titolo: 'Patrimonio globale',
                        descrizione: 'Somma totale dei saldi di tutti i tuoi conti correnti e del salvadanaio tasse.',
                      );
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        Text(
                          'PATRIMONIO GLOBALE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formattaInt(patrimonioNetto),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2.0,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 4))],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                if (mostraPiva)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 16),
                        _buildGlassBadge(
                          icon: Icons.payments_rounded,
                          color: oceanCyan,
                          value: _formattaInt(nettoRealeSpendibile),
                          onTap: () {},
                          onLongPress: () {
                            AppPopupWrapper.mostraInfo(
                              context: context,
                              icon: Icons.payments_rounded,
                              color: oceanCyan,
                              titolo: 'Netto Reale Spendibile',
                              descrizione:
                                  'È la liquidità che puoi spendere in totale serenità. '
                                  'Calcolata sottraendo al tuo patrimonio totale le tasse stimate e la quota accantonata per i tuoi mesi di pausa/ferie (${walletProvider.mesiAttivi} mesi lavorativi su 12).',
                              formula:
                                  '💰 Patrimonio Totale: ${_formattaInt(patrimonioNetto)}\n'
                                  '🛡️ Riserva Tasse Totale: -${_formattaInt(tasseTotaliCalcolate)}\n'
                                  '🏖️ Fondo Mesi Off: -${_formattaInt(cuscinettoFerie)}\n'
                                  '──────────────────────\n'
                                  '✨ Netto Spendibile: ${_formattaInt(nettoRealeSpendibile)}',
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildGlassBadge(
                          icon: Icons.shield_outlined,
                          color: taxBlue,
                          value: _formattaInt(tasseTotaliCalcolate),
                          isTasse: true,
                          isProtetta: isTasseCoperte,
                          onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: const Color(0xFF18181B)),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),

                const SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildGlassMiniCard(
                                icon: Icons.add_circle_outline_rounded,
                                title: 'Storico\nMovimenti',
                                value: 'Riepilogo',
                                iconColor: oceanCyan,
                                onTap: () => AppBottomSheet.mostra(context: context, child: const AddMovementSheet(initialTab: 'riepilogo')),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildGlassMiniCard(
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'I Tuoi\nConti',
                                value: '${walletProvider.accounts.length} Attivi',
                                iconColor: goldAccent,
                                onTap: () => AppBottomSheet.mostra(context: context, child: ManageAccountsSheet(isPiva: widget.isPiva)),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildGlassMiniCard(
                                icon: Icons.pie_chart_outline_rounded,
                                title: 'Gestione\nSpese',
                                value: 'Budget',
                                iconColor: purpleZen,
                                onTap: () => AppBottomSheet.mostra(context: context, child: const PianoSpesaSheet()),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildTipAccreditoStipendio(walletProvider),

                      _buildBannerRicalibrazioneSmart(walletProvider),

                      _buildRipartizioneSpeseGlass(
                        spesoBisogni: spesoRealeBisogni,
                        spesoSvago: spesoRealeSvago,
                        spesoRisparmio: spesoRealeRisparmio,
                        totaleSpeseReali: totaleSpeseReali,
                        targetBisogni: targetBisogni,
                        targetSvago: targetSvago,
                        targetRisparmio: targetRisparmio,
                        entrateRiferimento: entrateRiferimento,
                      ),

                      const SizedBox(height: 24),

                      _buildTargetECuscinettoGlass(walletProvider: walletProvider),

                      const SizedBox(height: 24),

                      if (mostraPiva) ...[
                        _buildGlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(24),
                          child: const SerbatoioTasseWidget(
                            cardColor: Colors.transparent,
                            isCollapsible: true,
                            initiallyExpanded: false,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'CONTI & CARTE',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassContainer(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: walletProvider.accounts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final acc = entry.value;
                            final bool isLast = index == walletProvider.accounts.length - 1;

                            final bool isSerbatoioTasse = acc.role == AccountRole.taxReserve || acc.id == '3';
                            final IconData iconaConto = isSerbatoioTasse
                                ? Icons.shield_outlined
                                : (acc.id == '1' ? Icons.account_balance_rounded : (acc.id == '2' ? Icons.credit_card_rounded : Icons.savings_rounded));

                            return Column(
                              children: [
                                _buildAccountRow(
                                  icon: iconaConto,
                                  title: acc.title,
                                  subtitle: acc.subtitle,
                                  amount: _formattaValuta(acc.amount),
                                  color: acc.color,
                                  onTap: () => _mostraMovimentiConto(context, acc),
                                ),
                                if (!isLast) Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 20, endIndent: 20),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Text(
                              'MOVIMENTI',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                          ),
                          _buildCustomSelectorMovimenti(),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (movimentiFiltrati.isEmpty)
                        _buildGlassContainer(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(child: Text('Nessun movimento in questo periodo', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13))),
                        )
                      else
                        _buildGlassContainer(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: (() {
                              final List<Map<String, dynamic>> movimentiUnici = [];
                              final Set<String> chiaviProcessate = {};
                              for (int i = 0; i < movimentiFiltrati.length; i++) {
                                final tx = movimentiFiltrati[i];
                                final String catLower = (tx.category ?? '').toLowerCase();
                                final String titleLower = (tx.title ?? '').toLowerCase();
                                final bool isTrasferimento = catLower.contains('giroconto') || titleLower.contains('giroconto') || titleLower.contains('accantonamento') || titleLower.contains('sblocco') || titleLower.contains('riserva');

                                if (isTrasferimento) {
                                  final String chiave = '${tx.date.year}_${tx.date.month}_${tx.date.day}_${tx.date.hour}_${tx.date.minute}_${tx.amount.abs().toStringAsFixed(2)}';
                                  if (chiaviProcessate.contains(chiave)) {
                                    final idx = movimentiUnici.indexWhere((m) => m['chiave'] == chiave);
                                    if (idx != -1) {
                                      if (tx.isIncome) movimentiUnici[idx]['toAccountId'] = tx.accountId;
                                      else movimentiUnici[idx]['fromAccountId'] = tx.accountId;
                                    }
                                    continue;
                                  }
                                  chiaviProcessate.add(chiave);
                                  movimentiUnici.add({ 'chiave': chiave, 'tx': tx, 'fromAccountId': !tx.isIncome ? tx.accountId : null, 'toAccountId': tx.isIncome ? tx.accountId : null });
                                } else {
                                  movimentiUnici.add({ 'chiave': 'tx_$i', 'tx': tx, 'fromAccountId': tx.accountId, 'toAccountId': null });
                                }
                              }
                              return movimentiUnici.asMap().entries.map((entry) {
                                final txData = entry.value;
                                final isLast = entry.key == movimentiUnici.length - 1;
                                final tx = txData['tx'];

                                return Column(
                                  children: [
                                    Dismissible(
                                      key: Key('dismiss_${tx.id}_${entry.key}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444).withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                      ),
                                      confirmDismiss: (direction) async {
                                        _gestisciEliminazioneMovimento(context, tx);
                                        return false;
                                      },
                                      child: _buildTransactionRow(
                                        tx: tx,
                                        fromAccountId: txData['fromAccountId'],
                                        toAccountId: txData['toAccountId'],
                                      ),
                                    ),
                                    if (!isLast) Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 20, endIndent: 20),
                                  ],
                                );
                              }).toList();
                            })(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    return RepaintBoundary(
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181C).withOpacity(0.75),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassBadge({required IconData icon, required Color color, required String value, bool isTasse = false, bool isProtetta = false, required VoidCallback onTap, VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress ?? onTap,
      child: _buildGlassContainer(
        padding: const EdgeInsets.only(left: 6, right: 16, top: 6, bottom: 6),
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            if (isTasse) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isProtetta ? oceanCyan.withOpacity(0.3) : color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isProtetta
                    ? Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: oceanCyan, size: 10),
                          const SizedBox(width: 4),
                          Text('Protette', style: TextStyle(color: oceanCyan, fontSize: 9, fontWeight: FontWeight.w800)),
                        ],
                      )
                    : Text('Accantona', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildGlassMiniCard({required IconData icon, required String title, required String value, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, height: 1.2, fontWeight: FontWeight.w600), maxLines: 2),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerRicalibrazioneSmart(WalletProvider walletProvider) {
    if (walletProvider.haRispostoRicalibrazione) return const SizedBox.shrink();

    final String ritmo = walletProvider.statoRitmoFatturato;
    if (ritmo == 'in_linea') return const SizedBox.shrink();

    final bool isOver = ritmo == 'over';
    final Color coloreBanner = isOver ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B);
    final String targetFormattato = _formattaInt(walletProvider.fatturatoStimato);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: coloreBanner.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: coloreBanner.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOver ? Icons.trending_up_rounded : Icons.warning_amber_rounded,
                    color: coloreBanner,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOver ? '🚀 Ritmo Fatturato Superiore' : '⚠️ Forte Scostamento Ritmo',
                    style: TextStyle(color: coloreBanner, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => walletProvider.impostaRispostaRicalibrazione(true),
                child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isOver
                ? 'Stai fatturando più del previsto rispetto al target di $targetFormattato. Vuoi ricalibrare l\'obiettivo annuo?'
                : 'Ad oggi hai fatturato ${_formattaInt(walletProvider.fatturatoTotale)} su $targetFormattato. Per raggiungere il target dovresti fatturare a ritmi molto elevati nei mesi ON rimasti.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coloreBanner,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _mostraModalRicalibrazioneTarget(context, walletProvider, isOver),
                  child: const Text(
                    'Modifica Target 🎯',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  walletProvider.impostaRispostaRicalibrazione(true);
                  AppNotifications.mostraInAlto(context, 'Target annuo di $targetFormattato confermato.');
                },
                child: Text('Mantieni $targetFormattato', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostraModalRicalibrazioneTarget(BuildContext context, WalletProvider walletProvider, bool isOver) {
    const bool simulaStoricoAnnoScorso = true; 
    const double fatturatoAnnoScorsoFinoAdOggi = 22000.0;
    const double fatturatoAnnoScorsoRestante = 38000.0;

    final double fatturatoMancanteYTG = (walletProvider.fatturatoStimato - walletProvider.fatturatoTotale).clamp(0.0, double.infinity);

    final int meseCorrente = DateTime.now().month;
    int mesiRimanentiOn = 0;
    for (int i = meseCorrente - 1; i < 12; i++) {
      if (walletProvider.mesiAttiviState.length > i && walletProvider.mesiAttiviState[i]) {
        mesiRimanentiOn++;
      }
    }
    final double quotaMensileLordaNecessaria = mesiRimanentiOn > 0 ? (fatturatoMancanteYTG / mesiRimanentiOn) : 0.0;

    final TextEditingController targetCtrl = TextEditingController(
      text: walletProvider.fatturatoStimato.toStringAsFixed(0),
    );

    AppPopupWrapper.mostra(
      context: context,
      child: Material(
        color: const Color(0xFF1F2428),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOver ? Icons.auto_graph_rounded : Icons.tune_rounded,
                          color: isOver ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Ricalibrazione Target',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('TARGET ANNUO', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_formattaInt(walletProvider.fatturatoStimato), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(height: 24, width: 1, color: Colors.white24),
                          Column(
                            children: [
                              const Text('REALIZZATO AD OGGI', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_formattaInt(walletProvider.fatturatoTotale), style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Colors.white.withOpacity(0.08), height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fatturato da realizzare (YTG):', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                          Text(_formattaInt(fatturatoMancanteYTG), style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ritmo sui $mesiRimanentiOn mesi attivi rimasti:', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          Text('${_formattaInt(quotaMensileLordaNecessaria)} / mese lordi', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),

                if (simulaStoricoAnnoScorso) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 14),
                            SizedBox(width: 6),
                            Text('STORICO ANNO SCORSO (2025)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Fatturato Gen - Ago 2025:', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                            Text(_formattaInt(fatturatoAnnoScorsoFinoAdOggi), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Fatturato Set - Dic 2025:', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                            Text(_formattaInt(fatturatoAnnoScorsoRestante), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Text('NUOVO TARGET FATTURATO ANNUO (€)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixText: '€ / Anno',
                    suffixStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOver ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final double nuovoTarget = double.tryParse(targetCtrl.text.replaceAll('.', '')) ?? walletProvider.fatturatoStimato;
                      
                      walletProvider.salvaProfiloFiscale(
                        codiceAteco: walletProvider.codiceAteco,
                        coeffRedditivitaVal: walletProvider.coeffRedditivita,
                        aliquotaImpostaVal: walletProvider.aliquotaImposta,
                        accontiVersati: walletProvider.accontiVersati,
                        nettoTarget: walletProvider.nettoTargetMensile,
                        fatturatoStimato: nuovoTarget,
                        mesiAttivi: walletProvider.mesiAttivi,
                        annoAperturaPiva: walletProvider.annoAperturaPiva,
                        meseAperturaPiva: walletProvider.meseAperturaPiva,
                      );

                      walletProvider.impostaRispostaRicalibrazione(true);
                      Navigator.pop(context);

                      AppNotifications.mostraInAlto(
                        context,
                        'Target Annuo aggiornato a ${_formattaInt(nuovoTarget)}! 🎯',
                      );
                    },
                    child: const Text('Salva Nuovo Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRipartizioneSpeseGlass({
    required double spesoBisogni,
    required double spesoSvago,
    required double spesoRisparmio,
    required double totaleSpeseReali,
    required double targetBisogni,
    required double targetSvago,
    required double targetRisparmio,
    required double entrateRiferimento,
  }) {
    final walletProvider = context.watch<WalletProvider>();
    final DateTime ora = DateTime.now();

    final bool isMeseFuturo = _dataFiltroRipartizione.year > ora.year ||
        (_dataFiltroRipartizione.year == ora.year && _dataFiltroRipartizione.month > ora.month);

    double entrateUso = 0.0;
    double bisogniUso = spesoBisogni;
    double svagoUso = spesoSvago;

    final double targetBaseOnboarding = _isVistaAnnuale 
        ? (walletProvider.nettoTargetMensile * 12) 
        : walletProvider.nettoTargetMensile;

    double tBisogni = targetBaseOnboarding * 0.50;
    double tSvago = targetBaseOnboarding * 0.30;
    double tRisparmio = targetBaseOnboarding * 0.20;

    double calcoloRisparmioMese = 0.0;

    if (isMeseFuturo) {
      entrateUso = walletProvider.getEntrataPrevistaMeseFuturo(_dataFiltroRipartizione);
      tBisogni = entrateUso * 0.50;
      tSvago = entrateUso * 0.30;
      tRisparmio = entrateUso * 0.20;

      bisogniUso = walletProvider.vociPianificate
          .where((v) => v['categoria'] == 'Bisogni (50%)')
          .fold(0.0, (sum, v) => sum + (v['previsto'] as num).toDouble());

      svagoUso = walletProvider.vociPianificate
          .where((v) => v['categoria'] == 'Svago (30%)')
          .fold(0.0, (sum, v) => sum + (v['previsto'] as num).toDouble());

      calcoloRisparmioMese = (entrateUso - bisogniUso - svagoUso).clamp(0.0, entrateUso);
    } else {
      entrateUso = entrateRiferimento; 
      
      calcoloRisparmioMese = entrateUso > 0
          ? (entrateUso - bisogniUso - svagoUso).clamp(0.0, entrateUso)
          : 0.0; 
    }

    final bool sforatoBisogni = bisogniUso > tBisogni && tBisogni > 0;
    final bool sforatoSvago = svagoUso > tSvago && tSvago > 0;
    final bool risparmioEroso = calcoloRisparmioMese < tRisparmio && entrateUso > 0;
    final bool haSforamenti = sforatoBisogni || sforatoSvago || risparmioEroso;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isBussolaEspansa = !_isBussolaEspansa),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: purpleZen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.explore_rounded, color: purpleZen, size: 15),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Bussola Spese (50/30/20)',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isBussolaEspansa ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isMeseFuturo
                              ? purpleZen.withOpacity(0.2)
                              : (haSforamenti ? const Color(0xFFEF4444).withOpacity(0.2) : oceanCyan.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isMeseFuturo
                              ? '🔮 PIANIFICATO'
                              : (haSforamenti ? '⚠️ Fuori Target' : 'In Equilibrio'),
                          style: TextStyle(
                            color: isMeseFuturo ? purpleZen : (haSforamenti ? const Color(0xFFEF4444) : oceanCyan),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () => _mostraModalRicalibrazioneTarget(context, walletProvider, walletProvider.statoRitmoFatturato == 'over'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white70, size: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isBussolaEspansa) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _cambiaPeriodoRipartizione(-1),
                        child: Icon(Icons.chevron_left_rounded, color: oceanCyan),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isVistaAnnuale
                            ? '${_dataFiltroRipartizione.year}'
                            : '${_nomiMesiBrevi[_dataFiltroRipartizione.month - 1]} ${_dataFiltroRipartizione.year}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _cambiaPeriodoRipartizione(1),
                        child: Icon(Icons.chevron_right_rounded, color: oceanCyan),
                      ),
                      if (_dataFiltroRipartizione.year != DateTime.now().year ||
                          _dataFiltroRipartizione.month != DateTime.now().month) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _dataFiltroRipartizione = DateTime.now()),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: oceanCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: oceanCyan.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Oggi',
                              style: TextStyle(color: oceanCyan, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isVistaAnnuale = false),
                        child: Text(
                          'Mese',
                          style: TextStyle(
                            color: !_isVistaAnnuale ? oceanCyan : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _isVistaAnnuale = true),
                        child: Text(
                          'Anno',
                          style: TextStyle(
                            color: _isVistaAnnuale ? oceanCyan : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 8,
                  color: Colors.white.withOpacity(0.1),
                  child: entrateUso > 0
                      ? Row(
                          children: [
                            if (bisogniUso > 0)
                              Expanded(
                                flex: (bisogniUso / entrateUso * 1000).toInt(),
                                child: Container(color: oceanCyan),
                              ),
                            if (svagoUso > 0)
                              Expanded(
                                flex: (svagoUso / entrateUso * 1000).toInt(),
                                child: Container(color: goldAccent),
                              ),
                            if (calcoloRisparmioMese > 0)
                              Expanded(
                                flex: (calcoloRisparmioMese / entrateUso * 1000).toInt(),
                                child: Container(color: purpleZen),
                              ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildTargetRow('Spese Fisse', 50, bisogniUso, tBisogni, oceanCyan),
              const SizedBox(height: 12),
              _buildTargetRow('Spese Variabili', 30, svagoUso, tSvago, goldAccent),
              const SizedBox(height: 12),
              _buildTargetRow(
                'Risparmio',
                20,
                calcoloRisparmioMese,
                tRisparmio,
                purpleZen,
                isRisparmio: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRow(String title, int pct, double real, double target, Color color, {bool isRisparmio = false}) {
    final bool inAllarme = isRisparmio ? (real < target && target > 0) : (real > target && target > 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('($pct%)', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ],
        ),
        Row(
          children: [
            Text(_formattaInt(real), style: TextStyle(color: inAllarme ? const Color(0xFFEF4444) : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text('/ ${_formattaInt(target)}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildAccountRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow({required dynamic tx, String? fromAccountId, String? toAccountId}) {
    final walletProvider = context.watch<WalletProvider>();
    String getNome(String? id) => id != null ? (walletProvider.accounts.firstWhere((a) => a.id == id, orElse: () => walletProvider.accounts.first).title) : '';

    String titleLower = tx.title.toLowerCase();
    IconData icon = Icons.receipt_long_rounded;
    Color color = tx.isIncome ? oceanCyan : const Color(0xFFF43F5E);
    String amountStr = (tx.isIncome ? '+' : '-') + _formattaValuta(tx.amount).replaceAll('+', '').replaceAll('-', '');
    
    String nomeConto = getNome(fromAccountId ?? tx.accountId);
    String detail = nomeConto.isNotEmpty ? '$nomeConto • ${tx.subtitle}' : tx.subtitle;

    if (titleLower.contains('accantonamento')) { icon = Icons.shield_rounded; color = taxBlue; detail = 'Verso Salvadanaio Tasse'; amountStr = _formattaValuta(tx.amount); }
    else if (titleLower.contains('sblocco')) { icon = Icons.shield_outlined; color = goldAccent; detail = 'Da Salvadanaio Tasse'; amountStr = _formattaValuta(tx.amount); }
    else if (titleLower.contains('giroconto')) { icon = Icons.sync_alt_rounded; color = Colors.white54; detail = 'Tra i tuoi conti'; amountStr = _formattaValuta(tx.amount); }

    final bool isSoloRicorrenteView = _filtroMeseMovimenti == 'ricorrenti';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tx.title.replaceAll('⚠️', '').replaceAll('🛡️', '').trim(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tx.isRecurrent ?? false) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.sync_rounded, color: oceanCyan.withOpacity(0.8), size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isSoloRicorrenteView ? '$nomeConto • Ricorrenza Mensile' : detail.split('-').first.trim(),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(amountStr, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTipAccreditoStipendio(WalletProvider walletProvider) {
    if (!walletProvider.mostraTipAccreditoStipendio) return const SizedBox.shrink();

    final String etichetta = walletProvider.hasDipendente ? 'lo Stipendio' : 'la Pensione';
    final String nomeTitolo = walletProvider.hasDipendente ? 'Stipendio Dipendente' : 'Assegno Pensione';
    final double importo = walletProvider.entrataExtraMensile;
    final String tipKey = 'tip_stipendio_${DateTime.now().year}_${DateTime.now().month}';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF38BDF8), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Accredito In Attesa',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => walletProvider.dismissAdvisorTip(tipKey),
                child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Risulta impostata un\'entrata mensile fissa. Hai già ricevuto $etichetta di ${_formattaInt(importo)} per questo mese?',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(
                'Registra ${_formattaInt(importo)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () {
                AppBottomSheet.mostra(
                  context: context,
                  child: AddMovementSheet(
                    initialTab: 'entrata',
                    initialTitle: nomeTitolo,
                    initialAmount: importo,
                    initialCategory: 'Stipendio',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}