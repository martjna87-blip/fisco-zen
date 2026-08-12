import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScannedDocumentData {
  final double? importoTotale;
  final DateTime? data;
  final String? partitaIva;
  final String testoGrezzo;

  ScannedDocumentData({this.importoTotale, this.data, this.partitaIva, required this.testoGrezzo});
}

class OcrEngine {
  static Future<ScannedDocumentData> scanImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final String rawText = recognizedText.text;

      return ScannedDocumentData(
        importoTotale: _estraiImporto(rawText),
        data: _estraiData(rawText),
        partitaIva: _estraiPartitaIva(rawText),
        testoGrezzo: rawText,
      );
    } finally {
      textRecognizer.close();
    }
  }

  static double? _estraiImporto(String text) {
    final RegExp importoRegExp = RegExp(
      r'(?:totale|importo|eur|€)?\s*:?\s*(\d{1,3}(?:\.\d{3})*(?:,\d{2})?|\d+(?:\.\d{2})?)',
      caseSensitive: false,
    );
    double? maxImporto;
    for (final match in importoRegExp.allMatches(text)) {
      String strVal = (match.group(1) ?? '').replaceAll('.', '').replaceAll(',', '.');
      final val = double.tryParse(strVal);
      if (val != null) {
        if (maxImporto == null || val > maxImporto) maxImporto = val;
      }
    }
    return maxImporto;
  }

  static DateTime? _estraiData(String text) {
    final match = RegExp(r'(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{2,4})').firstMatch(text);
    if (match != null) {
      int giorno = int.tryParse(match.group(1)!) ?? 1;
      int mese = int.tryParse(match.group(2)!) ?? 1;
      int anno = int.tryParse(match.group(3)!) ?? 2024;
      if (anno < 100) anno += 2000;
      return DateTime(anno, mese, giorno);
    }
    return null;
  }

  static String? _estraiPartitaIva(String text) {
    return RegExp(r'\b\d{11}\b').firstMatch(text)?.group(0);
  }
}