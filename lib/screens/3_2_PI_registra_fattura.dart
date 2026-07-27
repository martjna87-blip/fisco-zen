import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';

class RegistraFatturaSheet extends StatefulWidget {
  final Function(String cliente, double importo, String dataFormattata)? onFatturaSalvata;

  const RegistraFatturaSheet({
    super.key,
    this.onFatturaSalvata,
  });

  @override
  State<RegistraFatturaSheet> createState() => _RegistraFatturaSheetState();
}

class _RegistraFatturaSheetState extends State<RegistraFatturaSheet> {
  final _numeroController = TextEditingController();
  final _clienteController = TextEditingController();
  final _importoController = TextEditingController();
  DateTime _dataSelezionata = DateTime.now();

  @override
  void dispose() {
    _numeroController.dispose();
    _clienteController.dispose();
    _importoController.dispose();
    super.dispose();
  }

  Future<void> _selezionaData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelezionata,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2DD4BF),
              onPrimary: Colors.black,
              surface: Color(0xFF18181B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF18181B),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dataSelezionata) {
      setState(() {
        _dataSelezionata = picked;
      });
    }
  }

  String _formattaData(DateTime dt) {
    final giorno = dt.day.toString().padLeft(2, '0');
    final mese = dt.month.toString().padLeft(2, '0');
    return '$giorno/$mese/${dt.year}';
  }

  void _mostraPaywallPro(String funzionalita) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF18181B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA855F7), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Sblocca $funzionalita',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Importa le fatture in 2 secondi senza digitare nulla a mano grazie all\'Intelligenza Artificiale.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usa il tasto PRO/FREE nell\'Header della Home per provare la modalità IA!'),
                    backgroundColor: Color(0xFFA855F7),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Passa a PRO (7 Giorni Gratis)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _salvaFattura() {
    final numero = _numeroController.text.trim();
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

    final dataFormattata = _formattaData(_dataSelezionata);

    Provider.of<WalletProvider>(context, listen: false).addFatturaPiva(
      cliente: cliente,
      importo: importo,
      data: dataFormattata,
      numero: numero.isNotEmpty ? numero : null,
    );

    if (widget.onFatturaSalvata != null) {
      try {
        widget.onFatturaSalvata!(cliente, importo, dataFormattata);
      } catch (_) {}
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fattura ${numero.isNotEmpty ? "#$numero " : ""}di $cliente del $dataFormattata registrata!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<WalletProvider>().isProUser;
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    final isKeyboardOpen = bottomInset > 0;
    final dialogHeight = isKeyboardOpen ? screenSize.height * 0.78 : screenSize.height * 0.82;

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
                      // HEADER CON TASTO "X"
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
                                      'ACQUISIZIONE RAPIDA IA',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // 🎯 CARD PRO AFFIANCATE
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildProCard(
                                            icon: Icons.camera_alt_outlined,
                                            title: 'Fotocamera',
                                            subtitle: 'Scan OCR',
                                            isPro: isPro,
                                            onTap: () {
                                              if (isPro) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Apertura fotocamera OCR...')),
                                                );
                                              } else {
                                                _mostraPaywallPro('Scansione OCR');
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildProCard(
                                            icon: Icons.note_add_outlined,
                                            title: 'Carica File',
                                            subtitle: 'PDF / XML',
                                            isPro: isPro,
                                            onTap: () {
                                              if (isPro) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Apertura selettore file...')),
                                                );
                                              } else {
                                                _mostraPaywallPro('Importazione PDF/XML');
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(color: Colors.white12, height: 1),
                                    const SizedBox(height: 14),

                                    const Text(
                                      'INSERIMENTO MANUALE',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // 1. RIGA NUMERO E DATA AFFIANCATI (50/50)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _numeroController,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                            decoration: _buildInputDecoration('N° Fattura', Icons.tag_rounded),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _selezionaData(context),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.4),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DD4BF), size: 16),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _formattaData(_dataSelezionata),
                                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // 2. CLIENTE
                                    TextField(
                                      controller: _clienteController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Nome Cliente / Azienda', Icons.person_outline),
                                    ),
                                    const SizedBox(height: 10),

                                    // 3. IMPORTO LORDO IN EVIDENZA
                                    TextField(
                                      controller: _importoController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 18, fontWeight: FontWeight.bold),
                                      decoration: _buildInputDecoration('Importo Lordo (€)', Icons.euro_symbol_rounded),
                                    ),
                                    const SizedBox(height: 16),

                                    // BOTTONE SALVA
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
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

  Widget _buildProCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPro,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPro ? const Color(0xFFA855F7).withOpacity(0.5) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isPro ? const Color(0xFFA855F7).withOpacity(0.15) : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isPro ? const Color(0xFFA855F7) : const Color(0xFFF59E0B), size: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isPro) ...[
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PRO', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
      prefixIcon: Icon(icon, color: const Color(0xFF2DD4BF), size: 18),
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
    );
  }
}