import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/ocr_engine.dart';
import '../data/wallet_provider.dart';

class ScanResult {
  final double? importo;
  final DateTime? data;
  final String? piva;
  final String? ragioneSociale;
  final String? categoriaSpesa; // 💡 Utile per le future spese
  final String metodoUsato; // 'ML_KIT' o 'AI_VISION'

  ScanResult({
    this.importo,
    this.data,
    this.piva,
    this.ragioneSociale,
    this.categoriaSpesa,
    required this.metodoUsato,
  });
}

class DocumentScannerService {
  // 🗝️ Inserisci la tua API Key di Gemini/OpenAI
  static const String _geminiApiKey = 'LA_TUA_GEMINI_API_KEY';

  /// 🧠 Metodo principale che smista tra Free e Pro/Premium
  static Future<ScanResult> scanDocument({
    required String imagePath,
    required WalletProvider wallet,
  }) async {
    // 🟢 UTENTI PRO / PREMIUM: Scansione AI avanzata
    if (wallet.canUseOCR) {
      try {
        final resultAi = await _scanWithAi(imagePath);
        if (resultAi != null) return resultAi;
      } catch (e) {
        debugPrint('Fallback su ML Kit per errore AI: $e');
      }
    }

    // ⚪ UTENTI FREE (o Fallback): Scansione ML Kit On-Device
    final dataMl = await OcrEngine.scanImage(imagePath);
    return ScanResult(
      importo: dataMl.importoTotale,
      data: dataMl.data,
      piva: dataMl.partitaIva,
      metodoUsato: 'ML_KIT',
    );
  }

  /// 🤖 Analisi con AI Vision (Gemini REST API)
  static Future<ScanResult?> _scanWithAi(String imagePath) async {
    // 1. Convertiamo l'immagine in Base64
    final bytes = await http.readBytes(Uri.file(imagePath));
    final base64Image = base64Encode(bytes);

    // 2. Prompt strutturato per ricevere un JSON pulito
    final prompt = '''
      Analizza questo documento fiscale (fattura o scontrino) ed estrai in formato JSON puro:
      {
        "importo": numero (es. 150.50),
        "data": "YYYY-MM-DD",
        "piva": "stringa 11 cifre",
        "ragioneSociale": "nome cliente o fornitore",
        "categoriaSpesa": "Bisogni|Svago|Risparmi|P.IVA"
      }
      Rispondi ESCLUSIVAMENTE con il JSON, senza markdown o testo aggiuntivo.
    ''';

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final rawText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      
      // Pulizia eventuale formattazione markdown ```json ... ```
      final cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      return ScanResult(
        importo: (data['importo'] as num?)?.toDouble(),
        data: data['data'] != null ? DateTime.tryParse(data['data']) : null,
        piva: data['piva']?.toString(),
        ragioneSociale: data['ragioneSociale']?.toString(),
        categoriaSpesa: data['categoriaSpesa']?.toString(),
        metodoUsato: 'AI_VISION',
      );
    }
    return null;
  }
}