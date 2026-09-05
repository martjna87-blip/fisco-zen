import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../data/recurrence_manager.dart';
import 'app_notifications.dart';
import 'app_secondary_popup.dart';
import 'app_action_card.dart';

class AppGestioneRicorrenzaPopup {
  static const List<String> _nomiMesiBrevi = [
    'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
    'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
  ];

  static void mostra(
    BuildContext context, {
    required String id,
    required String titolo,
    DateTime? meseRiferimento,
    VoidCallback? onConcluso,
  }) {
    final provider = context.read<WalletProvider>();
    final String rootId = RecurrenceManager.getRootId(id);

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
                'Scegli come modificare la spesa/entrata per "$titolo":',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // 1️⃣ ULTIMO MESE DI VALIDITÀ
              AppActionCard(
                icon: Icons.calendar_view_month_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Scegli ultimo mese di validità...',
                subtitle: 'Seleziona solo il mese: la regola si fermerà dal mese successivo.',
                onTap: () {
                  _mostraPickerUltimoMese(context, provider, rootId, titolo, ctx, onConcluso);
                },
              ),
              const SizedBox(height: 10),

              // 2️⃣ SOSPENDI MESI SPECIFICI (GRIGLIA CON GESTIONE 3 COLORI)
              AppActionCard(
                icon: Icons.rule_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Sospendi mesi specifici...',
                subtitle: 'Seleziona quali mesi vuoi saltare. La regola rimarrà attiva per gli altri.',
                onTap: () {
                  _mostraPickerSaltaMesi(context, provider, rootId, id, titolo, ctx, onConcluso);
                },
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 14),

              // 3️⃣ ELIMINA L'INTERA SERIE (CON ALERT DI CONFERMA)
              AppActionCard(
                icon: Icons.delete_forever_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Elimina l\'intera serie',
                subtitle: 'Cancella la regola e lo storico passato nei mesi precedenti. Irreversibile.',
                isDanger: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _mostraAlertEliminazioneTotale(context, provider, rootId, titolo, onConcluso);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _mostraPickerUltimoMese(
    BuildContext context,
    WalletProvider provider,
    String rootId,
    String titolo,
    BuildContext parentCtx,
    VoidCallback? onConcluso,
  ) {
    int annoSelezionato = DateTime.now().year;
    final txMatches = provider.transactions.where((t) => RecurrenceManager.getRootId(t.id) == rootId).toList();

    DateTime? inizio = txMatches.isNotEmpty ? (txMatches.first.dataInizio ?? txMatches.first.date) : null;
    DateTime? fine = txMatches.isNotEmpty ? txMatches.first.dataFineRicorrenza : null;
    String freqStr = txMatches.isNotEmpty ? (txMatches.first.frequenza ?? 'Ogni mese').toLowerCase() : 'ogni mese';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setPickerState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ultimo Mese Attivo', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF38BDF8)),
                    onPressed: () => setPickerState(() => annoSelezionato--),
                  ),
                  Text('$annoSelezionato', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF38BDF8)),
                    onPressed: () => setPickerState(() => annoSelezionato++),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final meseIdx = index + 1;
                final nomeMese = _nomiMesiBrevi[index];
                final primoGiornoMese = DateTime(annoSelezionato, meseIdx, 1);
                final ultimoGiornoMese = DateTime(annoSelezionato, meseIdx + 1, 0);

                bool isSpesaPresente = true;
                if (inizio != null) {
                  final startMese = DateTime(inizio.year, inizio.month, 1);
                  if (primoGiornoMese.isBefore(startMese)) {
                    isSpesaPresente = false;
                  } else {
                    final diffMesi = (annoSelezionato - inizio.year) * 12 + (meseIdx - inizio.month);
                    if (freqStr.contains('2 mesi') && diffMesi % 2 != 0) isSpesaPresente = false;
                    else if (freqStr.contains('trimestrale') && diffMesi % 3 != 0) isSpesaPresente = false;
                    else if (freqStr.contains('semestrale') && diffMesi % 6 != 0) isSpesaPresente = false;
                    else if (freqStr.contains('annuale') && diffMesi % 12 != 0) isSpesaPresente = false;
                  }
                }
                if (fine != null && ultimoGiornoMese.isAfter(fine)) {
                  isSpesaPresente = false;
                }

                // 🔍 CONTROLLO SE IL MESE È GIÀ STATO CANCELLATO MANUALMENTE
                final targetMonth = DateTime(annoSelezionato, meseIdx, 1);
                final hasRealTx = provider.transactions.any((t) =>
                    RecurrenceManager.getRootId(t.id) == rootId &&
                    t.date.year == annoSelezionato &&
                    t.date.month == meseIdx);
                final hasPrevisto = provider.getMovimentiPrevisti(targetMonth).any((t) =>
                    RecurrenceManager.getRootId(t.id) == rootId);

                final bool isGiaCancellato = isSpesaPresente && !hasRealTx && !hasPrevisto;

                Color coloreSfondo = Colors.white.withOpacity(0.03);
                Color coloreBordo = Colors.white10;
                Color coloreTesto = Colors.white38;
                IconData? iconaStato;
                Color? coloreIcona;

                if (isSpesaPresente) {
                  if (isGiaCancellato) {
                    // 🔴 MESE CANCELLATO MANUALMENTE
                    coloreSfondo = const Color(0xFFEF4444).withOpacity(0.18);
                    coloreBordo = const Color(0xFFEF4444).withOpacity(0.6);
                    coloreTesto = const Color(0xFFEF4444);
                    iconaStato = Icons.block_rounded;
                    coloreIcona = const Color(0xFFEF4444);
                  } else {
                    // 🔵 MESE ATTIVO DISPONIBILE
                    coloreSfondo = const Color(0xFF38BDF8).withOpacity(0.2);
                    coloreBordo = const Color(0xFF38BDF8);
                    coloreTesto = Colors.white;
                    iconaStato = Icons.check_circle_rounded;
                    coloreIcona = const Color(0xFF38BDF8);
                  }
                }

                return InkWell(
                  onTap: () {
                    final limiteData = DateTime(annoSelezionato, meseIdx + 1, 0, 23, 59, 59);

                    if (inizio != null && limiteData.isBefore(DateTime(inizio.year, inizio.month, 1))) {
                      Navigator.pop(dialogCtx);
                      Navigator.pop(parentCtx);
                      _mostraAlertEliminazioneTotale(context, provider, rootId, titolo, onConcluso);
                      return;
                    }

                    final now = DateTime.now();
                    final bool tagliaStoricoGiaPagato = limiteData.isBefore(now);

                    if (tagliaStoricoGiaPagato) {
                      Navigator.pop(dialogCtx);
                      showDialog(
                        context: context,
                        builder: (ctxTaglio) => AlertDialog(
                          backgroundColor: const Color(0xFF18181B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.history_rounded, color: Color(0xFFF59E0B), size: 22),
                              SizedBox(width: 8),
                              Text('Storno Movimenti Passati', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Text(
                            'Impostando la fine a $nomeMese $annoSelezionato, i pagamenti registrati dopo questa data verranno cancellati e i relativi soldi saranno RIACCREDITATI sul tuo conto.\n\nVuoi procedere?',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctxTaglio),
                              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                provider.stopRecurrenceFromDate(rootId, limiteData);
                                Navigator.pop(ctxTaglio);
                                Navigator.pop(parentCtx);
                                onConcluso?.call();
                                AppNotifications.mostraInAlto(
                                  context,
                                  'Regola "$titolo" fermata a $nomeMese $annoSelezionato. Saldi e storico aggiornati!',
                                  type: NotificationType.warning,
                                );
                              },
                              child: const Text('SÌ, STORNA E FERMA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      provider.stopRecurrenceFromDate(rootId, limiteData);
                      Navigator.pop(dialogCtx);
                      Navigator.pop(parentCtx);
                      onConcluso?.call();
                      AppNotifications.mostraInAlto(
                        context,
                        'Regola "$titolo" valida fino a $nomeMese $annoSelezionato!',
                        type: NotificationType.warning,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: coloreSfondo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: coloreBordo),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (iconaStato != null) ...[
                              Icon(iconaStato, color: coloreIcona, size: 10),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              nomeMese,
                              style: TextStyle(
                                color: coloreTesto,
                                fontSize: 11,
                                fontWeight: isSpesaPresente ? FontWeight.bold : FontWeight.normal,
                                decoration: isGiaCancellato ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                        if (isGiaCancellato)
                          const Text(
                            'Cancellato',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 7, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  static void _mostraPickerSaltaMesi(
    BuildContext context,
    WalletProvider provider,
    String rootId,
    String currentId,
    String titolo,
    BuildContext parentCtx,
    VoidCallback? onConcluso,
  ) {
    int annoSelezionato = DateTime.now().year;
    Set<int> mesiDaSaltare = {};

    final txMatches = provider.transactions.where((t) => RecurrenceManager.getRootId(t.id) == rootId).toList();
    DateTime? inizio = txMatches.isNotEmpty ? (txMatches.first.dataInizio ?? txMatches.first.date) : null;
    DateTime? fine = txMatches.isNotEmpty ? txMatches.first.dataFineRicorrenza : null;
    String freqStr = txMatches.isNotEmpty ? (txMatches.first.frequenza ?? 'Ogni mese').toLowerCase() : 'ogni mese';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setPickerState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Salta Mesi', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFFF59E0B)),
                    onPressed: () => setPickerState(() { annoSelezionato--; mesiDaSaltare.clear(); }),
                  ),
                  Text('$annoSelezionato', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFFF59E0B)),
                    onPressed: () => setPickerState(() { annoSelezionato++; mesiDaSaltare.clear(); }),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final meseIdx = index + 1;
                final nomeMese = _nomiMesiBrevi[index];
                final primoGiornoMese = DateTime(annoSelezionato, meseIdx, 1);
                final ultimoGiornoMese = DateTime(annoSelezionato, meseIdx + 1, 0);

                bool isSpesaPresente = true;
                if (inizio != null && primoGiornoMese.isBefore(DateTime(inizio.year, inizio.month, 1))) {
                  isSpesaPresente = false;
                } else if (inizio != null) {
                  final diffMesi = (annoSelezionato - inizio.year) * 12 + (meseIdx - inizio.month);
                  if (freqStr.contains('2 mesi') && diffMesi % 2 != 0) isSpesaPresente = false;
                  else if (freqStr.contains('trimestrale') && diffMesi % 3 != 0) isSpesaPresente = false;
                  else if (freqStr.contains('semestrale') && diffMesi % 6 != 0) isSpesaPresente = false;
                  else if (freqStr.contains('annuale') && diffMesi % 12 != 0) isSpesaPresente = false;
                }
                if (fine != null && ultimoGiornoMese.isAfter(fine)) {
                  isSpesaPresente = false;
                }

                final targetMonth = DateTime(annoSelezionato, meseIdx, 1);
                final hasRealTx = provider.transactions.any((t) =>
                    RecurrenceManager.getRootId(t.id) == rootId &&
                    t.date.year == annoSelezionato &&
                    t.date.month == meseIdx);
                final hasPrevisto = provider.getMovimentiPrevisti(targetMonth).any((t) =>
                    RecurrenceManager.getRootId(t.id) == rootId);

                final bool isGiaCancellato = isSpesaPresente && !hasRealTx && !hasPrevisto;
                final bool isSelezionatoOra = mesiDaSaltare.contains(meseIdx);

                Color coloreSfondo = Colors.white.withOpacity(0.03);
                Color coloreBordo = Colors.white10;
                Color coloreTesto = Colors.white38;
                IconData? iconaStato;
                Color? coloreIcona;

                if (isSpesaPresente) {
                  if (isGiaCancellato) {
                    coloreSfondo = const Color(0xFFEF4444).withOpacity(0.18);
                    coloreBordo = const Color(0xFFEF4444).withOpacity(0.6);
                    coloreTesto = const Color(0xFFEF4444);
                    iconaStato = Icons.block_rounded;
                    coloreIcona = const Color(0xFFEF4444);
                  } else if (isSelezionatoOra) {
                    coloreSfondo = const Color(0xFF38BDF8).withOpacity(0.25);
                    coloreBordo = const Color(0xFF38BDF8);
                    coloreTesto = Colors.white;
                    iconaStato = Icons.check_circle_rounded;
                    coloreIcona = const Color(0xFF38BDF8);
                  } else {
                    coloreSfondo = const Color(0xFFF59E0B).withOpacity(0.15);
                    coloreBordo = const Color(0xFFF59E0B).withOpacity(0.4);
                    coloreTesto = Colors.white;
                    iconaStato = Icons.check_circle_outline_rounded;
                    coloreIcona = const Color(0xFFF59E0B);
                  }
                }

                return InkWell(
                  onTap: (isSpesaPresente && !isGiaCancellato) ? () {
                    setPickerState(() {
                      if (isSelezionatoOra) {
                        mesiDaSaltare.remove(meseIdx);
                      } else {
                        mesiDaSaltare.add(meseIdx);
                      }
                    });
                  } : null,
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: coloreSfondo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: coloreBordo),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (iconaStato != null) ...[
                              Icon(iconaStato, color: coloreIcona, size: 10),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              nomeMese,
                              style: TextStyle(
                                color: coloreTesto,
                                fontSize: 11,
                                fontWeight: isSpesaPresente ? FontWeight.bold : FontWeight.normal,
                                decoration: (isSelezionatoOra || isGiaCancellato) ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                        if (isGiaCancellato)
                          const Text(
                            'Cancellato',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 7, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            if (mesiDaSaltare.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  for (int m in mesiDaSaltare) {
                    final dataSospensione = DateTime(annoSelezionato, m, 1);
                    
                    final txGiaGenerata = provider.transactions.where((t) => 
                        RecurrenceManager.getRootId(t.id) == rootId && 
                        t.date.year == annoSelezionato && 
                        t.date.month == m &&
                        !t.id.startsWith('rule_') && !t.id.startsWith('prev_')
                    ).toList();

                    if (txGiaGenerata.isNotEmpty) {
                      provider.eliminaSoloQuestoMese(txGiaGenerata.first.id, dataSospensione);
                    } else {
                      provider.eliminaSoloQuestoMese(rootId, dataSospensione);
                    }
                  }
                  
                  Navigator.pop(dialogCtx);
                  Navigator.pop(parentCtx);
                  onConcluso?.call();
                  AppNotifications.mostraInAlto(
                    context,
                    'Regola "$titolo" sospesa per i mesi selezionati!',
                    type: NotificationType.warning,
                  );
                },
                child: Text('CONFERMA (${mesiDaSaltare.length})', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  static void _mostraAlertEliminazioneTotale(
    BuildContext context,
    WalletProvider provider,
    String rootId,
    String titolo,
    VoidCallback? onConcluso,
  ) {
    showDialog(
      context: context,
      builder: (ctxAlert) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.warning_rounded,
        iconColor: const Color(0xFFEF4444),
        titolo: '⚠️ ELIMINAZIONE TOTALE',
        testoAnnulla: 'Annulla',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sei sicuro di voler eliminare TUTTI i movimenti di "$titolo"?\n\n'
              '🚨 Verrà cancellato anche lo STORICO PASSATO nei mesi precedenti. L\'operazione è irreversibile.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  provider.rimuoviSpesaPianificata(rootId);
                  provider.deleteTransaction(rootId);
                  Navigator.pop(ctxAlert);
                  onConcluso?.call();
                  AppNotifications.mostraInAlto(
                    context,
                    'Intera serie di "$titolo" eliminata (compreso lo storico passato)',
                    type: NotificationType.error,
                  );
                },
                child: const Text(
                  'SÌ, ELIMINA ANCHE LO STORICO PASSATO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}