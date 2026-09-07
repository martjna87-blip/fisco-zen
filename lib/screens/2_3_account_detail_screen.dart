import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_popup_wrapper.dart';

class AccountDetailScreen extends StatefulWidget {
  final Map<String, dynamic> conto;

  const AccountDetailScreen({super.key, required this.conto});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  // 📁 Mantiene traccia degli anni passati espansi dall'utente
  final Set<int> _anniEspansi = {};

  final List<String> _nomiMesi = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final String accountId = widget.conto['id']?.toString() ?? '';
    final String accountTitle = widget.conto['nome']?.toString() ?? widget.conto['title']?.toString() ?? '';

    // 🎯 Recupera l'account reale per leggere il saldo aggiornato
    final accountReale = walletProvider.accounts.firstWhere(
      (a) => a.id == accountId || a.title == accountTitle,
      orElse: () => AccountModel(
        id: accountId,
        title: accountTitle,
        subtitle: 'Conto',
        amount: (widget.conto['saldo'] as num?)?.toDouble() ?? 0.0,
        color: widget.conto['colore'] as Color? ?? const Color(0xFF2DD4BF),
      ),
    );

    final Color coloreConto = accountReale.color;
    final IconData iconaConto = widget.conto['icona'] as IconData? ?? Icons.account_balance_wallet_rounded;

    // 🔍 Filtra i movimenti di questo specifico conto (escludendo le regole astratte)
    final tuttiMovimentiConto = walletProvider.transactions.where((tx) {
      if (tx.id.startsWith('rule_')) return false;
      return tx.accountId == accountReale.id ||
          tx.title.toLowerCase().contains(accountReale.title.toLowerCase());
    }).toList();

    tuttiMovimentiConto.sort((a, b) => b.date.compareTo(a.date));

    // 🗓️ Raggruppa i movimenti per Anno -> Mese
    final Map<int, Map<int, List<TransactionModel>>> mappaAnnoMese = {};

    for (var tx in tuttiMovimentiConto) {
      final anno = tx.date.year;
      final mese = tx.date.month;

      mappaAnnoMese.putIfAbsent(anno, () => {});
      mappaAnnoMese[anno]!.putIfAbsent(mese, () => []);
      mappaAnnoMese[anno]![mese]!.add(tx);
    }

    final int annoCorrente = DateTime.now().year;
    final List<int> anniPresenti = mappaAnnoMese.keys.toList()..sort((a, b) => b.compareTo(a));

    return AppPopupWrapper(
      title: accountReale.title,
      child: Column(
        children: [
          // 📌 CARD HEADER RIASSUNTIVA CONTO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: coloreConto.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconaConto, color: coloreConto, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formattaValuta(accountReale.amount),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${accountReale.subtitle} • ${tuttiMovimentiConto.length} moviment${tuttiMovimentiConto.length == 1 ? "o" : "i"} registrat${tuttiMovimentiConto.length == 1 ? "o" : "i"}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 📌 ALBERO STORICO MOVIMENTI MULTI-ANNO
          Expanded(
            child: tuttiMovimentiConto.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, color: Colors.white.withOpacity(0.2), size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          'Nessun movimento registrato su questo conto.',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: anniPresenti.length,
                    itemBuilder: (context, indexAnno) {
                      final anno = anniPresenti[indexAnno];
                      final mesiDellAnno = mappaAnnoMese[anno]!;
                      final bool isAnnoCorrente = anno == annoCorrente;
                      final bool isEspanso = isAnnoCorrente || _anniEspansi.contains(anno);

                      // Calcola il bilancio totale dell'anno
                      double totaleAnno = 0.0;
                      mesiDellAnno.forEach((_, listaTx) {
                        for (var tx in listaTx) {
                          totaleAnno += tx.isIncome ? tx.amount : -tx.amount;
                        }
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📁 HEADER ANNO PASSATO (ESPANDIBILE)
                          if (!isAnnoCorrente) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_anniEspansi.contains(anno)) {
                                    _anniEspansi.remove(anno);
                                  } else {
                                    _anniEspansi.add(anno);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isEspanso ? Icons.folder_open_rounded : Icons.folder_rounded,
                                          color: const Color(0xFF2DD4BF),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'ARCHIVIO ANNO $anno',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${totaleAnno >= 0 ? '+' : '-'}${_formattaValuta(totaleAnno)}',
                                          style: TextStyle(
                                            color: totaleAnno >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          isEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: const Color(0xFF2DD4BF),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // 📅 LISTA MESI ED ELEMENTI DELL'ANNO
                          if (isEspanso) ...[
                            ...mesiDellAnno.keys.toList()
                              ..sort((a, b) => b.compareTo(a))
                              ..map((m) {
                                final listaTxMese = mesiDellAnno[m]!;

                                double totaleMese = 0.0;
                                for (var tx in listaTxMese) {
                                  totaleMese += tx.isIncome ? tx.amount : -tx.amount;
                                }

                                final bool isPositivo = totaleMese >= 0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // INTESTAZIONE MESE
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4, right: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_nomiMesi[m - 1].toUpperCase()} $anno',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isPositivo
                                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                                  : const Color(0xFFEF4444).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${isPositivo ? '+' : '-'}${_formattaValuta(totaleMese)}',
                                              style: TextStyle(
                                                color: isPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // SINGOLI MOVIMENTI DEL MESE
                                    ...listaTxMese.map((tx) {
                                      final bool isSpesa = !tx.isIncome;
                                      final g = tx.date.day.toString().padLeft(2, '0');
                                      final mStr = _nomiMesi[tx.date.month - 1].substring(0, 3);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.30),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isSpesa
                                                    ? const Color(0xFFEF4444).withOpacity(0.15)
                                                    : const Color(0xFF10B981).withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isSpesa ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                                color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx.title,
                                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$g $mStr $anno • ${tx.category}',
                                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${isSpesa ? '-' : '+'}${_formattaValuta(tx.amount)}',
                                              style: TextStyle(
                                                color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                );
                              }),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}