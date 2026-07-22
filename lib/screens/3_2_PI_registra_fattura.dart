import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class RegistraFatturaSheet extends StatefulWidget {
  final Function(String cliente, double importo, String data)? onFatturaSalvata;

  const RegistraFatturaSheet({
    super.key,
    this.onFatturaSalvata,
  });

  @override
  State<RegistraFatturaSheet> createState() => _RegistraFatturaSheetState();
}

class _RegistraFatturaSheetState extends State<RegistraFatturaSheet> {
  final _clienteController = TextEditingController();
  final _importoController = TextEditingController();
  bool _isManualOpen = true;

  @override
  void dispose() {
    _clienteController.dispose();
    _importoController.dispose();
    super.dispose();
  }

  void _salvaFattura() {
    final cliente = _clienteController.text.trim();
    final importoText = _importoController.text.trim();

    if (cliente.isEmpty || importoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci nome cliente e importo valido'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final double? importo = double.tryParse(importoText.replaceAll(',', '.'));
    if (importo == null || importo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Importo non valido'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Provider.of<WalletProvider>(context, listen: false).addFatturaPiva(
      cliente: cliente,
      importo: importo,
    );

    if (widget.onFatturaSalvata != null) {
      widget.onFatturaSalvata!(cliente, importo, 'Oggi');
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fattura di $cliente (€$importoText) registrata!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Se la tastiera è aperta, occupiamo più altezza e attacchiamo il box in alto
    final isKeyboardOpen = bottomInset > 0;
    final dialogHeight = isKeyboardOpen ? screenSize.height * 0.72 : screenSize.height * 0.84;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 10, 
        vertical: isKeyboardOpen ? 10 : 14,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: double.infinity,
            height: dialogHeight,
            child: Stack(
              children: [
                // 1. IMMAGINE DI SFONDO ATMOSFERICA
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

                // 3. CONTENUTO CON HEADER FLUTTUANTE & RIQUADRI GLASS
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // --- HEADER FLUTTUANTE ---
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
                                'Registra Fattura',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ==========================================
                      // 🔲 RIQUADRO 1: MODALITÀ DI REGISTRAZIONE
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
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SCEGLI MODALITÀ DI REGISTRAZIONE',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // OPTION PRO: FOTO
                                    _buildOptionTile(
                                      icon: Icons.camera_alt_outlined,
                                      color: const Color(0xFFF59E0B),
                                      title: 'Scansiona con Fotocamera',
                                      subtitle: 'Acquisizione automatica da cartaceo (OCR)',
                                      isPro: true,
                                    ),

                                    const SizedBox(height: 8),

                                    // OPTION PRO: FILE
                                    _buildOptionTile(
                                      icon: Icons.note_add_outlined,
                                      color: const Color(0xFFF59E0B),
                                      title: 'Carica File / PDF / XML',
                                      subtitle: 'Importa da cassetto fiscale o file locale',
                                      isPro: true,
                                    ),

                                    const SizedBox(height: 8),

                                    // INSERIMENTO MANUALE (ACCORDION)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _isManualOpen
                                              ? const Color(0xFF2DD4BF).withOpacity(0.4)
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                        child: ExpansionTile(
                                          initiallyExpanded: true,
                                          onExpansionChanged: (val) => setState(() => _isManualOpen = val),
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2DD4BF), size: 20),
                                          ),
                                          title: const Text(
                                            'Inserimento Manuale',
                                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: const Text(
                                            'Compila dati cliente e importo a mano',
                                            style: TextStyle(color: Colors.white54, fontSize: 10),
                                          ),
                                          childrenPadding: const EdgeInsets.all(12),
                                          children: [
                                            // CAMPO CLIENTE
                                            TextField(
                                              controller: _clienteController,
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                              scrollPadding: const EdgeInsets.only(bottom: 80),
                                              decoration: InputDecoration(
                                                labelText: 'Nome Cliente / Azienda',
                                                labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2DD4BF), size: 18),
                                                filled: true,
                                                fillColor: Colors.black.withOpacity(0.4),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              ),
                                            ),
                                            const SizedBox(height: 10),

                                            // CAMPO IMPORTO
                                            TextField(
                                              controller: _importoController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                              scrollPadding: const EdgeInsets.only(bottom: 80),
                                              decoration: InputDecoration(
                                                labelText: 'Importo Lordo (€)',
                                                labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                                                prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 18),
                                                filled: true,
                                                fillColor: Colors.black.withOpacity(0.4),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              ),
                                            ),
                                            const SizedBox(height: 14),

                                            // BOTTONE SALVA
                                            SizedBox(
                                              width: double.infinity,
                                              height: 44,
                                              child: ElevatedButton(
                                                onPressed: _salvaFattura,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2DD4BF),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  elevation: 0,
                                                ),
                                                child: const Text(
                                                  'Registra e Salva Fattura',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
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
                      ),

                      // Mostra il tasto chiudi inferiore solo se la tastiera NON è aperta
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
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isPro,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (isPro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}