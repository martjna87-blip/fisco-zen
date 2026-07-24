import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '2_1_wallet_add_movement.dart';
import '2_2_wallet_manage_accounts.dart';
import '2_4_wallet_budget_pilot.dart';
import '2_5_wallet_annual_summary.dart';

class WalletScreen extends StatefulWidget {
  final bool isPiva;

  const WalletScreen({super.key, this.isPiva = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // 🛡️ DIALOG RAPIDO CON GOAL TRACKER & FEEDBACK PERCENTUALE
  void _mostraDialogAccantonamentoTasse(BuildContext context, double tasseScoperte) {
    final walletProvider = context.read<WalletProvider>();
    final accounts = walletProvider.accounts;

    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi avere almeno due conti per accantonare le tasse.')),
      );
      return;
    }

    final TextEditingController importoController = TextEditingController(
      text: tasseScoperte.toStringAsFixed(2),
    );

    final contoConTasse = accounts.firstWhere(
      (a) => a.virtualTaxAmount > 0 && !a.title.toLowerCase().contains('salvadanaio'),
      orElse: () => accounts[0],
    );

    final salvadanaioTasse = accounts.firstWhere(
      (a) => a.title.toLowerCase().contains('salvadanaio tasse'),
      orElse: () => accounts.length > 1 ? accounts[1] : accounts[0],
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final importoInserito = double.tryParse(importoController.text.replaceAll(',', '.')) ?? 0.0;
          
          final double percentuale = tasseScoperte > 0 ? (importoInserito / tasseScoperte).clamp(0.0, 2.0) : 1.0;
          final double percentualeText = tasseScoperte > 0 ? (importoInserito / tasseScoperte * 100) : 100;
          final double extraCuscinetto = importoInserito > tasseScoperte ? importoInserito - tasseScoperte : 0.0;

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 22),
                SizedBox(width: 8),
                Text('Accantona Tasse', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasse calcolate (Codice Ateco): ${tasseScoperte.toStringAsFixed(2)} €',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Copertura: ${percentualeText.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: importoInserito >= tasseScoperte ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (extraCuscinetto > 0)
                            Text(
                              '+${extraCuscinetto.toStringAsFixed(0)} € Cuscinetto',
                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (percentuale / 1.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            importoInserito >= tasseScoperte ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: importoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Importo da accantonare (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 20),
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
                  if (importoInserito > 0) {
                    walletProvider.eseguiGiroconto(
                      daAccountId: contoConTasse.id,
                      aAccountId: salvadanaioTasse.id,
                      importo: importoInserito,
                      isAccantonamentoTasse: true,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          extraCuscinetto > 0
                              ? 'Messo al sicuro il 100% delle tasse + ${extraCuscinetto.toStringAsFixed(0)} € di cuscinetto! 🛡️'
                              : 'Hai messo al sicuro ${importoInserito.toStringAsFixed(2)} €! 🎉',
                        ),
                        backgroundColor: const Color(0xFF3B82F6),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Metti al Sicuro', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final patrimonioNetto = walletProvider.patrimonioNetto;
    final spesoBisogni = walletProvider.spesoBisogni;
    final spesoSvago = walletProvider.spesoSvago;
    final spesoRisparmi = walletProvider.spesoRisparmi;
    final movimenti = walletProvider.transactions;
    
    final double tasseTotaliCalcolate = walletProvider.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double riservaGiaAccantonata = walletProvider.accounts
        .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, acc) => sum + acc.amount);

    final double residuoTasseDaCoprire = (tasseTotaliCalcolate - riservaGiaAccantonata).clamp(0.0, double.infinity);
    final double nettoReale = patrimonioNetto - tasseTotaliCalcolate;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 🎯 HEADER PORTAFOGLIO (STESSA STRUTTURA SPECULARE 280PX)
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. SFONDO IMMERSIVO
                Container(
                  height: 280,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1600585154526-990dced4db0d?q=80&w=1000&auto=format&fit=crop',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.45,
                    ),
                  ),
                ),
                // 2. GRADIENTE SCURO
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0A0A0C).withOpacity(0.5),
                        const Color(0xFF0A0A0C),
                      ],
                    ),
                  ),
                ),

                // 🏷️ 3. PILLOLA RIEPILOGO IN ALTO A DESTRA
                Positioned(
                  top: 10,
                  right: 16,
                  child: SafeArea(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnnualSummarySheet(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFF2DD4BF)),
                      label: const Text(
                        'Riepilogo',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),

                // 🎯 4. CONTENUTO CENTRATO CLEAN
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Portafoglio netto',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${patrimonioNetto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        
                        if (widget.isPiva) ...[
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 12),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${nettoReale.toStringAsFixed(0)} €',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 12),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${tasseTotaliCalcolate.toStringAsFixed(0)} €',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  if (residuoTasseDaCoprire > 0) 
                                    InkWell(
                                      onTap: () => _mostraDialogAccantonamentoTasse(context, residuoTasseDaCoprire),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                                        ),
                                        child: const Text(
                                          'Accantona',
                                          style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                                          SizedBox(width: 3),
                                          Text(
                                            'Protette',
                                            style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // CONTENUTO SCROLLABILE SPECULARE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 🛡️ 1. SERBATOIO RISERVA TASSE (In cima al contenuto)
                  if (widget.isPiva) ...[
                    Builder(
                      builder: (context) {
                        final double riservaAccantonata = walletProvider.accounts
                            .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
                            .fold(0.0, (sum, acc) => sum + acc.amount);

                        final double percentuale = tasseTotaliCalcolate > 0 ? (riservaAccantonata / tasseTotaliCalcolate).clamp(0.0, 2.0) : 1.0;
                        final double percentualeText = tasseTotaliCalcolate > 0 ? (riservaAccantonata / tasseTotaliCalcolate * 100) : 100;
                        final double cuscinettoExtra = riservaAccantonata > tasseTotaliCalcolate ? riservaAccantonata - tasseTotaliCalcolate : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141417).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Serbatoio Riserva Tasse',
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: percentualeText >= 100 
                                          ? const Color(0xFF10B981).withOpacity(0.15) 
                                          : const Color(0xFFF59E0B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${percentualeText.toStringAsFixed(0)}% Coperto',
                                      style: TextStyle(
                                        color: percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (percentuale / 1.0).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Dovuto Ateco: ${tasseTotaliCalcolate.toStringAsFixed(0)} €',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  Text(
                                    'In Salvadanaio: ${riservaAccantonata.toStringAsFixed(0)} €',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              if (cuscinettoExtra > 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🛡️ Cuscinetto di sicurezza extra: +${cuscinettoExtra.toStringAsFixed(2)} €',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // 2. 3 QUADRANTI AZIONE (SUBITO SOTTO IL SERBATOIO ALLA STESSA ALTEZZA SPECULARE)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionSquareCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Movimenti',
                          value: 'Entrata / Uscita',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddMovementSheet(initialTab: 'riepilogo'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionSquareCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Gestione\nConti',
                          value: '3 Attivi',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ManageAccountsSheet(isPiva: widget.isPiva),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionSquareCard(
                          icon: Icons.pie_chart_outline_rounded,
                          title: 'Pilotaggio\nBudget',
                          value: 'Pianificazione',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const BudgetPilotSheet(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. BARRA EQUILIBRIO
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141417).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Equilibrio Portafoglio',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '880,00 € / 5.120 €',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 880 / 5120,
                            minHeight: 6,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. GRAFICO A TORTA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141417).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RIPARTIZIONE BUDGET (50 / 30 / 20)',
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CustomPaint(
                                painter: DonutChartPainter(
                                  values: [spesoBisogni, spesoSvago, spesoRisparmi],
                                  colors: const [Color(0xFF2DD4BF), Color(0xFFF59E0B), Color(0xFF3B82F6)],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLegendItem('50% Bisogni', '${spesoBisogni.toInt()} €', const Color(0xFF2DD4BF)),
                                  const SizedBox(height: 10),
                                  _buildLegendItem('30% Svago', '${spesoSvago.toInt()} €', const Color(0xFFF59E0B)),
                                  const SizedBox(height: 10),
                                  _buildLegendItem('20% Risparmi', '${spesoRisparmi.toInt()} €', const Color(0xFF3B82F6)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'CONTI & CARTE',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  ...walletProvider.accounts.map((acc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildAccountCard(
                          icon: acc.id == '1'
                              ? Icons.account_balance_rounded
                              : (acc.id == '2' ? Icons.credit_card_rounded : Icons.savings_rounded),
                          title: acc.title,
                          subtitle: acc.subtitle,
                          amount: '${acc.amount.toStringAsFixed(2)} €',
                          color: acc.color,
                        ),
                      )),

                  const Text(
                    'ULTIMI MOVIMENTI',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  if (movimenti.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Nessun movimento presente', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    )
                  else
                    ...movimenti.map((tx) => _buildTransactionTile(
                          icon: tx.isIncome ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined,
                          title: tx.title,
                          subtitle: tx.subtitle,
                          amount: '${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} €',
                          isIncome: tx.isIncome,
                        )),

                  // 👈 5. SPAZIO INVISIBILE ABBONDANTE PER NON COPRIRE CON LA BOTTOM NAV BAR
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSquareCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141417).withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildAccountCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141417).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141417).withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFF10B981).withOpacity(0.12) : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isIncome ? const Color(0xFF10B981) : Colors.white70, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isIncome ? const Color(0xFF10B981) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.reduce((a, b) => a + b);
   
    if (total == 0) return;

    double startAngle = -pi / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(7, 7, size.width - 14, size.height - 14);

    for (int i = 0; i < values.length; i++) {
      final double sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}