import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class ManageAccountsSheet extends StatefulWidget {
  final bool? isPiva; // 👈 Dichiarazione della variabile mancante

  const ManageAccountsSheet({super.key, this.isPiva});

  @override
  State<ManageAccountsSheet> createState() => _ManageAccountsSheetState();
}

class _ManageAccountsSheetState extends State<ManageAccountsSheet> {
  final ScrollController _scrollController = ScrollController();
  int? _contoEspansoIndex; // Per espandere la cella in-line

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🎨 ASSEGNA IL COLORE IN BASE ALLA TIPOLOGIA
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

  // 🏛️ RICONOSCE L'ICONA IN AUTOMATICO
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
  
  // 🗑️ DIALOG DI CONFERMA ELIMINAZIONE CONTO
  void _confermaEliminazioneConto(BuildContext context, AccountModel account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text('Elimina Conto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Vuoi davvero eliminare il conto "${account.title}"?\nQuesta azione non potrà essere annullata.',
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
              try {
                context.read<WalletProvider>().deleteAccount(account.id);
                Navigator.pop(ctx);
                setState(() {
                  _contoEspansoIndex = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conto "${account.title}" eliminato.'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$e'.replaceAll('Exception: ', '')),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ✏️ DIALOG MODIFICA NOME E SALDO CONTO
  void _mostraDialogModificaConto(BuildContext context, AccountModel account) {
    final TextEditingController nomeController = TextEditingController(text: account.title);
    final TextEditingController controller = TextEditingController(
      text: account.amount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifica Conto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final nuovoNome = nomeController.text.trim();
              final nuovoSaldo = double.tryParse(controller.text.replaceAll(',', '.')) ?? account.amount;

              if (nuovoNome.isNotEmpty) {
                context.read<WalletProvider>().updateAccountDetails(
                      accountId: account.id,
                      newTitle: nuovoNome,
                      newAmount: nuovoSaldo,
                    );
                Navigator.pop(ctx);
                setState(() {
                  _contoEspansoIndex = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conto "$nuovoNome" aggiornato!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // SCROLL AUTOMATICO REGOLATO FLUIDO
  void _scrollToOffset(double deltaPixels) {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          (_scrollController.offset + deltaPixels).clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  // FUNZIONE PER APRIRE IL DETTAGLIO MOVIMENTI DEL CONTO REALI CON DIVISORI PER MESE
  void _mostraDettaglioMovimentiConto(BuildContext context, AccountModel account) {
    final transactions = context.read<WalletProvider>().transactions;

    // 1. FILTRO INTELLIGENTE PER ID O TITOLO
    final movimentiConto = transactions.where((t) =>
      t.accountId == account.id ||
      t.title.contains(account.title) ||
      account.title.contains(t.title)
    ).toList();

    // 2. ORDINAMENTO PER DATA (dal più recente al più vecchio)
    movimentiConto.sort((a, b) => b.date.compareTo(a.date));

    // Nomi dei mesi in italiano
    const List<String> nomiMesi = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];

    // 3. COSTRUZIONE DELLA LISTA DI WIDGET CON DIVISORI
    List<Widget> elementiLista = [];
    String? meseAnnoCorrente;

    for (var tx in movimentiConto) {
      String meseAnno = '${nomiMesi[tx.date.month - 1].toUpperCase()} ${tx.date.year}';

      // Se il mese cambia, aggiunge la riga divisoria in grigio chiaro/trasparente
      if (meseAnno != meseAnnoCorrente) {
        meseAnnoCorrente = meseAnno;
        elementiLista.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08), // Grigio chiaro coerente col tema scuro
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

      // Riga movimento standard
      final String sign = tx.isIncome ? '+' : '-';
      final String impFormatted = '$sign${tx.amount.toStringAsFixed(2)} €';
      final String dataStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}';

      elementiLista.add(_buildRigaMovimento(tx.title, impFormatted, dataStr, tx.isIncome));
    }

    // 4. MOSTRA DIALOG
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141417),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: account.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Movimenti: ${account.title}',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
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
                        maxHeight: MediaQuery.of(context).size.height * 0.45, // Evita overflow su liste lunghe
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
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

  // DIALOG NUOVO CONTO COMPLETAMENTE CUSTOMIZZABILE
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
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C21),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Crea Nuovo Conto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. NOME CONTO
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

                // 2. DETTAGLIO / SOTTOTITOLO OPZIONALE
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

                // 3. SELETTORE TIPOLOGIA CONTO
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

                // 4. SALDO INIZIALE
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final dettaglioText = dettaglioController.text.trim();
                final saldo = double.tryParse(saldoController.text.replaceAll(',', '.')) ?? 0.0;

                if (nome.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inserisci un nome per il conto!'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }

                try {
                  final provider = context.read<WalletProvider>();
                  final sottotitoloFinale = dettaglioText.isNotEmpty ? dettaglioText : tipoSelezionato;
                  final coloreConto = _getAccountTypeColor(tipoSelezionato);

                  // Aggiunge il conto assegnando colore e sottotitolo corretti
                  provider.addAccount(
                    title: nome,
                    subtitle: sottotitoloFinale,
                    initialAmount: saldo,
                    color: coloreConto,
                  );

                  if (saldo > 0) {
                    provider.addTransaction(
                      title: 'Saldo Iniziale: $nome',
                      amount: saldo,
                      isIncome: true,
                      category: 'Risparmi',
                    );
                  }

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Conto "$nome" creato con successo!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore creazione conto: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Crea Conto', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  
  // DIALOG GIROCONTO INTELLIGENTE (CON GESTIONE RISERVA TASSE P.IVA)
  void _mostraDialogGiroconto(List<AccountModel> accounts) {
    if (accounts.length < 2) return;

    String daConto = accounts[0].title;
    String aConto = accounts[1].title;
    bool isDaContoEspanso = false;
    bool isAContoEspanso = false;
    bool isAccantonamentoTasse = false; // 👈 NOVITÀ: Interruttore Caso A

    final List<String> nomiConti = accounts.map((c) => c.title).toList();
    final TextEditingController importoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final walletProvider = context.read<WalletProvider>();
          final bool mostraPiva = widget.isPiva ?? walletProvider.isPartitaIVA;

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Giroconto Tra Conti', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
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

                  // 👈 NOVITÀ P.IVA: Interruttore Sposta Riserva Tasse (Visibile SOLO per P.IVA)
                  if (mostraPiva) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isAccantonamentoTasse 
                            ? const Color(0xFF3B82F6).withOpacity(0.12) 
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAccantonamentoTasse 
                              ? const Color(0xFF3B82F6).withOpacity(0.4) 
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sposta Riserva Tasse 🛡️',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Trasferisce il vincolo virtuale delle tasse sul conto di destinazione',
                                  style: TextStyle(color: Colors.white38, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isAccantonamentoTasse,
                            activeColor: const Color(0xFF3B82F6),
                            onChanged: (val) {
                              setDialogState(() => isAccantonamentoTasse = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  final importo = double.tryParse(importoController.text.replaceAll(',', '.')) ?? 0.0;
                  if (daConto != aConto && importo > 0) {
                    final provider = context.read<WalletProvider>();
                    
                    final accDa = accounts.firstWhere((a) => a.title == daConto);
                    final accA = accounts.firstWhere((a) => a.title == aConto);

                    // 🎯 Richiama la logica avanzata creata nel provider
                    provider.eseguiGiroconto(
                      daAccountId: accDa.id,
                      aAccountId: accA.id,
                      importo: importo,
                      isAccantonamentoTasse: isAccantonamentoTasse,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAccantonamentoTasse
                              ? 'Giroconto eseguito: ${importo.toStringAsFixed(2)} € riservati alle tasse!'
                              : 'Giroconto di ${importo.toStringAsFixed(2)} € eseguito!',
                        ),
                        backgroundColor: isAccantonamentoTasse 
                            ? const Color(0xFF3B82F6) 
                            : const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Esegui Giroconto', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    final walletProvider = context.watch<WalletProvider>();
    final double saldoTotale = walletProvider.patrimonioNetto;
    final accounts = walletProvider.accounts;

    // 🎯 La schermata obbedisce a quello che gli ordina la Home (widget.isPiva).
    // Se riceve 'false' (Dipendente), spegne tutto istantaneamente.
    final bool mostraPiva = widget.isPiva ?? walletProvider.isPartitaIVA;

    // 👈 NUOVO CALCOLO PRUDENZIALE: Somma le tasse lorde di tutti i conti ignorando l'acconto
    final double totaleTasseLorde = accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double nettoReale = saldoTotale - totaleTasseLorde;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 10, 
        vertical: isKeyboardOpen ? 10 : 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: double.infinity,
          height: screenSize.height * 0.88,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),

              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Gestione Conti',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _mostraDialogNuovoConto,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, color: Color(0xFF2DD4BF), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Nuovo Conto',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B).withOpacity(0.60),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('PATRIMONIO LIQUIDO TOTALE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${saldoTotale.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.sync_alt_rounded, color: Color(0xFF2DD4BF), size: 20),
                                            onPressed: () => _mostraDialogGiroconto(accounts),
                                            tooltip: 'Esegui Giroconto',
                                          ),
                                        ],
                                      ),

                                      // 👈 WIDGET P.IVA: NETTO SPENDIBILE (VERDE + MONEY) E FONDO TASSE (BLU + SALVADANAIO)
                                      if (mostraPiva) ...[
                                        const SizedBox(height: 12),
                                        const Divider(color: Colors.white12, height: 1),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 12),
                                                      SizedBox(width: 4),
                                                      Text('NETTO SPENDIBILE', style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${nettoReale.toStringAsFixed(2)} €',
                                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  const Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 12),
                                                      SizedBox(width: 4),
                                                      Text('FONDO TASSE DA VERSARE', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 8, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${totaleTasseLorde.toStringAsFixed(2)} €',
                                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('I TUOI CONTI & CARTE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                            Text('${accounts.length} attivi', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        ReorderableListView.builder(
                                          buildDefaultDragHandles: false, // 👈 RIMUOOVE LA LINETTA AUTOMATICA A DESTRA
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
                                            final bool isEspanso = _contoEspansoIndex == index;

                                            return AnimatedContainer(
                                              key: ValueKey(account.id),
                                              duration: const Duration(milliseconds: 200),
                                              margin: const EdgeInsets.only(bottom: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.35),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isEspanso ? account.color.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        if (_contoEspansoIndex == index) {
                                                          _contoEspansoIndex = null;
                                                        } else {
                                                          _contoEspansoIndex = index;
                                                          _scrollToOffset(120);
                                                        }
                                                      });
                                                    },
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(12),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.drag_handle_rounded, color: Colors.white24, size: 18),
                                                          const SizedBox(width: 8),

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
                                                                Text(account.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                                const SizedBox(height: 2),
                                                                Text(account.subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                                              ],
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                '${account.amount.toStringAsFixed(2)} €',
                                                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                              ),
                                                              // 👈 WIDGET P.IVA: Visibile SOLO sul Conto Principale
                                                              if (mostraPiva && (account.id == '1' || account.title.toLowerCase().contains('principale'))) ...[
                                                                const SizedBox(height: 3),
                                                                Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 10),
                                                                    const SizedBox(width: 2),
                                                                    Text(
                                                                      '${(account.amount - account.virtualTaxAmount).toStringAsFixed(0)} €',
                                                                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 10),
                                                                    const SizedBox(width: 2),
                                                                    Text(
                                                                      '${account.virtualTaxAmount.toStringAsFixed(0)} € tasse',
                                                                      style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                              Icon(
                                                                isEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                                                color: Colors.white38,
                                                                size: 16,
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  if (isEspanso) ...[
                                                    const Divider(color: Colors.white12, height: 1),
                                                    Container(
                                                      padding: const EdgeInsets.all(12),
                                                      color: Colors.black.withOpacity(0.15),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          InkWell(
                                                            onTap: () => _mostraDettaglioMovimentiConto(context, account),
                                                            borderRadius: BorderRadius.circular(10),
                                                            child: Container(
                                                              width: double.infinity,
                                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.3)),
                                                              ),
                                                              child: const Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(Icons.list_alt_rounded, color: Color(0xFF2DD4BF), size: 16),
                                                                  SizedBox(width: 6),
                                                                  Text(
                                                                    'Vedi Dettaglio Movimenti',
                                                                    style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),

                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: InkWell(
                                                                  onTap: () => _mostraDialogModificaConto(context, account),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.white.withOpacity(0.08),
                                                                      borderRadius: BorderRadius.circular(10),
                                                                      border: Border.all(color: Colors.white12),
                                                                    ),
                                                                    child: const Row(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      children: [
                                                                        Icon(Icons.edit_rounded, color: Colors.white70, size: 14),
                                                                        SizedBox(width: 6),
                                                                        Text('Modifica Conto', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),

                                                              InkWell(
                                                                onTap: () => _confermaEliminazioneConto(context, account),
                                                                borderRadius: BorderRadius.circular(10),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(8),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(0xFFEF4444).withOpacity(0.15),
                                                                    borderRadius: BorderRadius.circular(10),
                                                                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                                                                  ),
                                                                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
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
                          ),
                        ),
                      ),
                    ),

                    if (!isKeyboardOpen) ...[
                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B).withOpacity(0.65),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Annulla e Chiudi',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}