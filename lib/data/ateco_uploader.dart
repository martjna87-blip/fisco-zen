import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AtecoUploader {
  static Future<void> caricaTuttoSuFirebase() async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    // 🗂️ LA TUA LISTA MASSIVA DI PARTENZA
    final List<Map<String, dynamic>> codiciDaCaricare = [
      {'codice': '62.01.00', 'descrizione': 'Sviluppo di software e programmazione', 'coef': 0.78},
      {'codice': '62.02.00', 'descrizione': 'Consulenza nel settore delle tecnologie informatiche', 'coef': 0.78},
      {'codice': '74.10.21', 'descrizione': 'Graphic design, Web design, UI/UX', 'coef': 0.78},
      {'codice': '74.10.29', 'descrizione': 'Altre attività di design', 'coef': 0.78},
      {'codice': '73.11.01', 'descrizione': 'Ideazione di campagne pubblicitarie', 'coef': 0.78},
      {'codice': '73.11.02', 'descrizione': 'Marketing, Social Media e Advertising', 'coef': 0.78},
      {'codice': '70.22.09', 'descrizione': 'Consulenza imprenditoriale e gestionale', 'coef': 0.78},
      {'codice': '74.20.19', 'descrizione': 'Fotografia e riprese video', 'coef': 0.78},
      {'codice': '85.52.09', 'descrizione': 'Formazione culturale, corsi e coaching', 'coef': 0.78},
      {'codice': '47.91.10', 'descrizione': 'Commercio al dettaglio (E-commerce)', 'coef': 0.40},
      {'codice': '46.19.02', 'descrizione': 'Procacciatori d\'affari / Agenti di commercio', 'coef': 0.62},
      {'codice': '56.10.11', 'descrizione': 'Ristoranti, Pizzerie con somministrazione', 'coef': 0.40},
      {'codice': '56.30.00', 'descrizione': 'Bar e altri esercizi simili', 'coef': 0.40},
      {'codice': '96.02.01', 'descrizione': 'Servizi dei saloni di barbiere e parrucchiere', 'coef': 0.67},
      {'codice': '96.02.02', 'descrizione': 'Servizi degli istituti di bellezza ed estetica', 'coef': 0.67},
      {'codice': '86.90.29', 'descrizione': 'Altre professioni sanitarie (es. Psicologo)', 'coef': 0.78},
      {'codice': '69.10.10', 'descrizione': 'Attività degli studi legali (Avvocati)', 'coef': 0.78},
      {'codice': '69.20.11', 'descrizione': 'Servizi forniti da dottori commercialisti', 'coef': 0.78},
      {'codice': '71.11.00', 'descrizione': 'Attività degli studi di architettura', 'coef': 0.78},
      {'codice': '71.12.10', 'descrizione': 'Attività degli studi di ingegneria', 'coef': 0.78},
      {'codice': '41.20.00', 'descrizione': 'Costruzione di edifici (Edilizia)', 'coef': 0.86},
      {'codice': '43.21.01', 'descrizione': 'Installazione di impianti elettrici', 'coef': 0.86},
      {'codice': '43.22.01', 'descrizione': 'Installazione di impianti idraulici', 'coef': 0.86},
      {'codice': '68.31.00', 'descrizione': 'Agenti immobiliari', 'coef': 0.86},
      {'codice': '90.03.09', 'descrizione': 'Altre creazioni artistiche e letterarie (Copywriter)', 'coef': 0.67},
      {'codice': '96.09.09', 'descrizione': 'Altre attività di servizi per la persona', 'coef': 0.67},
    ];

    try {
      debugPrint('🚀 Avvio caricamento massivo di ${codiciDaCaricare.length} codici su Firebase...');
      
      for (var item in codiciDaCaricare) {
        // Usiamo il codice stesso (es. "62.01.00") come ID del documento, invece di una stringa casuale!
        final docRef = db.collection('codici_ateco').doc(item['codice'].toString());
        batch.set(docRef, item);
      }

      // Eseguiamo tutte le scritture in un colpo solo
      await batch.commit();
      debugPrint('✅ CARICAMENTO COMPLETATO CON SUCCESSO!');
    } catch (e) {
      debugPrint('❌ Errore durante il caricamento: $e');
    }
  }
}