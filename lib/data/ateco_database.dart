import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AtecoDatabase {
  // 1. Questa è la lista "Viva" che l'app leggerà sempre. 
  // All'avvio la riempiamo subito con i dati di emergenza.
  static List<Map<String, dynamic>> lista = List.from(_listaDiEmergenza);

  // 2. Il motore di Firebase
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 3. La funzione che aggiorna i dati dal Cloud
  static Future<void> sincronizzaCodiciDaFirebase() async {
    try {
      debugPrint('🔄 Inizio download codici ATECO da Firebase...');
      
      final snapshot = await _db.collection('codici_ateco').get();
      
      final List<Map<String, dynamic>> codiciScaricati = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'codice': data['codice']?.toString() ?? '',
          'descrizione': data['descrizione']?.toString() ?? '',
          'coef': (data['coef'] ?? 0.78).toDouble(), 
        };
      }).toList();

      if (codiciScaricati.isNotEmpty) {
        // ✨ MAGIA: Abbiamo i dati nuovi! Sostituiamo quelli vecchi/locali
        lista = codiciScaricati;
        debugPrint('✅ Download completato! Ora stiamo usando ${lista.length} codici aggiornati da Firebase.');
      } else {
        debugPrint('⚠️ Firebase è vuoto, continuo a usare la lista locale.');
      }

    } catch (e) {
      debugPrint('❌ Nessuna connessione o errore Firebase: $e. Uso la lista offline di emergenza.');
    }
  }

  // 4. Metodo per cercare (ora cercherà sempre nella lista più aggiornata che ha)
  static Map<String, dynamic> cercaPerCodice(String codiceCercato) {
    return lista.firstWhere(
      (item) => item['codice'] == codiceCercato,
      orElse: () => {'codice': codiceCercato, 'descrizione': 'Codice non in lista', 'coef': 0.78},
    );
  }

  // --- 🛡️ LISTA DI EMERGENZA (Se non c'è internet) ---
  static const List<Map<String, dynamic>> _listaDiEmergenza = [
    {'codice': '74.10.21', 'descrizione': 'Graphic design, Web design, UI/UX (OFFLINE)', 'coef': 0.78},
    {'codice': '62.01.00', 'descrizione': 'Sviluppo software e programmazione (OFFLINE)', 'coef': 0.78},
    {'codice': '70.22.09', 'descrizione': 'Consulenza imprenditoriale (OFFLINE)', 'coef': 0.78},
    {'codice': '47.91.10', 'descrizione': 'Commercio al dettaglio E-commerce (OFFLINE)', 'coef': 0.40},
    {'codice': '56.10.11', 'descrizione': 'Ristoranti, Pizzerie, Bar (OFFLINE)', 'coef': 0.40},
  ];
}