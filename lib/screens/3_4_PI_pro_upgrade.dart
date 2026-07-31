import 'dart:ui';
import 'package:flutter/material.dart';

class ProUpgradeSheet extends StatelessWidget {
  final String funzionalita;

  const ProUpgradeSheet({
    super.key,
    required this.funzionalita,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SFONDO FOTOGRAFICO CLICCABILE PER CHIUDERE
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: screenHeight * 0.70,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1557804506-669a67965ba0?q=80&w=1000&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CARD FROSTED GLASS
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 18),
              child: Container(
                height: screenHeight * 0.66,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // TASTO CHIUDI
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // ICONA CROWN PRO
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 36),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Sblocca Fisco Zen PRO',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'La funzione "$funzionalita" richiede un piano attivo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),

                    const SizedBox(height: 20),

                    // LISTA VANTAGGI PRO (Ora scorrevole se lo schermo è corto!)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildProFeatureRow('Scansione OCR automatica da fotocamera'),
                            _buildProFeatureRow('Importazione diretta file PDF e XML Fatture'),
                            _buildProFeatureRow('Calcolo Tasse e INPS avanzato in tempo reale'),
                            _buildProFeatureRow('Export CSV/PDF per il tuo Commercialista'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // SCHEDA PREZZO (Blindata orizzontalmente)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Piano P.IVA Pro',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '4,99 € / mese',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // BOTTONE ACQUISTA
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          AppNotifications.mostraInAlto(
                            context, 
                            '⚡ Integrazione In-App Purchase in arrivo!', 
                            type: NotificationType.warning,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          elevation: 0,
                        ),
                        child: const Text('Prova Gratis per 7 Giorni', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11), // 👈 Corretto white80
            ),
          ),
        ],
      ),
    );
  }
}