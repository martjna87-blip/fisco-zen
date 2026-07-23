import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class ManageAccountsSheet extends StatefulWidget {
  const ManageAccountsSheet({super.key});

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

  // ✏️ DIALOG MODIFICA IMPORTO SALDO CONTO
  void _mostraDialogModificaSaldo(BuildContext context, AccountModel account) {
    final TextEditingController controller = TextEditingController(
      text: account.amount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifica Saldo: ${account.title}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Nuovo Saldo Apertura (€)',
            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final nuovoSaldo = double.tryParse(controller.text.replaceAll(',', '.')) ?? account.amount;
              context.read<WalletProvider>().updateAccountAmount(account.id, nuovoSaldo);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saldo di "${account.title}" aggiornato!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salva Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // FUNZIONE PER APRIRE IL DETTAGLIO MOVIMENTI DEL CONTO REALI
  void _mostraDettaglioMovimentiConto(BuildContext context, AccountModel account) {
    final transactions = context.read<WalletProvider>().transactions;
    final movimentiConto = transactions.where((t) => t.title.contains(account.title) || account.title.contains(t.title)).toList();

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
              const SizedBox(height: 12),
              movimentiConto.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Nessun movimento registrato su questo conto.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : Column(
                      children: movimentiConto.map((tx) {
                        final String sign = tx.isIncome ? '+' : '-';
                        final String impFormatted = '$sign${tx.amount.toStringAsFixed(2)} €';
                        final String dataStr = '${tx.date.day}/${tx.date.month}';
                        return _buildRigaMovimento(tx.title, impFormatted, dataStr, tx.isIncome);
                      }).toList(),
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

  // DIALOG NUOVO CONTO CON SELETTORE IN-LINE INTEGRATO
  void _mostraDialogNuovoConto() {
    final TextEditingController nomeController = TextEditingController();
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
                TextField(
                  controller: nomeController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Nome Conto o Carta',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
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
                    prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Colors.white54, size: 16),
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
                final saldo = double.tryParse(saldoController.text.replaceAll(',', '.')) ?? 0.0;

                // 1. Controlla che il campo nome non sia vuoto
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

                  // 2. Registra il conto nel Provider
                  provider.addAccount(
                    title: nome,
                    subtitle: tipoSelezionato,
                    initialAmount: saldo,
                    color: const Color(0xFF2DD4BF),
                  );

                  // 3. Se c'è un saldo iniziale, registra la transazione
                  if (saldo > 0) {
                    provider.addTransaction(
                      title: 'Saldo Iniziale: $nome',
                      amount: saldo,
                      isIncome: true,
                      category: 'Risparmi',
                    );
                  }

                  // 4. Chiudi la finestra di dialogo
                  Navigator.pop(context);

                  // 5. Avviso di successo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Conto "$nome" creato con successo!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  // 🔴 Se manca addAccount o c'è un errore nel provider, l'app mostra la causa precisa in un banner rosso
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

  // DIALOG GIROCONTO CON SELETTORI IN-LINE INTEGRATI
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
        builder: (context, setDialogState) => AlertDialog(
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

                  provider.addTransaction(
                    title: 'Giroconto verso ${accA.title}',
                    amount: importo,
                    isIncome: false,
                    category: 'Risparmi',
                    accountId: accDa.id,
                  );

                  provider.addTransaction(
                    title: 'Giroconto da ${accDa.title}',
                    amount: importo,
                    isIncome: true,
                    category: 'Risparmi',
                    accountId: accA.id,
                  );

                  Navigator.pop(context);
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
        ),
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

    // 📍 STRUTTURA DIALOG A DOPPIO RIQUADRO IDENTICA A REGISTRA FATTURA
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
              // 1. IMMAGINE SFONDO ATMOSFERICA
              Positioned.fill(
                child: Image.network(
                  'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),

              // 2. OVERLAY SCURO SFUMATO
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                ),
              ),

              // 3. CONTENUTO CON HEADER CIRCOLARE E SCHEDE GLASS
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // --- HEADER CON BOTTONE (X) CIRCOLARE IDENTICO A REGISTRA FATTURA ---
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

                    // ==========================================
                    // 🔲 RIQUADRO 1: CORPO PRINCIPALE GLASSMORPHIC
                    // ==========================================
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
                                // INNER CARD SALDO COMPLESSIVO
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Row(
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
                                ),

                                const SizedBox(height: 14),

                                // CONTENUTO SCROLLABILE LISTA CONTI
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

                                        // LISTA CONTI DINAMICA DAL PROVIDER
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: accounts.length,
                                          itemBuilder: (context, index) {
                                            final account = accounts[index];
                                            final bool isEspanso = _contoEspansoIndex == index;

                                            return AnimatedContainer(
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
                                                  // RIGA TESTATA CLICCABILE
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
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: account.color.withOpacity(0.15),
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: Icon(
                                                              account.id == '1'
                                                                  ? Icons.account_balance_outlined
                                                                  : (account.id == '2' ? Icons.credit_card_rounded : Icons.savings_outlined),
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

                                                  // CONTENUTO IN-LINE INTEGRATO APPARTENENTE ALLA CELLA
                                                  if (isEspanso) ...[
                                                    const Divider(color: Colors.white12, height: 1),
                                                    Container(
                                                      padding: const EdgeInsets.all(12),
                                                      color: Colors.black.withOpacity(0.15),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          // 1. PULSANTE VEDI DETTAGLIO MOVIMENTI
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

                                                          // 2. PULSANTI AZIONE: MODIFICA SALDO E ELIMINA CONTO
                                                          Row(
                                                            children: [
                                                              // TASTO MATITA: MODIFICA IMPORTO
                                                              Expanded(
                                                                child: InkWell(
                                                                  onTap: () => _mostraDialogModificaSaldo(context, account),
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
                                                                        Text('Modifica Saldo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),

                                                              // TASTO CESTINO: ELIMINA CONTO
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
                                                ], // 👈 QUESTA ERA LA PARENTESI QUADRA MANCANTE!
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

                      // ==========================================
                      // 🔲 RIQUADRO 2: TASTO CHIUDI BOTTOM GLASS
                      // ==========================================
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