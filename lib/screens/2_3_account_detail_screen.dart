import 'package:flutter/material.dart';
import '../widgets_shared/app_popup_wrapper.dart';

class AccountDetailScreen extends StatelessWidget {
  final Map<String, dynamic> conto;

  const AccountDetailScreen({super.key, required this.conto});

  @override
  Widget build(BuildContext context) {
    // Dati simulati di movimenti raggruppati per mese
    final List<Map<String, dynamic>> sezioniMesi = [
      {
        'mese': 'Luglio 2026',
        'totaleMese': 2149.80,
        'movimenti': [
          {'titolo': 'Supermercato Esselunga', 'data': '18 Lug 2026', 'importo': -84.50, 'tipo': 'spesa', 'icona': Icons.shopping_cart_outlined},
          {'titolo': 'Stipendio Luglio', 'data': '15 Lug 2026', 'importo': 2400.00, 'tipo': 'entrata', 'icona': Icons.work_outline},
          {'titolo': 'Bolletta Luce & Gas', 'data': '10 Lug 2026', 'importo': -120.30, 'tipo': 'spesa', 'icona': Icons.bolt_outlined},
          {'titolo': 'Ristorante Sushi', 'data': '05 Lug 2026', 'importo': -45.40, 'tipo': 'spesa', 'icona': Icons.restaurant_outlined},
        ]
      },
      {
        'mese': 'Giugno 2026',
        'totaleMese': 1820.00,
        'movimenti': [
          {'titolo': 'Assicurazione Auto', 'data': '28 Giu 2026', 'importo': -450.00, 'tipo': 'spesa', 'icona': Icons.verified_user_outlined},
          {'titolo': 'Stipendio Giugno', 'data': '15 Giu 2026', 'importo': 2400.00, 'tipo': 'entrata', 'icona': Icons.work_outline},
          {'titolo': 'Rifornimento Carburante', 'data': '02 Giu 2026', 'importo': -130.00, 'tipo': 'spesa', 'icona': Icons.local_gas_station_outlined},
        ]
      },
      {
        'mese': 'Maggio 2026',
        'totaleMese': -110.00,
        'movimenti': [
          {'titolo': 'Acquisto Abbigliamento', 'data': '20 Mag 2026', 'importo': -110.00, 'tipo': 'spesa', 'icona': Icons.shopping_bag_outlined},
        ]
      },
    ];

    final Color coloreConto = conto['colore'] as Color? ?? const Color(0xFF2DD4BF);
    final IconData iconaConto = conto['icona'] as IconData? ?? Icons.account_balance_outlined;

    return AppPopupWrapper(
      title: conto['nome']?.toString() ?? 'Dettaglio Conto',
      child: Column(
        children: [
          // 📌 CARD RIASSUNTIVA DEL CONTO
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
                          '${((conto['saldo'] ?? 0.0) as double).toStringAsFixed(2)} €',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${conto['tipo']} • Aperto il ${conto['dataCreazione']}',
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

          // 📌 LISTA RAGGRUPPATA PER MESE
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: sezioniMesi.length,
              itemBuilder: (context, indexSezione) {
                final sezione = sezioniMesi[indexSezione];
                final List<Map<String, dynamic>> movimenti = sezione['movimenti'];
                final double totaleMese = sezione['totaleMese'];
                final bool isPositivo = totaleMese >= 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INTESTAZIONE MESE + BILANCIO MENSILE
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sezione['mese'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPositivo ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${isPositivo ? '+' : ''}${totaleMese.toStringAsFixed(2)} €',
                              style: TextStyle(
                                color: isPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LISTA MOVIMENTI DEL MESE
                    ...movimenti.map((m) {
                      final isSpesa = m['tipo'] == 'spesa';

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
                                color: isSpesa ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(m['icona'] as IconData, color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['titolo'].toString(), 
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m['data'].toString(), 
                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isSpesa ? '' : '+'}${(m['importo'] as double).toStringAsFixed(2)} €',
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
              },
            ),
          ),
        ],
      ),
    );
  }