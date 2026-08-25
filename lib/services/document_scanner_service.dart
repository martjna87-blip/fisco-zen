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
      final file = XFile(imagePath);
      final imageBytes = await file.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception("Immagine non trovata o vuota.");
      }

      // ✨ Configurazione nativa: forza Gemini a rispondere ESCLUSIVAMENTE in JSON
      final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = TextPart('''
Sei un assistente contabile esperto nell'analisi di scontrini, ricevute fiscali e FATTURE italiane.
Analizza il documento fornito ed estrai ESATTAMENTE questi dati:

{
  "importo": 120.50,
  "merchant": "Nome Negozio o Fornitore",
  "piva": "12345678901",
  "date": "YYYY-MM-DD",
  "category": "Alimentari",
  "is_fattura": false
}

Regole importanti:
1. "importo": numero decimale con punto (es. 120.50) del totale lordo da pagare.
2. "merchant": ragione sociale o nome del punto vendita.
3. "piva": Partita IVA o Codice Fiscale dell'esercente/fornitore se visibile, altrimenti null.
4. "date": data in formato YYYY-MM-DD, altrimenti null.
5. "category": UNA sola tra [Alimentari, Casa/Affitto, Canoni/Bollette, Acquisti, Divertimento, Auto, Viaggi, Salute & Benessere, Altro].
6. "is_fattura": true se è una fattura fiscale con P.IVA/N. Documento, false se scontrino/ricevuta.
''');

      // Detect del formato reale dell'immagine per iOS (JPEG, PNG o HEIC)
      String mimeType = 'image/jpeg';
      final pathLower = imagePath.toLowerCase();
      if (pathLower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (pathLower.endsWith('.heic') || pathLower.endsWith('.heif')) {
        mimeType = 'image/heic';
      }

      final imagePart = InlineDataPart(mimeType, imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final textResponse = response.text?.trim() ?? '';

      if (textResponse.isEmpty) {
        throw Exception("L'AI non ha restituito alcun testo.");
      }

      // Pulizia ed estrazione sicura del blocco JSON {...}
      String cleanJson = textResponse;
      final startIdx = cleanJson.indexOf('{');
      final endIdx = cleanJson.lastIndexOf('}');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        cleanJson = cleanJson.substring(startIdx, endIdx + 1);
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
      print('❌ Errore Scansione AI: $e');
      throw Exception('Impossibile analizzare il documento con Gemini: $e');
    }
  }
}