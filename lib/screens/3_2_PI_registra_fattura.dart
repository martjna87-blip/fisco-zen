import 'dart:ui';
import 'package:flutter/material.dart';
import '3_4_PI_pro_upgrade.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';


class RegistraFatturaSheet extends StatefulWidget {
 final Function(String cliente, double importo, String dataFormattata) onFatturaSalvata;


 const RegistraFatturaSheet({
   super.key,
   required this.onFatturaSalvata,
 });


 @override
 State<RegistraFatturaSheet> createState() => _RegistraFatturaSheetState();
}


class _RegistraFatturaSheetState extends State<RegistraFatturaSheet> {
 final TextEditingController _clienteController = TextEditingController();
 final TextEditingController _importoController = TextEditingController();
 DateTime _dataFattura = DateTime.now();
 bool _isManualeEspanso = false;


 @override
 void dispose() {
   _clienteController.dispose();
   _importoController.dispose();
   super.dispose();
 }


 String _formattaData(DateTime date) {
   final giorno = date.day.toString().padLeft(2, '0');
   final mese = date.month.toString().padLeft(2, '0');
   return '$giorno/$mese/${date.year}';
 }


 Future<DateTime?> _mostraCalendarioCompatto(DateTime dataIniziale) {
   return showDialog<DateTime>(
     context: context,
     builder: (BuildContext context) {
       return Dialog(
         backgroundColor: const Color(0xFF1C1C21),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
         child: Container(
           width: 320,
           padding: const EdgeInsets.all(8),
           child: Theme(
             data: ThemeData.dark().copyWith(
               colorScheme: const ColorScheme.dark(
                 primary: Color(0xFF2DD4BF),
                 onPrimary: Colors.black,
                 surface: Color(0xFF1C1C21),
                 onSurface: Colors.white,
               ),
               dialogBackgroundColor: const Color(0xFF1C1C21),
               visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
               textTheme: const TextTheme(
                 bodyMedium: TextStyle(fontSize: 12),
                 bodyLarge: TextStyle(fontSize: 13),
               ),
             ),
             child: DatePickerDialog(
               initialDate: dataIniziale,
               firstDate: DateTime(2020),
               lastDate: DateTime(2030),
             ),
           ),
         ),
       );
     },
   );
 }


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
             height: screenHeight * 0.76,
             width: double.infinity,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(28),
               image: const DecorationImage(
                 image: NetworkImage(
                   'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000&auto=format&fit=crop',
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
                     Colors.black.withOpacity(0.35),
                     Colors.black.withOpacity(0.80),
                   ],
                 ),
               ),
             ),
           ),
         ),


         // CARD SCURA FROSTED GLASS
         ClipRRect(
           borderRadius: BorderRadius.circular(24),
           child: BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 16, sigmaY: 18),
             child: Container(
               height: screenHeight * 0.72,
               margin: const EdgeInsets.all(12),
               padding: const EdgeInsets.all(18),
               decoration: BoxDecoration(
                 color: const Color(0xFF141417).withOpacity(0.68),
                 borderRadius: BorderRadius.circular(24),
                 border: Border.all(color: Colors.white.withOpacity(0.18)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // INTESTAZIONE
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Row(
                         children: [
                           IconButton(
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                             icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                             onPressed: () => Navigator.pop(context),
                             tooltip: 'Chiudi',
                           ),
                           const SizedBox(width: 8),
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


                   const SizedBox(height: 14),


                   Expanded(
                     child: SingleChildScrollView(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'SCEGLI MODALITÀ DI REGISTRAZIONE',
                             style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                           ),
                           const SizedBox(height: 8),


                           // Opzione 1: Scansione Fotocamera (PRO)
                           _buildGlassOptionCard(
                             icon: Icons.camera_alt_outlined,
                             title: 'Scansiona con Fotocamera',
                             subtitle: 'Acquisizione automatica da cartaceo (OCR)',
                             badgeText: 'PRO',
                             isPro: true,
                             onTap: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => const ProUpgradeSheet(funzionalita: 'Scansione Fotocamera OCR'),
                               );
                             },
                           ),


                           const SizedBox(height: 8),


                           // Opzione 2: PDF / XML (PRO)
                           _buildGlassOptionCard(
                             icon: Icons.picture_as_pdf_outlined,
                             title: 'Carica File / PDF / XML',
                             subtitle: 'Importa da cassetto fiscale o file locale',
                             badgeText: 'PRO',
                             isPro: true,
                             onTap: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => const ProUpgradeSheet(funzionalita: 'Upload File PDF/XML'),
                               );
                             },
                           ),


                           const SizedBox(height: 8),


                           // Opzione 3: Inserimento Manuale In-Line
                           AnimatedContainer(
                             duration: const Duration(milliseconds: 200),
                             decoration: BoxDecoration(
                               color: Colors.black.withOpacity(0.35),
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(
                                 color: _isManualeEspanso ? const Color(0xFF2DD4BF).withOpacity(0.5) : Colors.white.withOpacity(0.08),
                               ),
                             ),
                             child: Column(
                               children: [
                                 InkWell(
                                   onTap: () => setState(() => _isManualeEspanso = !_isManualeEspanso),
                                   borderRadius: BorderRadius.circular(16),
                                   child: Padding(
                                     padding: const EdgeInsets.all(12),
                                     child: Row(
                                       children: [
                                         Container(
                                           padding: const EdgeInsets.all(8),
                                           decoration: BoxDecoration(
                                             color: const Color(0xFF2DD4BF).withOpacity(0.15),
                                             shape: BoxShape.circle,
                                           ),
                                           child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2DD4BF), size: 18),
                                         ),
                                         const SizedBox(width: 12),
                                         const Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               Text('Inserimento Manuale', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                               SizedBox(height: 2),
                                               Text('Compila dati cliente e importo a mano', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                             ],
                                           ),
                                         ),
                                         Icon(
                                           _isManualeEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                           color: Colors.white38,
                                           size: 18,
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),


                                 if (_isManualeEspanso) ...[
                                   const Divider(color: Colors.white12, height: 1),
                                   Padding(
                                     padding: const EdgeInsets.all(12),
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         TextField(
                                           controller: _clienteController,
                                           style: const TextStyle(color: Colors.white, fontSize: 13),
                                           decoration: InputDecoration(
                                             labelText: 'Nome Cliente / Ragione Sociale',
                                             labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                                             filled: true,
                                             fillColor: Colors.black.withOpacity(0.3),
                                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                           ),
                                         ),
                                         const SizedBox(height: 10),
                                         TextField(
                                           controller: _importoController,
                                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                           style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                           decoration: InputDecoration(
                                             labelText: 'Importo Lordo Fattura (€)',
                                             labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                                             filled: true,
                                             fillColor: Colors.black.withOpacity(0.3),
                                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                             prefixIcon: const Icon(Icons.euro_symbol_rounded, color: Color(0xFF2DD4BF), size: 16),
                                           ),
                                         ),
                                         const SizedBox(height: 10),


                                         // Data Fattura
                                         const Text('DATA EMISSIONE FATTURA', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                         const SizedBox(height: 4),
                                         InkWell(
                                           onTap: () async {
                                             final DateTime? dataScelta = await _mostraCalendarioCompatto(_dataFattura);
                                             if (dataScelta != null) {
                                               setState(() {
                                                 _dataFattura = dataScelta;
                                               });
                                             }
                                           },
                                           borderRadius: BorderRadius.circular(10),
                                           child: Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                             decoration: BoxDecoration(
                                               color: Colors.black.withOpacity(0.3),
                                               borderRadius: BorderRadius.circular(10),
                                               border: Border.all(color: Colors.white12),
                                             ),
                                             child: Row(
                                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                               children: [
                                                 Row(
                                                   children: [
                                                     const Icon(Icons.calendar_today_rounded, color: Color(0xFF2DD4BF), size: 14),
                                                     const SizedBox(width: 8),
                                                     Text(
                                                       _formattaData(_dataFattura),
                                                       style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                     ),
                                                   ],
                                                 ),
                                                 const Text('Cambia', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.w600)),
                                               ],
                                             ),
                                           ),
                                         ),


                                         const SizedBox(height: 12),


                                         SizedBox(
                                           width: double.infinity,
                                           height: 38,
                                           child: ElevatedButton(
                                             onPressed: () {
                                                final imp = double.tryParse(_importoController.text.replaceAll(',', '.')) ?? 0.0;
                                                final cliente = _clienteController.text.trim().isEmpty
                                                    ? 'Cliente Anonimo'
                                                    : _clienteController.text.trim();

                                                if (imp > 0) {
                                                  // 1. SALVA UNICAMENTE NEL PROVIDER CON LA DATA SCELTA
                                                  context.read<WalletProvider>().addFatturaPiva(
                                                    cliente: cliente,
                                                    importo: imp,
                                                    data: _formattaData(_dataFattura),
                                                  );

                                                  // 2. CALLBACK PER NOTIFICA VISIVA
                                                  widget.onFatturaSalvata(
                                                    cliente,
                                                    imp,
                                                    _formattaData(_dataFattura),
                                                  );

                                                  // 3. CHIUDI MODALE
                                                  Navigator.pop(context);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Inserisci un importo valido!'),
                                                      backgroundColor: Color(0xFFEF4444),
                                                    ),
                                                  );
                                                }
                                              },
                                             style: ElevatedButton.styleFrom(
                                               backgroundColor: const Color(0xFF2DD4BF),
                                               foregroundColor: Colors.black,
                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                             ),
                                             child: const Text('Salva e Registra Fattura', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                           ),
                                         ),
                                       ],
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


                   const SizedBox(height: 10),


                   // TASTO CHIUDI
                   SizedBox(
                     width: double.infinity,
                     height: 48,
                     child: ElevatedButton(
                       onPressed: () => Navigator.pop(context),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.black,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                         elevation: 0,
                       ),
                       child: const Text('Annulla e Chiudi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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


 Widget _buildGlassOptionCard({
   required IconData icon,
   required String title,
   required String subtitle,
   required VoidCallback onTap,
   String? badgeText,
   bool isPro = false,
 }) {
   return InkWell(
     onTap: onTap,
     borderRadius: BorderRadius.circular(16),
     child: Container(
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
         color: Colors.black.withOpacity(0.35),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.white.withOpacity(0.08)),
       ),
       child: Row(
         children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: isPro ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFF2DD4BF).withOpacity(0.15),
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF2DD4BF), size: 18),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                     if (badgeText != null) ...[
                       const SizedBox(width: 6),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                           color: const Color(0xFFF59E0B).withOpacity(0.2),
                           borderRadius: BorderRadius.circular(6),
                           border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                         ),
                         child: Text(
                           badgeText,
                           style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ],
                   ],
                 ),
                 const SizedBox(height: 2),
                 Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
               ],
             ),
           ),
           const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
         ],
       ),
     ),
   );
 }
}

