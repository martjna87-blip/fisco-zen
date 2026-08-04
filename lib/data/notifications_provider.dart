import 'package:flutter/material.dart';
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
}

class NotificationsProvider extends ChangeNotifier {
  final List<AppNotificationItem> _notifiche = [
    AppNotificationItem(
      id: 'welcome_1',
      titolo: 'Benvenuto in FiscOn! 🎉',
      messaggio: 'Il tuo centro notifiche è attivo. Qui troverai avvisi su tasse, scadenze e fatture in ritardo.',
      data: DateTime.now().subtract(const Duration(minutes: 5)),
      type: AppNotificationType.info,
      letta: false,
    ),
  ];

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
    notifyListeners();
  }

  void segnaComeLetta(String id) {
    final index = _notifiche.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifiche[index].letta) {
      _notifiche[index].letta = true;
      notifyListeners();
    }
  }

  void segnaTutteComeLette() {
    for (var n in _notifiche) {
      n.letta = true;
    }
    notifyListeners();
  }

  void eliminaNotifica(String id) {
    _notifiche.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void svuotaTutto() {
    _notifiche.clear();
    notifyListeners();
  }

  void rimuoviNotificaFattura(String idFattura) {
    final String notifId = 'ritardo_$idFattura';
    _notifiche.removeWhere((n) => n.id == notifId);
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
      notifyListeners();
    }
  }
}