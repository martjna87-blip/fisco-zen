import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../data/wallet_provider.dart';

enum TipoDocumentoScan { scontrino, fattura }

class ScanResult {
  final double? importo;
  final String? ragioneSociale;
  final DateTime? data;
  final String? categoriaSuggerita;
  final String? bussolaSuggerita; // 🎯 Nuova voce per la Bussola
  final bool isFattura;
  final String? piva;
  final String metodoUsato;

  ScanResult({
    this.importo,
    this.ragioneSociale,
    this.data,
    this.categoriaSuggerita,
    this.bussolaSuggerita,
    this.isFattura = false,
    this.piva,
    required this.metodoUsato,
  });
}

class DocumentScannerService {
  // 🔗 URL Proxy Cloudflare
  static const String _proxyUrl = 'https://fiscon-ai-proxy.martjna87.workers.dev';

  static Future<ScanResult> scanDocument({
    required String imagePath,
    required WalletProvider wallet,
    TipoDocumentoScan tipo = TipoDocumentoScan.scontrino,
    Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('📁 1/3: Lettura file...');
      final file = XFile(imagePath);
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) throw Exception("Immagine vuota o non accessibile.");

      final String base64Image = base64Encode(bytes);
      String mimeType = 'image/jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) mimeType = 'image/png';

      onProgress?.call('🤖 2/3: Analisi AI in corso...');

      final String promptText = tipo == TipoDocumentoScan.scontrino
    ? '''
Analizza questo SCONTRINO ed estrai questo JSON esatto:
{
  "importo": 69.00,
  "merchant": "Trattoria Il Gabbiano",
  "piva": "12345678901",
  "date": "YYYY-MM-DD",
  "category": "Ristoranti & Bar",
  "bussola": "30% Svago & Desideri"
}
Regole:
- "importo": numero decimale lordo con punto.
- "category": UNA tra [Alimentari, Ristoranti & Bar, Casa/Affitto, Canoni/Bollette, Acquisti, Divertimento, Auto, Viaggi, Salute & Benessere, Altro].
- "bussola": UNA tra ["50% Spese Fisse", "30% Svago & Desideri", "20% Risparmio"]. Per ristoranti, bar e svago usa "30% Svago & Desideri"; per spesa supermercato, affitto o bollette usa "50% Spese Fisse".
'''
    : '''
Analizza questa FATTURA ed estrai questo JSON esatto:
{
  "importo": 450.00,
  "merchant": "Ragione Sociale",
  "piva": "12345678901",
  "date": "YYYY-MM-DD",
  "category": "Acquisti",
  "bussola": "50% Spese Fisse"
}
''';

      final payload = {
        "contents": [
          {
            "parts": [
              {"text": promptText},
              {
                "inline_data": {
                  "mime_type": mimeType,
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json"
        }
      };

      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException("Connessione scaduta. Riprova."),
      );

      onProgress?.call('⚡ 3/3: Estrazione dati...');

      final Map<String, dynamic> resData = jsonDecode(response.body);

      // Gestione trasparenti degli errori restituibili da Google o Cloudflare
      if (response.statusCode != 200 || resData.containsKey('error')) {
        final errObj = resData['error'];
        String errorMsg = "Errore HTTP (${response.statusCode})";
        if (errObj is String) {
          errorMsg = errObj;
        } else if (errObj is Map && errObj.containsKey('message')) {
          errorMsg = errObj['message'].toString();
        }
        throw Exception(errorMsg);
      }

      final String textContent = resData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

      if (textContent.isEmpty) {
        throw Exception("Risposta AI vuota o bloccata dai filtri.");
      }

      final startIdx = textContent.indexOf('{');
      final endIdx = textContent.lastIndexOf('}');
      if (startIdx == -1 || endIdx == -1 || endIdx < startIdx) {
        throw Exception("Formato JSON non valido nella risposta AI.");
      }

      final cleanJson = textContent.substring(startIdx, endIdx + 1);
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      return ScanResult(
  importo: double.tryParse(data['importo']?.toString() ?? ''),
  ragioneSociale: data['merchant'] as String?,
  piva: data['piva'] as String?,
  data: data['date'] != null ? DateTime.tryParse(data['date'].toString()) : null,
  categoriaSuggerita: data['category'] as String?,
  bussolaSuggerita: data['bussola'] as String?, // 🎯 Ritorna la bussola estratta
  isFattura: tipo == TipoDocumentoScan.fattura,
  metodoUsato: 'AI_VISION',
);
    } catch (e) {
      print('❌ Errore Scansione AI: $e');
      rethrow;
    }
  }
}