import 'package:flutter/material.dart';

class AccountDetailScreen extends StatelessWidget {
  final Map<String, dynamic> conto;

  const AccountDetailScreen({super.key, required this.conto});

  @override
  Widget build(BuildContext context) {
    // Dati simulati di movimenti raggruppati per mese (senza il prefisso '+' nei numeri)
    final List<Map<String, dynamic>> sezioniMesi = [
      {
        'mese': 'Luglio 2026',
        'totaleMese': 2149.80, // 👈 Corretto qui!
        'movimenti': [
          {'titolo': 'Supermercato Esselunga', 'data': '18 Lug 2026', 'importo': -84.50, 'tipo': 'spesa', 'icona': Icons.shopping_cart_outlined},
          {'titolo': 'Stipendio Luglio', 'data': '15 Lug 2026', 'importo': 2400.00, 'tipo': 'entrata', 'icona': Icons.work_outline},
          {'titolo': 'Bolletta Luce & Gas', 'data': '10 Lug 2026', 'importo': -120.30, 'tipo': 'spesa', 'icona': Icons.bolt_outlined},
          {'titolo': 'Ristorante Sushi', 'data': '05 Lug 2026', 'importo': -45.40, 'tipo': 'spesa', 'icona': Icons.restaurant_outlined},
        ]
      },
      {
        'mese': 'Giugno 2026',
        'totaleMese': 1820.00, // 👈 Corretto qui!
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

    return Scaffold(
      backgroundColor: const Color(0xFF141417),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141417),
        elevation: 0,
        title: Text(conto['nome'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // CARD RIASSUNTIVA DEL CONTO
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (conto['colore'] as Color).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(conto['icona'], color: conto['colore'], size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${(conto['saldo'] as double).toStringAsFixed(2)} €',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${conto['tipo']} • Aperto il ${conto['dataCreazione']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // LISTA RAGGRUPPATA PER MESE
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sezioniMesi.length,
              itemBuilder: (context, indexSezione) {
                final sezione = sezioniMesi[indexSezione];
                final List<Map<String, dynamic>> movimenti = sezione['movimenti'];
                final double totaleMese = sezione['totaleMese'];
                final bool isPositivo = totaleMese >= 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INTESTAZIONE MESE + BILANCIO MENSILE (BLINDATO)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sezione['mese'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSpesa ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(m['icona'], color: isSpesa ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['titolo'], 
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m['data'], 
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
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
                                fontSize: 15,
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
}