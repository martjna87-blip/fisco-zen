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
  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final patrimonioNetto = walletProvider.patrimonioNetto;
    final spesoBisogni = walletProvider.spesoBisogni;
    final spesoSvago = walletProvider.spesoSvago;
    final spesoRisparmi = walletProvider.spesoRisparmi;
    final movimenti = walletProvider.transactions;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: Stack(
        children: [
          // 1. SFONDO IMMERSIVO
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, -150),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1600585154526-990dced4db0d?q=80&w=1000&auto=format&fit=crop](https://images.unsplash.com/photo-1600585154526-990dced4db0d?q=80&w=1000&auto=format&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.65),
                        const Color(0xFF0A0A0C).withOpacity(0.85),
                        const Color(0xFF0A0A0C),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. CONTENUTO SCROLLABILE
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER SALDO NETTO
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Portafoglio netto',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${patrimonioNetto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // PULSANTE RIEPILOGO ANNUALE
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AnnualSummarySheet(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.show_chart_rounded, size: 18, color: Color(0xFF2DD4BF)),
                          label: const Text(
                            'Riepilogo Annuale',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.white.withOpacity(0.18)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                  
                  // 3 QUADRANTI AZIONE (MOVIMENTO, CONTI, BUDGET)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionSquareCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Aggiungi\nmovimento',
                          value: 'Entrata / Spesa',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddMovementSheet(),
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
                              builder: (context) => const ManageAccountsSheet(),
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

                  // BARRA EQUILIBRIO PORTAFOGLIO
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

                  // GRAFICO A TORTA (REGOLA 50 / 30 / 20)
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
                            // Donut Chart Custom
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
                            // Legenda
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

                  // CONTI E CARTE
                  const Text(
                    'CONTI & CARTE',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  // 🟢 MAPPA DINAMICA DAL PROVIDER
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

                  // ULTIMI MOVIMENTI
                  const Text(
                    'ULTIMI MOVIMENTI',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),

                  // 🟢 CODICE DINAMICO:
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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

// PAINTER PER IL GRAFICO A TORTA (DONUT CHART)
class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.reduce((a, b) => a + b);
   
    // 🛡️ SICUREZZA AGGIUNTA: Blocca il disegno se il totale è zero per evitare errori matematici
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