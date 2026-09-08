import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../data/wallet_provider.dart';
import '../services/document_scanner_service.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '../widgets_shared/app_notifications.dart';
import '2_1_wallet_add_movement.dart';

// Modello per la riga estratta dall'OCR
class ExtractedRow {
  bool isSelected;
  bool isDuplicate;
  bool isExpanded; // Permette di aprire la scheda di confronto in-loco
  final DateTime date;
  final String title;
  final double amount;
  final bool isIncome;
  String category;

  ExtractedRow({
    this.isSelected = true,
    this.isDuplicate = false,
    this.isExpanded = false,
    required this.date,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
  });
}

class ImportStatementSheet extends StatefulWidget {
  final String accountId;
  final String accountName;
  final Color accountColor;

  const ImportStatementSheet({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.accountColor,
  });

  @override
  State<ImportStatementSheet> createState() => _ImportStatementSheetState();
}

class _ImportStatementSheetState extends State<ImportStatementSheet> {
  final Color oceanCyan = const Color(0xFF38BDF8);
  final Color alertRed = const Color(0xFFEF4444);
  final Color goldAccent = const Color(0xFFFBBF24);

  int _step = 1; // 1: Scelta file, 2: Analisi, 3: Revisione
  List<ExtractedRow> _movimentiEstratti = [];
  bool _soloDaVerificare = false; // Filtro per mostrare solo duplicati e match DB

  String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${importo < 0 ? '-' : ''}$intPart,${parti[1]} €';
  }

  // 🔍 Algoritmo multilivello: rileva scostamenti minimi anche con parole/lingue diverse
  bool _isMovimentoSimile(dynamic tx, ExtractedRow riga) {
    if (tx.accountId.toString() != widget.accountId) return false;
    if (tx.isIncome != riga.isIncome) return false;

    final DateTime date = tx.date as DateTime;
    final int diffGiorni = date.difference(riga.date).inDays.abs();
    final bool stessoMese = date.month == riga.date.month && date.year == riga.date.year;

    if (!stessoMese && diffGiorni > 7) return false;

    final double amount = (tx.amount as num).toDouble();
    final double diffImporto = (amount - riga.amount).abs();

    final String titleTx = tx.title.toString().toLowerCase();
    final String titleRiga = riga.title.toLowerCase();

    // Confronto avanzato sulle radici delle parole (> 3 lettere) per collegare es. "Parkings" e "Parcheggio"
    final List<String> paroleTx = titleTx.split(RegExp(r'[\s\-/]+')).where((String p) => p.length >= 4).toList();
    final List<String> paroleRiga = titleRiga.split(RegExp(r'[\s\-/]+')).where((String p) => p.length >= 4).toList();

    final bool haTestoSimile = paroleTx.any((String p1) => titleRiga.contains(p1) || (p1.length >= 4 && titleRiga.contains(p1.substring(0, 4)))) ||
        paroleRiga.any((String p2) => titleTx.contains(p2) || (p2.length >= 4 && titleTx.contains(p2.substring(0, 4))));

    final String catTx = tx.category.toString().toLowerCase();
    final String catRiga = riga.category.toLowerCase();

    final bool stessaCategoria = catTx == catRiga ||
        catTx.contains(catRiga) ||
        catRiga.contains(catTx) ||
        (catRiga.contains('alimentar') && (catTx.contains('supermercato') || catTx.contains('spesa'))) ||
        (catRiga.contains('supermercato') && (catTx.contains('alimentar') || catTx.contains('spesa'))) ||
        (catRiga.contains('ristorant') && catTx.contains('ristorant')) ||
        (catRiga.contains('trasport') && (catTx.contains('auto') || catTx.contains('trasport') || catTx.contains('parchegg'))) ||
        (catRiga.contains('carburan') && (catTx.contains('auto') || catTx.contains('carburan')));

    // 1. Scostamento minimo di prezzo (<= 1,00 €) entro 5 giorni -> MATCH (Cattura Parcheggio 18,90 vs 19,00 e Chez Eva 40,10 vs 41,00)
    if (diffImporto <= 1.00 && diffGiorni <= 5) return true;

    // 2. Delta fino a 3,00 € MA con Categoria o Radice del testo affine -> MATCH (Cattura Chez Francky 42,70 vs 41,00)
    if (diffImporto < 3.00 && (haTestoSimile || stessaCategoria) && diffGiorni <= 5) return true;

    // 3. Stesso Mese con Categoria o Testo affine (fino a 5,00 €) -> MATCH
    if (diffImporto < 5.00 && (haTestoSimile || stessaCategoria) && stessoMese) return true;

    return false;
  }

  // 📸 1. MENU DI SELEZIONE SORGENTE
  Future<void> _mostraSceltaSorgente() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleziona il documento',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Scatta una foto', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx); // Chiude il menu di scelta

                  // ✨ MESSAGGIO DI PRE-AVVISO FOTOCAMERA
                  final bool? procedi = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Row(
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Color(0xFF38BDF8), size: 22),
                          SizedBox(width: 8),
                          Text('Accesso Fotocamera', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: const Text(
                        'Per scansionare l\'estratto conto, FiscON richiede l\'accesso alla tua fotocamera.\n\nLe immagini verranno elaborate in modo sicuro per estrarre i movimenti.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text('Continua', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  // Se l'utente clicca Continua, apre la fotocamera
                  if (procedi == true) {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) _elaboraDocumentoReale(pickedFile);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Carica da Galleria', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) _elaboraDocumentoReale(pickedFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Carica file PDF', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null && result.files.isNotEmpty) {
                    _elaboraDocumentoReale(result.files.first);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧠 2. ELABORAZIONE AI REALE TRAMITE OCR ENGINE
  Future<void> _elaboraDocumentoReale(dynamic pickedFile) async {
    setState(() => _step = 2);

    try {
      List<int> fileBytes;
      String mimeType = 'image/jpeg';

      if (pickedFile is XFile) {
        fileBytes = await pickedFile.readAsBytes();
        if (pickedFile.path.toLowerCase().endsWith('.png')) mimeType = 'image/png';
      } else if (pickedFile is PlatformFile) {
        fileBytes = pickedFile.bytes ?? await File(pickedFile.path!).readAsBytes();
        if (pickedFile.name.toLowerCase().endsWith('.pdf')) {
          mimeType = 'application/pdf';
        }
      } else {
        throw Exception("Formato file non supportato");
      }

      final List<Map<String, dynamic>> risultatiAI = await DocumentScannerService.scanEstrattoConto(
        fileBytes: fileBytes,
        mimeType: mimeType,
      );

      List<ExtractedRow> letture = [];
      for (var item in risultatiAI) {
        letture.add(ExtractedRow(
          date: DateTime.tryParse(item['date'].toString()) ?? DateTime.now(),
          title: item['title'].toString(),
          amount: (item['amount'] as num).toDouble(),
          isIncome: item['isIncome'] as bool,
          category: item['category'].toString(),
        ));
      }

      final wallet = Provider.of<WalletProvider>(context, listen: false);
      final txsEsistenti = wallet.transactions.where((t) => t.accountId == widget.accountId).toList();

      for (var estratto in letture) {
        bool duplicatoTrovato = txsEsistenti.any((tx) {
          final stessImporto = tx.amount == estratto.amount;
          final stessaDirezione = tx.isIncome == estratto.isIncome;
          final differenzaGiorni = tx.date.difference(estratto.date).inDays.abs();
          return stessImporto && stessaDirezione && differenzaGiorni <= 2;
        });

        if (duplicatoTrovato) {
          estratto.isDuplicate = true;
          estratto.isSelected = false;
        }
      }

      if (mounted) {
        setState(() {
          _movimentiEstratti = letture;
          _step = 3;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step = 1);
        AppNotifications.mostraInAlto(context, '❌ Errore AI: Impossibile estrarre i dati dal file.');
        print(e);
      }
    }
  }

  void _importaSelezionati() {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    int conteggio = 0;

    for (var riga in _movimentiEstratti.where((r) => r.isSelected)) {
      wallet.addTransaction(
        title: riga.title,
        amount: riga.amount,
        isIncome: riga.isIncome,
        category: riga.category,
        date: riga.date,
        accountId: widget.accountId,
      );
      conteggio++;
    }

    Navigator.pop(context);
    AppNotifications.mostraInAlto(context, '✅ $conteggio movimenti importati con successo!');
  }

  void _vaiAVerificaMovimenti({DateTime? dataRiferimento}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMovementSheet(
        initialTab: 'riepilogo',
        initialDate: dataRiferimento, // ✨ Invia la data del movimento per aprire Agosto 2026
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return AppBottomSheet(
      title: 'Importa Estratto Conto',
      badgeText: widget.accountName,
      badgeColor: widget.accountColor,
      child: SizedBox(
        height: screenHeight * 0.75,
        child: Column(
          children: [
            // STEP 1: CARICAMENTO FILE
            if (_step == 1) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: oceanCyan.withOpacity(0.15), shape: BoxShape.circle),
                        child: Icon(Icons.document_scanner_rounded, color: oceanCyan, size: 50),
                      ),
                      const SizedBox(height: 24),
                      const Text('Carica il tuo Estratto Conto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Carica un PDF o scatta una foto ai movimenti.\nL\'AI estrarrà dati e categorie automaticamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: oceanCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Scegli PDF / Immagine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: _mostraSceltaSorgente,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // STEP 2: ANALISI IN CORSO
            if (_step == 2) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: oceanCyan.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: oceanCyan.withOpacity(0.3), width: 2),
                        ),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: oceanCyan,
                            strokeWidth: 3.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Scansione AI in corso...',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Estrazione dati, categorizzazione e\nverifica duplicati (potrebbe richiedere 10-20 sec)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // STEP 3: REVISIONE
            if (_step == 3) ...[
              if (_movimentiEstratti.isEmpty) ...[
                const Expanded(
                  child: Center(
                    child: Text('Nessun movimento trovato nel documento.', style: TextStyle(color: Colors.white54)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: goldAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: goldAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trovati ${_movimentiEstratti.length} movimenti. Deseleziona eventuali errori prima di importare.',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

                // BARRA AZIONI: SELEZIONE TOTALE, FILTRO DUBBI & LENTE VERIFICA COMPATTA
                Builder(
                  builder: (context) {
                    final wallet = Provider.of<WalletProvider>(context, listen: false);
                    final countDaVerificare = _movimentiEstratti.where((riga) {
                      if (riga.isDuplicate) return true;
                      final simili = wallet.transactions.where((tx) => _isMovimentoSimile(tx, riga));
                      return simili.isNotEmpty;
                    }).length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Seleziona / Deseleziona tutti
                          InkWell(
                            onTap: () {
                              final tuttiSelezionati = _movimentiEstratti.every((r) => r.isSelected);
                              setState(() {
                                for (var riga in _movimentiEstratti) {
                                  riga.isSelected = !tuttiSelezionati;
                                }
                              });
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _movimentiEstratti.isNotEmpty && _movimentiEstratti.every((r) => r.isSelected),
                                  activeColor: oceanCyan,
                                  checkColor: Colors.black,
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                  onChanged: (val) {
                                    setState(() {
                                      for (var riga in _movimentiEstratti) {
                                        riga.isSelected = val ?? false;
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  _movimentiEstratti.every((r) => r.isSelected) ? 'Deseleziona' : 'Tutti',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              // FilterChip compatto per isolare i dubbi
                              FilterChip(
                                selected: _soloDaVerificare,
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                avatar: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 13,
                                  color: _soloDaVerificare ? Colors.black : goldAccent,
                                ),
                                label: Text(
                                  'Da verificare ($countDaVerificare)',
                                  style: TextStyle(
                                    color: _soloDaVerificare ? Colors.black : Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selectedColor: goldAccent,
                                backgroundColor: goldAccent.withOpacity(0.12),
                                side: BorderSide(color: goldAccent.withOpacity(0.4)),
                                onSelected: (val) {
                                  setState(() {
                                    _soloDaVerificare = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 6),

                              // Lente d'ingrandimento ridimensionata ed efficace
                              InkWell(
                                onTap: _vaiAVerificaMovimenti,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search_rounded, size: 14, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Riepilogo',
                                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // LISTA MOVIMENTI ESTRATTI CON CONFRONTO RAPIDO IN-LOCO
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final wallet = Provider.of<WalletProvider>(context, listen: false);

                      final movimentiVisibili = _movimentiEstratti.where((riga) {
                        if (!_soloDaVerificare) return true;
                        final simili = wallet.transactions.where((tx) => _isMovimentoSimile(tx, riga)).toList();
                        return riga.isDuplicate || simili.isNotEmpty;
                      }).toList();

                      if (movimentiVisibili.isEmpty && _soloDaVerificare) {
                        return Center(
                          child: Text(
                            '✅ Nessun movimento richiede verifica manuale.',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: movimentiVisibili.length,
                        itemBuilder: (context, index) {
                          final riga = movimentiVisibili[index];

                          final movimentiSimili = wallet.transactions.where((tx) => _isMovimentoSimile(tx, riga)).toList();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: riga.isDuplicate
                                  ? alertRed.withOpacity(0.08)
                                  : (riga.isSelected ? oceanCyan.withOpacity(0.08) : Colors.white.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: riga.isDuplicate
                                    ? alertRed.withOpacity(0.3)
                                    : (riga.isSelected ? oceanCyan.withOpacity(0.3) : Colors.white10),
                              ),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: Checkbox(
                                    value: riga.isSelected,
                                    activeColor: oceanCyan,
                                    checkColor: Colors.black,
                                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                    onChanged: (val) {
                                      setState(() {
                                        riga.isSelected = val ?? false;
                                      });
                                    },
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          riga.title,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        '${riga.isIncome ? '+' : '-'}${_formattaValuta(riga.amount)}',
                                        style: TextStyle(
                                          color: riga.isIncome ? const Color(0xFF10B981) : alertRed,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${riga.date.day}/${riga.date.month}/${riga.date.year} • ${riga.category}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              // Verifica se una spesa DB è contesa da più righe dell'estratto conto
                                              final bool haMatchConteso = movimentiSimili.any((dynamic tx) {
                                                return _movimentiEstratti.where((ExtractedRow altra) {
                                                  final stessoMese = (tx.date as DateTime).month == altra.date.month && (tx.date as DateTime).year == altra.date.year;
                                                  final importoSimile = (((tx.amount as num) - altra.amount).abs()) < 2.0;
                                                  final titleTx = tx.title.toString().toLowerCase();
                                                  return tx.accountId.toString() == widget.accountId && stessoMese && (importoSimile || titleTx.contains(altra.title.toLowerCase()));
                                                }).length > 1;
                                              });

                                              return InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    bool statoFuturo = !riga.isExpanded;
                                                    for (var voce in _movimentiEstratti) {
                                                      voce.isExpanded = false;
                                                    }
                                                    riga.isExpanded = statoFuturo;
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                                  child: Row(
                                                    children: [
                                                      if (haMatchConteso) ...[
                                                        Icon(Icons.warning_amber_rounded, color: goldAccent, size: 13),
                                                        const SizedBox(width: 3),
                                                      ],
                                                      if (movimentiSimili.isNotEmpty) ...[
                                                        Text(
                                                          '🔍 ${movimentiSimili.length} simili nel DB',
                                                          style: TextStyle(
                                                            color: haMatchConteso ? goldAccent : oceanCyan,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                      ],
                                                      Icon(
                                                        riga.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                        color: movimentiSimili.isNotEmpty ? (haMatchConteso ? goldAccent : oceanCyan) : Colors.white38,
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      if (riga.isDuplicate) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.warning_rounded, color: alertRed, size: 12),
                                            const SizedBox(width: 4),
                                            Text('Probabile Duplicato Già Registrato', style: TextStyle(color: alertRed, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // SCHEDA ESPANDIBILE COMPATTA & OTTIMIZZATA
                                if (riga.isExpanded) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    margin: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Movimenti registrati nel conto in questo periodo:',
                                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        if (movimentiSimili.isEmpty) ...[
                                          const Text('✅ Nessuna spesa simile trovata nel database.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                        ] else ...[
                                          ...movimentiSimili.map((tx) {
                                            final bool isConteso = _movimentiEstratti.where((ExtractedRow altra) {
                                              final stessoMese = (tx.date as DateTime).month == altra.date.month && (tx.date as DateTime).year == altra.date.year;
                                              final importoSimile = (((tx.amount as num) - altra.amount).abs()) < 2.0;
                                              final titleTx = tx.title.toString().toLowerCase();
                                              return tx.accountId.toString() == widget.accountId && stessoMese && (importoSimile || titleTx.contains(altra.title.toLowerCase()));
                                            }).length > 1;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '• ${tx.title} (${tx.date.day}/${tx.date.month}/${tx.date.year})',
                                                          style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 11),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${tx.isIncome ? '+' : '-'}${_formattaValuta(tx.amount)}',
                                                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isConteso) ...[
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.info_outline_rounded, color: goldAccent, size: 11),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            '1 spesa DB corrispondente a più voci dell\'estratto conto.',
                                                            style: TextStyle(color: goldAccent, fontSize: 9.5, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          }),
                                        ],
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: InkWell(
                                            onTap: () => _vaiAVerificaMovimenti(dataRiferimento: riga.date),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.open_in_new_rounded, color: oceanCyan, size: 11),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Apri Riepilogo (${riga.date.day}/${riga.date.month}/${riga.date.year})',
                                                    style: TextStyle(color: oceanCyan, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // AZIONE FINALE COMPATTA (SPAZIO OTTIMIZZATO)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oceanCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.white10,
                  ),
                  onPressed: _movimentiEstratti.where((r) => r.isSelected).isEmpty ? null : _importaSelezionati,
                  child: Text(
                    'Importa ${_movimentiEstratti.where((r) => r.isSelected).length} Movimenti',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}