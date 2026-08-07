import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../widgets_shared/app_secondary_popup.dart';

class ManageAccountsSheet extends StatefulWidget {
  final bool? isPiva;

  const ManageAccountsSheet({super.key, this.isPiva});

  @override
  State<ManageAccountsSheet> createState() => _ManageAccountsSheetState();
}

class _ManageAccountsSheetState extends State<ManageAccountsSheet> {
  final ScrollController _scrollController = ScrollController();
  int? _contoEspansoIndex;

  // 🇮🇹 HELPER VALUTA ITALIANA CON DECIMALI (es. 1.000,50 €)
  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getAccountTypeColor(String tipo) {
    switch (tipo) {
      case 'Carta Prepagata / Debito':
        return const Color(0xFFF59E0B);
      case 'Riserva / Accumulo':
        return const Color(0xFF3B82F6);
      case 'Conto Titoli / Investimenti':
        return const Color(0xFFA855F7);
      case 'Conto Corrente':
      default:
        return const Color(0xFF2DD4BF);
    }
  }

  IconData _getAccountIcon(AccountModel account) {
    final text = '${account.title} ${account.subtitle}'.toLowerCase();
    if (text.contains('carta') || text.contains('prepagata') || text.contains('debito')) {
      return Icons.credit_card_rounded;
    } else if (text.contains('salvadanaio') || text.contains('riserva') || text.contains('accumulo')) {
      return Icons.savings_outlined;
    } else if (text.contains('titoli') || text.contains('investiment')) {
      return Icons.show_chart_rounded;
    } else {
      return Icons.account_balance_outlined;
    }
  }

  void _confermaEliminazioneConto(BuildContext context, AccountModel account) {
    if (account.role == AccountRole.principal || account.role == AccountRole.taxReserve) {
      AppNotifications.mostraInAlto(
        context,
        '"${account.title}" è un conto protetto e non può essere eliminato.',
        type: NotificationType.warning,
      );
      return;
    }

    final provider = context.read<WalletProvider>();
    final altriConti = provider.accounts.where((a) => a.id != account.id).toList();

    // Cerca le transazioni ricorrenti collegate a questo conto
    final ricorrentiAttive = provider.transactions
        .where((t) => t.accountId == account.id && t.isRecurrent)
        .toList();

    // Stato iniziale per le selezioni dell'utente
    String? contoSceltoSaldo = altriConti.isNotEmpty ? altriConti.first.id : 'AZZERA';
    final Map<String, String> scelteRicorrenze = {};
    for (var tx in ricorrentiAttive) {
      scelteRicorrenze[tx.id] = altriConti.isNotEmpty ? altriConti.first.id : 'ANNULLA';
    }

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFEF4444),
      titolo: 'Chiusura Conto: ${account.title}',
      testoConferma: 'Conferma Chiusura',
      onConferma: () {
        try {
          provider.chiudiContoGuidato(
            targetAccountId: account.id,
            saldoDestinazioneAccountId: contoSceltoSaldo,
            mappaNuoviContiRicorrenze: scelteRicorrenze,
          );
          Navigator.pop(context);
          setState(() {
            _contoEspansoIndex = null;
          });
          AppNotifications.mostraInAlto(context, 'Conto "${account.title}" chiuso regolarmente! 🎉');
        } catch (e) {
          Navigator.pop(context);
          AppNotifications.mostraInAlto(context, '$e'.replaceAll('Exception: ', ''), type: NotificationType.error);
        }
      },
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SEZIONE 1: SALDO RESIDUO ---
                if (account.amount != 0.0) ...[
                  Text(
                    'Sul conto è presente un saldo di ${_formattaValuta(account.amount)}.\nDove vuoi trasferire questo importo?',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: contoSceltoSaldo,
                    dropdownColor: const Color(0xFF18181B),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      ...altriConti.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('Trasferisci a: ${c.title}'),
                          )),
                      const DropdownMenuItem(
                        value: 'AZZERA',
                        child: Text('Azzeramento (Denaro speso/prelevato)'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => contoSceltoSaldo = v),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),
                ],

                // --- SEZIONE 2: LISTA SPESE RICORRENTI ---
                if (ricorrentiAttive.isNotEmpty) ...[
                  Text(
                    'Ci sono ${ricorrentiAttive.length} spese ricorrenti collegate a questo conto. Su quale conto vuoi spostare i futuri addebiti?',
                    style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 13, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ...ricorrentiAttive.map((tx) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tx.title} (${_formattaValuta(tx.amount)})',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: scelteRicorrenze[tx.id],
                            dropdownColor: const Color(0xFF18181B),
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            items: [
                              ...altriConti.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text('Sposta su: ${c.title}'),
                                  )),
                              const DropdownMenuItem(
                                value: 'ANNULLA',
                                child: Text('Annulla Ricorrenza futura', style: TextStyle(color: Color(0xFFEF4444))),
                              ),
                            ],
                            onChanged: (v) => setDialogState(() {
                              if (v != null) scelteRicorrenze[tx.id] = v;
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  Text(
                    'Vuoi davvero chiudere il conto "${account.title}"?\nNessuna spesa ricorrente attiva riscontrata.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  void _mostraDialogModificaConto(BuildContext context, AccountModel account) {
    final TextEditingController nomeController = TextEditingController(text: account.title);
    final TextEditingController controller = TextEditingController(
      text: account.amount.toStringAsFixed(2).replaceAll('.', ','),
    );

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.edit_rounded,
      iconColor: const Color(0xFF2DD4BF),
      titolo: 'Modifica Conto',
      testoConferma: 'Salva',
      onConferma: () {
        final nuovoNome = nomeController.text.trim();
        final nuovoSaldo = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', '.')) ?? account.amount;

        if (nuovoNome.isNotEmpty) {
          context.read<WalletProvider>().updateAccountDetails(
                accountId: account.id,
                newTitle: nuovoNome,
                newAmount: nuovoSaldo,
              );
          Navigator.pop(context);
          setState(() {
            _contoEspansoIndex = null;
          });
          AppNotifications.mostraInAlto(context, 'Conto "$nuovoNome" aggiornato! 🎉');
        }
      },
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Nome Conto',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Nuovo Saldo (€)',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostraDettaglioMovimentiConto(BuildContext context, AccountModel account) {
    final transactions = context.read<WalletProvider>().transactions;

    final movimentiConto = transactions
        .where((t) =>
            t.accountId == account.id ||
            t.title.contains(account.title) ||
            account.title.contains(t.title))
        .toList();

    movimentiConto.sort((a, b) => b.date.compareTo(a.date));

    const List<String> nomiMesi = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];

    List<Widget> elementiLista = [];
    String? meseAnnoCorrente;

    for (var tx in movimentiConto) {
      String meseAnno = '${nomiMesi[tx.date.month - 1].toUpperCase()} ${tx.date.year}';

      if (meseAnno != meseAnnoCorrente) {
        meseAnnoCorrente = meseAnno;
        elementiLista.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              meseAnno,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      }

      final String sign = tx.isIncome ? '+' : '-';
      final String impFormatted = '$sign${_formattaValuta(tx.amount)}';
      final String dataStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}';

      elementiLista.add(_buildRigaMovimento(tx.title, impFormatted, dataStr, tx.isIncome));
    }

    AppSecondaryPopup.mostra(
      context: context,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: account.color,
      titolo: 'Movimenti: ${account.title}',
      testoAnnulla: 'Chiudi',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          elementiLista.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Nessun movimento registrato su questo conto.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: elementiLista,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRigaMovimento(String titolo, String importo, String data, bool isEntrata) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titolo, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(data, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Text(
            importo,
            style: TextStyle(
              color: isEntrata ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _mostraDialogNuovoConto() {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController dettaglioController = TextEditingController();
    final TextEditingController saldoController = TextEditingController();
    String tipoSelezionato = 'Conto Corrente';
    bool isTipoEspanso = false;

    final List<String> opzioniTipo = [
      'Conto Corrente',
      'Carta Prepagata / Debito',
      'Riserva / Accumulo',
      'Conto Titoli / Investimenti',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppSecondaryPopup(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF2DD4BF),
          titolo: 'Crea Nuovo Conto',
          testoConferma: 'Crea Conto',
          onConferma: () {
            final nome = nomeController.text.trim();
            final dettaglioText = dettaglioController.text.trim();
            final saldo = double.tryParse(saldoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

            if (nome.isEmpty) {
              AppNotifications.mostraInAlto(
                context,
                'Attenzione: inserire il nome del conto',
                type: NotificationType.warning,
              );
              return;
            }

            try {
              final provider = context.read<WalletProvider>();
              final sottotitoloFinale = dettaglioText.isNotEmpty ? dettaglioText : tipoSelezionato;
              final coloreConto = _getAccountTypeColor(tipoSelezionato);

              // 🟢 Una sola chiamata pulita: crea il conto e registra tutto al posto giusto!
              provider.addAccount(
                title: nome,
                subtitle: sottotitoloFinale,
                initialAmount: saldo,
                color: coloreConto,
              );

              Navigator.pop(context);
              AppNotifications.mostraInAlto(context, 'Conto "$nome" creato con successo! 🎉');
            } catch (e) {
              AppNotifications.mostraInAlto(context, 'Errore creazione conto: $e', type: NotificationType.error);
            }
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Nome Conto o Carta (es. Hype, Fineco)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dettaglioController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Dettaglio / Note (es. IBAN •• 4092)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('TIPOLOGIA CONTO', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildDialogInlineSelector(
                  selectedValue: tipoSelezionato,
                  isExpanded: isTipoEspanso,
                  items: opzioniTipo,
                  onToggle: () => setDialogState(() => isTipoEspanso = !isTipoEspanso),
                  onSelect: (val) {
                    setDialogState(() {
                      tipoSelezionato = val;
                      isTipoEspanso = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: saldoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Saldo Iniziale (€)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostraDialogGiroconto(List<AccountModel> accounts) {
    if (accounts.length < 2) return;

    String daConto = accounts[0].title;
    String aConto = accounts[1].title;
    bool isDaContoEspanso = false;
    bool isAContoEspanso = false;

    final List<String> nomiConti = accounts.map((c) => c.title).toList();
    final TextEditingController importoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppSecondaryPopup(
            icon: Icons.sync_alt_rounded,
            iconColor: const Color(0xFF2DD4BF),
            titolo: 'Giroconto Tra Conti',
            testoConferma: 'Esegui Giroconto',
            onConferma: () {
              final importo = double.tryParse(importoController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
              
              if (importo <= 0) {
                AppNotifications.mostraInAlto(
                  context,
                  'Inserisci un importo valido maggiore di 0 €',
                  type: NotificationType.warning,
                );
                return;
              }

              if (daConto == aConto) {
                AppNotifications.mostraInAlto(
                  context,
                  'Seleziona due conti differenti per il trasferimento',
                  type: NotificationType.warning,
                );
                return;
              }

              final accDa = accounts.firstWhere((a) => a.title == daConto);
              final accA = accounts.firstWhere((a) => a.title == aConto);

              if (accDa.amount < importo) {
                AppNotifications.mostraInAlto(
                  context,
                  'Saldo insufficiente su "${accDa.title}"! (Disponibili: ${_formattaValuta(accDa.amount)})',
                  type: NotificationType.error,
                );
                return;
              }

              try {
                final provider = context.read<WalletProvider>();
                provider.eseguiGiroconto(
                  daAccountId: accDa.id,
                  aAccountId: accA.id,
                  importo: importo,
                  isAccantonamentoTasse: false,
                );

                Navigator.pop(context);
                AppNotifications.mostraInAlto(
                  context,
                  'Giroconto di ${_formattaValuta(importo)} eseguito con successo! 🎉',
                );
              } catch (e) {
                AppNotifications.mostraInAlto(
                  context,
                  'Errore durante il giroconto: $e',
                  type: NotificationType.error,
                );
              }
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DA CONTO (ADDEBITO)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildDialogInlineSelector(
                    selectedValue: daConto,
                    isExpanded: isDaContoEspanso,
                    items: nomiConti,
                    onToggle: () => setDialogState(() {
                      isDaContoEspanso = !isDaContoEspanso;
                      if (isDaContoEspanso) isAContoEspanso = false;
                    }),
                    onSelect: (val) {
                      setDialogState(() {
                        daConto = val;
                        isDaContoEspanso = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('A CONTO (ACCREDITO)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildDialogInlineSelector(
                    selectedValue: aConto,
                    isExpanded: isAContoEspanso,
                    items: nomiConti,
                    onToggle: () => setDialogState(() {
                      isAContoEspanso = !isAContoEspanso;
                      if (isAContoEspanso) isDaContoEspanso = false;
                    }),
                    onSelect: (val) {
                      setDialogState(() {
                        aConto = val;
                        isAContoEspanso = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: importoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Importo Trasferimento (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.sync_alt_rounded, color: Color(0xFF2DD4BF), size: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogInlineSelector({
    required String selectedValue,
    required bool isExpanded,
    required List<String> items,
    required VoidCallback onToggle,
    required Function(String) onSelect,
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
            Column(
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
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 🔴 INIZIO SOSTITUZIONE — METODO: build(BuildContext context) in 2_2_wallet_manage_accounts.dart
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final double saldoTotale = walletProvider.patrimonioNetto;
    final accounts = walletProvider.accounts;
    final bool mostraPiva = widget.isPiva ?? walletProvider.isPartitaIVA;

    // 📌 CALCOLO DELLE QUOTE GLOBALI PRUDENZIALI
    final int mesiLavorati = walletProvider.mesiAttivi > 0 ? walletProvider.mesiAttivi : 10;
    final double percentualeFondoFerie = (12 - mesiLavorati) / 12;

    final double sommaContiLiquidi = accounts
        .where((a) => !a.title.toLowerCase().contains('salvadanaio tasse') && !a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double tasseDaAccantonare = accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double postTasse = (sommaContiLiquidi - tasseDaAccantonare).clamp(0.0, double.infinity);
    final double cuscinettoFerie = postTasse * percentualeFondoFerie;
    final double nettoRealeSpendibile = postTasse - cuscinettoFerie;

    return AppPopupWrapper(
      title: 'Gestione Conti',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 HEADER GLOBALE: LIQUIDITÀ SPENDIBILE + CUSCINETTO PROTETTO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PATRIMONIO LIQUIDO TOTALE',
                            style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formattaValuta(saldoTotale),
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (mostraPiva) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  // 📊 TABELLA GLOBALE 2 RIGHE: SPENDIBILE + CUSCINETTO
                  Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FixedColumnWidth(12),
                      2: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 14),
                              SizedBox(width: 6),
                              Text('LIQUIDITÀ SPENDIBILE:', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox.shrink(),
                          Text(
                            _formattaValuta(nettoRealeSpendibile),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const TableRow(
                        children: [
                          SizedBox(height: 6),
                          SizedBox.shrink(),
                          SizedBox(height: 6),
                        ],
                      ),
                      TableRow(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.beach_access_rounded, color: Color(0xFF8B5CF6), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'CUSCINETTO MESI NO-LAVORO ($mesiLavorati MESI):',
                                style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox.shrink(),
                          Text(
                            _formattaValuta(cuscinettoFerie),
                            style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 📌 INTESTAZIONE E AZIONI DEI CONTI (Qui sono stati spostati i tasti "Nuovo" e "Giroconto")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'I TUOI CONTI & CARTE',
                    style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Text('${accounts.length} attivi', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _mostraDialogNuovoConto,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF2DD4BF), size: 14),
                          SizedBox(width: 3),
                          Text(
                            'Nuovo',
                            style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.sync_alt_rounded, color: Color(0xFF2DD4BF), size: 20),
                    onPressed: () => _mostraDialogGiroconto(accounts),
                    tooltip: 'Esegui Giroconto',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 📌 LISTA CONTI ORDINABILE E PULITA
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        _contoEspansoIndex = null;
                      });
                      context.read<WalletProvider>().reorderAccounts(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final bool isPrincipal = account.id == '1' || account.title.toLowerCase().contains('principale');
                      final double contoPostTasse = (account.amount - account.virtualTaxAmount).clamp(0.0, double.infinity);

                      return Container(
                        key: ValueKey(account.id),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: InkWell(
                          onTap: () => _mostraDettaglioMovimentiConto(context, account),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.drag_handle_rounded, color: Colors.white38, size: 20),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: account.color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getAccountIcon(account),
                                    color: account.color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        account.subtitle,
                                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formattaValuta(account.amount),
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    // 📌 RIPARTIZIONE CONTABILE ORDINATA SUL CONTO PRINCIPALE (Post-Tasse e Tasse)
                                    if (mostraPiva && isPrincipal) ...[
                                      const SizedBox(height: 4),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formattaValuta(contoPostTasse),
                                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formattaValuta(account.virtualTaxAmount),
                                                style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                                  color: const Color(0xFF1C1C21),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  offset: const Offset(0, 40),
                                  onSelected: (value) {
                                    if (value == 'edit') _mostraDialogModificaConto(context, account);
                                    if (value == 'delete') _confermaEliminazioneConto(context, account);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [Icon(Icons.edit_rounded, color: Colors.white, size: 16), SizedBox(width: 8), Text('Modifica Conto', style: TextStyle(color: Colors.white, fontSize: 12))]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16), SizedBox(width: 8), Text('Elimina Conto', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12))]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}