// 📍 INIZIO CODICE COMPLETO: lib/data/notifications_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets_shared/app_notifications.dart';

enum AppNotificationType { info, success, warning, error }

class AppNotificationItem {
  final String id;
  final String titolo;
  final String messaggio;
  final DateTime data;
  final AppNotificationType type;
  final String? actionType;
  bool letta;

  AppNotificationItem({
    required this.id,
    required this.titolo,
    required this.messaggio,
    required this.data,
    this.type = AppNotificationType.info,
    this.actionType,
    this.letta = false,
  });

  // 📦 Metodo per convertire la notifica in JSON da salvare
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titolo': titolo,
      'messaggio': messaggio,
      'data': data.toIso8601String(),
      'type': type.name,
      'actionType': actionType,
      'letta': letta,
    };
  }

  // 🔓 Metodo per ricostruire la notifica dal JSON salvato
  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] ?? '',
      titolo: json['titolo'] ?? '',
      messaggio: json['messaggio'] ?? '',
      data: DateTime.tryParse(json['data'] ?? '') ?? DateTime.now(),
      type: AppNotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AppNotificationType.info,
      ),
      actionType: json['actionType'],
      letta: json['letta'] ?? false,
    );
  }
}

class NotificationsProvider extends ChangeNotifier {
  final List<AppNotificationItem> _notifiche = [];
  bool _isInitialized = false;

  NotificationsProvider() {
    _inizializzaNotifiche();
  }

  // 💾 Salva l'intera lista delle notifiche nella memoria permanente
  Future<void> _salvaNotificheLocali() async {
    if (!_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_notifiche.map((n) => n.toJson()).toList());
    await prefs.setString('notifiche_salvate_v1', jsonString);
  }

  // 🔄 Carica le notifiche all'avvio e gestisce benvenuto/bentornato
  Future<void> _inizializzaNotifiche() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Carica lo storico notifiche salvate
    final String? salvate = prefs.getString('notifiche_salvate_v1');
    if (salvate != null) {
      try {
        final List<dynamic> decoded = jsonDecode(salvate);
        _notifiche.addAll(decoded.map((item) => AppNotificationItem.fromJson(item)).toList());
      } catch (e) {
        debugPrint('Errore nel parsing delle notifiche: $e');
      }
    }

    // 2. Controllo Primo Accesso (Mostra il benvenuto 1 sola volta)
    final bool benvenutoMostrato = prefs.getBool('welcome_shown') ?? false;

    if (!benvenutoMostrato) {
      _notifiche.add(
        AppNotificationItem(
          id: 'welcome_1',
          titolo: 'Benvenuto in FiscOn! 🎉',
          messaggio: 'Il tuo centro notifiche è attivo. Qui troverai avvisi su tasse, scadenze e fatture in ritardo.',
          data: DateTime.now(),
          type: AppNotificationType.info,
          letta: false,
        ),
      );
      await prefs.setBool('welcome_shown', true);
    }

    // 3. Controllo Inattività Prolungata (> 30 giorni)
    final String? ultimoAccessoStr = prefs.getString('ultimo_accesso');
    final DateTime ora = DateTime.now();

    if (ultimoAccessoStr != null) {
      final DateTime ultimoAccesso = DateTime.parse(ultimoAccessoStr);
      if (ora.difference(ultimoAccesso).inDays >= 30) {
        _notifiche.add(
          AppNotificationItem(
            id: 'welcome_back_${ora.millisecondsSinceEpoch}',
            titolo: 'Bentornato su FiscON! 👋',
            messaggio: 'È da un po\' che non aggiorni i tuoi dati. Dai un\'occhiata alle fatture e alla riserva tasse.',
            data: ora,
            type: AppNotificationType.info,
            letta: false,
          ),
        );
      }
    }

    // 🧹 AUTO-PULIZIA: Elimina le notifiche più vecchie di 30 giorni per non intasare la memoria
    final limiteVecchio = ora.subtract(const Duration(days: 30));
    _notifiche.removeWhere((n) => n.data.isBefore(limiteVecchio));

    // 4. Salva la data di accesso corrente e aggiorna
    await prefs.setString('ultimo_accesso', ora.toIso8601String());
    
    _isInitialized = true;
    _notifiche.sort((a, b) => b.data.compareTo(a.data)); // Ordina dalla più recente
    await _salvaNotificheLocali();
    notifyListeners();
  }

  List<AppNotificationItem> get notifiche => List.unmodifiable(_notifiche);

  int get nonLetteCount => _notifiche.where((n) => !n.letta).length;

  void mostraESalva({
    required BuildContext context,
    required String titolo,
    required String messaggio,
    AppNotificationType type = AppNotificationType.info,
    String? actionType,
  }) {
    aggiungiNotifica(
      titolo: titolo,
      messaggio: messaggio,
      type: type,
      actionType: actionType,
    );

    NotificationType toastType = NotificationType.success;
    if (type == AppNotificationType.warning) toastType = NotificationType.warning;
    if (type == AppNotificationType.error) toastType = NotificationType.error;

    AppNotifications.mostraInAlto(
      context,
      '$titolo\n$messaggio',
      type: toastType,
    );
  }

  void aggiungiNotifica({
    required String titolo,
    required String messaggio,
    AppNotificationType type = AppNotificationType.info,
    String? actionType,
  }) {
    final nuova = AppNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titolo: titolo,
      messaggio: messaggio,
      data: DateTime.now(),
      type: type,
      actionType: actionType,
    );
    _notifiche.insert(0, nuova);
    _salvaNotificheLocali();
    notifyListeners();
  }

  void segnaComeLetta(String id) {
    final index = _notifiche.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifiche[index].letta) {
      _notifiche[index].letta = true;
      _salvaNotificheLocali();
      notifyListeners();
    }
  }

  void segnaTutteComeLette() {
    bool modificate = false;
    for (var n in _notifiche) {
      if (!n.letta) {
        n.letta = true;
        modificate = true;
      }
    }
    if (modificate) {
      _salvaNotificheLocali();
      notifyListeners();
    }
  }

  void eliminaNotifica(String id) {
    _notifiche.removeWhere((n) => n.id == id);
    _salvaNotificheLocali();
    notifyListeners();
  }

  void svuotaTutto() {
    _notifiche.clear();
    _salvaNotificheLocali();
    notifyListeners();
  }

  void rimuoviNotificaFattura(String idFattura) {
    final String notifId = 'ritardo_$idFattura';
    _notifiche.removeWhere((n) => n.id == notifId);
    _salvaNotificheLocali();
    notifyListeners();
  }

  int _calcolaGiorniTrascorsi(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return 0;
    DateTime? parsedDate = DateTime.tryParse(dataStr);

    if (parsedDate == null && dataStr.contains('/')) {
      final parts = dataStr.split('/');
      if (parts.length == 3) {
        final g = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final a = int.tryParse(parts[2]);
        if (g != null && m != null && a != null) parsedDate = DateTime(a, m, g);
      }
    }

    if (parsedDate == null) {
      final List<String> mesi = [
        'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
        'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'
      ];
      final parts = dataStr.toLowerCase().split(' ');
      if (parts.length >= 3) {
        final giorno = int.tryParse(parts[0]);
        final meseIdx = mesi.indexOf(parts[1]);
        final anno = int.tryParse(parts[2]);
        if (giorno != null && meseIdx != -1 && anno != null) {
          parsedDate = DateTime(anno, meseIdx + 1, giorno);
        }
      }
    }

    if (parsedDate == null) return 0;
    final differenza = DateTime.now().difference(parsedDate).inDays;
    return differenza > 0 ? differenza : 0;
  }

  void verificaFattureInRitardo(List<Map<String, dynamic>> fattureDaIncassare) {
    bool modificato = false;

    for (var f in fattureDaIncassare) {
      final String idFattura = f['id']?.toString() ?? '';
      final String cliente = f['cliente']?.toString() ?? 'Cliente';
      final String dataStr = f['data']?.toString() ?? '';
      final double importo = (f['importo'] as num?)?.toDouble() ?? 0.0;

      final int giorni = _calcolaGiorniTrascorsi(dataStr);

      if (giorni >= 15) {
        final String notifId = 'ritardo_$idFattura';
        final int indexEsistente = _notifiche.indexWhere((n) => n.id == notifId);

        if (indexEsistente == -1) {
          _notifiche.insert(
            0,
            AppNotificationItem(
              id: notifId,
              titolo: '⚠️ Fattura in ritardo (+15 gg)',
              messaggio: 'La fattura di $cliente da ${importo.toStringAsFixed(0)} € (del $dataStr) attende il saldo da $giorni giorni.',
              data: DateTime.now(),
              type: AppNotificationType.warning,
              actionType: 'INCASSO_FATTURE',
            ),
          );
          modificato = true;
        } else {
          if (_notifiche[indexEsistente].actionType == null) {
            final vecchia = _notifiche[indexEsistente];
            _notifiche[indexEsistente] = AppNotificationItem(
              id: vecchia.id,
              titolo: vecchia.titolo,
              messaggio: vecchia.messaggio,
              data: vecchia.data,
              type: vecchia.type,
              actionType: 'INCASSO_FATTURE',
              letta: vecchia.letta,
            );
            modificato = true;
          }
        }
      }
    }

    if (modificato) {
      _notifiche.sort((a, b) => b.data.compareTo(a.data));
      _salvaNotificheLocali();
      notifyListeners();
    }
  }
}
// 📍 FINE CODICE COMPLETO: lib/data/notifications_provider.dart