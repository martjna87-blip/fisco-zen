import 'package:flutter/material.dart';
import 'wallet_provider.dart';
import '../widgets_shared/advisor_tip_card.dart';

enum AdvisorAction { vediFattureInRitardo, mettiAlSicuroTasse }

class AdvisorMessage {
  final AdvisorMood mood;
  final String title;
  final String message;
  final String? actionText;
  final AdvisorAction? action;
  final IconData? icon;

  AdvisorMessage({
    required this.mood,
    required this.title,
    required this.message,
    this.actionText,
    this.action,
    this.icon,
  });
}

class AdvisorEngine {
  static List<AdvisorMessage> getBusinessTips(WalletProvider wallet) {
    List<AdvisorMessage> tips = [];

    // ---------------------------------------------------------
    // 🔴 REGOLA 1: FATTURE IN RITARDO (> 15 giorni)
    // ---------------------------------------------------------
    int fattureInRitardo = 0;
    double importoInRitardo = 0.0;
    final now = DateTime.now();

    for (var f in wallet.fattureDaIncassare) {
      final dataStr = f['data']?.toString() ?? '';
      DateTime? dataFattura;
      
      if (dataStr.contains('/')) {
        final parts = dataStr.split('/');
        if (parts.length == 3) {
          dataFattura = DateTime(
            int.tryParse(parts[2]) ?? now.year,
            int.tryParse(parts[1]) ?? now.month,
            int.tryParse(parts[0]) ?? now.day,
          );
        }
      }

      if (dataFattura != null && now.difference(dataFattura).inDays >= 15) {
        fattureInRitardo++;
        importoInRitardo += (f['importo'] as num).toDouble();
      }
    }

    if (fattureInRitardo > 0) {
      tips.add(AdvisorMessage(
        mood: AdvisorMood.danger,
        title: 'Fatture in Scadenza 🔴',
        message: 'Ci sono $fattureInRitardo fattur${fattureInRitardo > 1 ? "e" : "a"} in ritardo da oltre 15 giorni per un totale di ${importoInRitardo.toStringAsFixed(0)} €. Bloccano la liquidità aziendale!',
        actionText: 'Vedi da incassare',
        action: AdvisorAction.vediFattureInRitardo,
        icon: Icons.warning_rounded,
      ));
    }

    // ---------------------------------------------------------
    // CALCOLO TASSE CON TOLLERANZA DECIMALI
    // ---------------------------------------------------------
    final double tasseDaAccantonare = wallet.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double riservaGiaAccantonata = wallet.accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);
    
    final double tasseTotaliCalcolate = tasseDaAccantonare + riservaGiaAccantonata;
    final double tasseAncoraDaSpostare = tasseTotaliCalcolate - riservaGiaAccantonata;

    // 🏆 REGOLA 2: 100% TASSE AL SICURO (Frase Neutra Impersonale)
    if (tasseTotaliCalcolate > 0.01 && tasseAncoraDaSpostare <= 0.01) {
      tips.add(AdvisorMessage(
        mood: AdvisorMood.success,
        title: 'Tasse al sicuro!',
        message: 'Ottimo lavoro! Il 100% delle tasse stimate è al sicuro nel salvadanaio. Tutto il resto degli incassi è profitto libero.',
        icon: Icons.shield_outlined,
      ));
    } 
    // ⚠️ REGOLA 3: TASSE ANCORA DA SPOSTARE
    else if (tasseAncoraDaSpostare > 0.01) {
      tips.add(AdvisorMessage(
        mood: AdvisorMood.warning,
        title: 'Attenzione alle Tasse',
        message: 'Ci sono ${tasseAncoraDaSpostare.toStringAsFixed(0)} € di tasse generate dai recenti incassi sparse nei conti. Spostale nel salvadanaio per protezione.',
        actionText: 'Metti al sicuro',
        action: AdvisorAction.mettiAlSicuroTasse,
        icon: Icons.shield_outlined,
      ));
    }

    // 🙈 Filtra automaticamente i tip che l'utente ha già chiuso con la X
    return tips.where((t) => !wallet.dismissedTipKeys.contains(t.title)).toList();
  }
  // 👛 CASSETTO WALLET (Promotore Finanziario Personale)
  static List<AdvisorMessage> getPersonalTips(WalletProvider wallet) {
    List<AdvisorMessage> tips = [];

    // ---------------------------------------------------------
    // ⚠️ REGOLA: CUSCINETTO / MINIMO VITALE PER MESI NO-LAVORO
    // ---------------------------------------------------------
    final int mesiNoLavoro = 12 - wallet.mesiAttivi;

    if (mesiNoLavoro > 0) {
      final double targetMinimoVitale = wallet.nettoTargetMensile;
      final double disponibilitaNetta = wallet.nettoSpendibile;

      // Se la liquidità disponibile non copre il minimo vitale impostato nell'onboarding
      if (disponibilitaNetta < targetMinimoVitale) {
        final double mancante = targetMinimoVitale - disponibilitaNetta;

        tips.add(AdvisorMessage(
          mood: AdvisorMood.warning,
          title: 'Cuscinetto Ferie da Integrare 🏖️',
          message: 'Per garantire il tuo minimo vitale di ${targetMinimoVitale.toStringAsFixed(0)} € durante i $mesiNoLavoro mesi di pausa, ti mancano ancora ${mancante.toStringAsFixed(0)} €. Controlla la gestione spese!',
          //actionText: 'Analizza Wallet',
          icon: Icons.radar_rounded,
        ));
      }
    }

    return tips.where((t) => !wallet.dismissedTipKeys.contains(t.title)).toList();
  }
}