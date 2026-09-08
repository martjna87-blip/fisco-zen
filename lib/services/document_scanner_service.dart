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
  final String? bussolaSuggerita;
  final bool isFattura;
  final String? piva;
  final String? numeroFattura; // ✨ Campo aggiunto per il numero di fattura
  final String metodoUsato;

  ScanResult({
    this.importo,
    this.ragioneSociale,
    this.data,
    this.categoriaSuggerita,
    this.bussolaSuggerita,
    this.isFattura = false,
    this.piva,
    this.numeroFattura, // ✨ Inizializzato nel costruttore
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
  "bussola": "30% Spese Variabili"
}
Regole:
- "importo": numero decimale lordo con punto.
- "category": UNA ESATTA tra [Casa/Affitto, Mutuo, Canoni/Bollette, Supermercato, Ristoranti & Bar, Acquisti, Divertimento, Auto, Viaggi, Salute & Benessere, Altro].
- "bussola": UNA ESATTA tra ["50% Spese Fisse", "30% Spese Variabili", "20% Risparmio"]. Per ristoranti, bar e svago usa "30% Spese Variabili"; per supermercato, affitto o bollette usa "50% Spese Fisse".
'''
          : '''
Sei un esperto contabile italiano. Analizza la FATTURA nell'immagine ed estrai questo JSON esatto:
{
  "importo": 450.00,
  "numero_fattura": "12/A",
  "merchant": "Nome Ragione Sociale Cliente",
  "piva": "12345678901",
  "date": "YYYY-MM-DD",
  "category": "P.IVA",
  "bussola": "50% Spese Fisse"
}

REGOLE TASSATIVE DI ESTRAZIONE FISCALE:
1. "merchant": Identifica il DESTINATARIO / CLIENTE (Cessionario / Committente, solitamente preceduto da "Spett.le", "Cliente", "Destinatario" o posizionato a destra/in basso). IGNORA tassativamente l'Emittente / Fornitore (Cedente / Prestatore, chi emette la fattura in alto a sinistra).
2. "piva": Partita IVA o Codice Fiscale del CLIENTE / DESTINATARIO (Cessionario / Committente).
3. "numero_fattura": Cerca nel documento diciture come "Fattura N.", "Fattura numero", "Doc. N.", "N° Fattura", "Numero Documento" ed estrai la stringa/codice alfanumerico completo (es. "101", "FATT-2026/01", "12/A", "01/2026").
4. "importo": Cerca "Totale Documento", "Totale da Pagare", "Totale Fattura" ed estrai il valore numerico lordo con punto decimale.
5. "date": Data di emissione del documento in formato YYYY-MM-DD.
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
        numeroFattura: data['numero_fattura']?.toString(), // ✨ Mappato correttamente
        data: data['date'] != null ? DateTime.tryParse(data['date'].toString()) : null,
        categoriaSuggerita: data['category'] as String?,
        bussolaSuggerita: data['bussola'] as String?,
        isFattura: tipo == TipoDocumentoScan.fattura,
        metodoUsato: 'AI_VISION',
      );
    } catch (e) {
      print('❌ Errore Scansione AI: $e');
      rethrow;
    }
  }
  // 🏦 Analisi Estratto Conto con Retry Automatico per errori 503 / Timeout
  static Future<List<Map<String, dynamic>>> scanEstrattoConto({
    required List<int> fileBytes,
    required String mimeType,
  }) async {
    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        final String base64File = base64Encode(fileBytes);

        final String promptText = '''
Sei un esperto contabile. Analizza questo ESTRATTO CONTO BANCARIO ed estrai tutte le transazioni (entrate e uscite) visibili.
Restituisci ESCLUSIVAMENTE un ARRAY JSON valido in questo esatto formato, senza Markdown o testo aggiuntivo:
[
  {
    "date": "YYYY-MM-DD",
    "title": "Nome del negozio, azienda o causale bonifico",
    "amount": 150.50,
    "isIncome": false,
    "category": "Una categoria logica (es. Spesa Alimentare, Bollette, Ristoranti, Bonifico in Ingresso, Stipendio)"
  }
]
Regole:
1. "amount" DEVE essere un numero positivo. Se è un'uscita imposta "isIncome": false, se è un'entrata imposta "isIncome": true.
2. "date" DEVE essere in formato YYYY-MM-DD.
3. Se non trovi transazioni restituisci un array vuoto [].
''';

        final payload = {
          "contents": [
            {
              "parts": [
                {"text": promptText},
                {
                  "inline_data": {
                    "mime_type": mimeType,
                    "data": base64File
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
          const Duration(seconds: 45),
          onTimeout: () => throw TimeoutException("Timeout connessione con il server AI"),
        );

        if (response.statusCode == 503 || response.statusCode == 429) {
          throw Exception("Server AI temporaneamente occupato (${response.statusCode})");
        }

        final Map<String, dynamic> resData = jsonDecode(response.body);

        if (response.statusCode != 200 || resData.containsKey('error')) {
          final errObj = resData['error'];
          String errorMsg = "Errore HTTP (${response.statusCode})";
          if (errObj is String) errorMsg = errObj;
          if (errObj is Map && errObj.containsKey('message')) errorMsg = errObj['message'].toString();
          throw Exception(errorMsg);
        }

        final String textContent = resData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        if (textContent.isEmpty) {
          throw Exception("Risposta AI vuota.");
        }

        String cleanJson = textContent.trim();
        if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
        if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
        if (cleanJson.endsWith('```')) cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        cleanJson = cleanJson.trim();

        final List<dynamic> parsedList = jsonDecode(cleanJson);
        List<Map<String, dynamic>> finalResult = [];

        for (var item in parsedList) {
          if (item is Map<String, dynamic>) {
            finalResult.add(item);
          }
        }

        return finalResult; // Scansione riuscita
      } catch (e) {
        print('⚠️ Tentativo Scansione $attempt/$maxRetries fallito: $e');
        if (attempt >= maxRetries) {
          rethrow;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception("Impossibile completare la scansione dopo $maxRetries tentativi.");
  }
}