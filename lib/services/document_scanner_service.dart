import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../data/wallet_provider.dart';

class ScanResult {
  final double? importo;
  final String? ragioneSociale;
  final DateTime? data;
  final String? categoriaSuggerita;
  final bool isFattura;
  final String? piva;
  final String metodoUsato;

  ScanResult({
    this.importo,
    this.ragioneSociale,
    this.data,
    this.categoriaSuggerita,
    this.isFattura = false,
    this.piva,
    required this.metodoUsato,
  });
}

class DocumentScannerService {
  static Future<ScanResult> scanDocument({
    required String imagePath,
    required WalletProvider wallet,
  }) async {
    try {
      final imageBytes = await XFile(imagePath).readAsBytes();

      // ✨ Inizializzazione sicura tramite Firebase (senza API Key visibili)
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-flash',
      );

      final prompt = TextPart('''
Sei un assistente contabile esperto nell'analisi di scontrini, ricevute fiscali e FATTURE italiane.
Analizza il documento fornito ed estrai ESATTAMENTE questi dati in formato JSON puro:

{
  "importo": <numero decimale con punto, es. 120.50. Cerca il Totale Documento / Totale da Pagare comprensivo di IVA>,
  "merchant": "<nome del negozio o Ragione Sociale/Fornitore della fattura>",
  "piva": "<Partita IVA o Codice Fiscale dell'esercente/fornitore se visibile, altrimenti null>",
  "date": "<data del documento in formato YYYY-MM-DD. Se non chiaramente visibile usa null>",
  "category": "<scegli UNA sola categoria tra: Alimentari, Casa/Affitto, Canoni/Bollette, Acquisti, Divertimento, Auto, Viaggi, Salute & Benessere, Altro>",
  "is_fattura": <true se si tratta di una fattura con P.IVA o numero documento, false se è uno scontrino>
}

Rispondi ESCLUSIVAMENTE con il JSON, senza blocchi di codice markdown, senza testo introduttivo.
''');

      final imagePart = DataPart('image/jpeg', imageBytes);
      
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final textResponse = response.text?.trim() ?? '';
      
      String cleanJson = textResponse;
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```[a-z]*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }

      final Map<String, dynamic> data = jsonDecode(cleanJson);

      return ScanResult(
        importo: double.tryParse(data['importo']?.toString() ?? ''),
        ragioneSociale: data['merchant'] as String?,
        piva: data['piva'] as String?,
        data: data['date'] != null ? DateTime.tryParse(data['date'].toString()) : null,
        categoriaSuggerita: data['category'] as String?,
        isFattura: data['is_fattura'] as bool? ?? false,
        metodoUsato: 'AI_VISION',
      );
    } catch (e) {
      print('Errore Scansione AI: $e');
      throw Exception('Impossibile analizzare il documento con Gemini: $e');
    }
  }
}