import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets_shared/app_notifications.dart';

class ProUpgradeSheet extends StatelessWidget {
  final String funzionalita;

  const ProUpgradeSheet({
    super.key,
    required this.funzionalita,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: SafeArea( // 🛡️ PROTEZIONE ANTI-NOTCH PER LA 'X'
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: isKeyboardOpen ? screenSize.height * 0.88 : screenSize.height * 0.78,
            color: const Color(0xFF141417),
            child: Stack(
              children: [
                // SFONDO FOTOGRAFICO CLICCABILE PER CHIUDERE
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1557804506-669a67965ba0?q=80&w=1000&auto=format&fit=crop',
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

                // CARD FROSTED GLASS
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // TASTO CHIUDI (X) CON PROTEZIONE NOTCH
                      Align(
                        alignment: Alignment.topRight,
                        child: Material(
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
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141417).withOpacity(0.75),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  // ICONA CROWN PRO
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                                    ),
                                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 32),
                                  ),

                                  const SizedBox(height: 10),

                                  const Text(
                                    'Sblocca FiscOn PRO',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    'La funzione "$funzionalita" richiede un piano attivo.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),

                                  const SizedBox(height: 16),

                                  // LISTA VANTAGGI PRO
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

                                  // SCHEDA PREZZO
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
                                    height: 44,
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
                                      child: const Text('Prova Gratis per 7 Giorni', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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