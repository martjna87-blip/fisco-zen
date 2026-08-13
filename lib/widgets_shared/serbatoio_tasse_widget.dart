import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/app_secondary_popup.dart';

class SerbatoioTasseWidget extends StatefulWidget {
  final Color cardColor;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const SerbatoioTasseWidget({
    super.key,
    this.cardColor = const Color(0xFF292524),
    this.isCollapsible = true,
    this.initiallyExpanded = false,
  });

  static String _formattaInt(double importo) {
    final int intVal = importo.round();
    return intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static String _formattaValuta(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intPart,${parti[1]} €';
  }

  static double _parseImportoSicuro(String text) {
    if (text.trim().isEmpty) return 0.0;
    String pulito = text.trim().replaceAll(' ', '').replaceAll('€', '');
    
    if (pulito.contains('.') && pulito.contains(',')) {
      if (pulito.lastIndexOf(',') > pulito.lastIndexOf('.')) {
        pulito = pulito.replaceAll('.', '').replaceAll(',', '.');
      } else {
        pulito = pulito.replaceAll(',', '');
      }
    } else if (pulito.contains('.')) {
      final parti = pulito.split('.');
      if (parti.last.length == 1 || parti.last.length == 2) {
        final dec = parti.removeLast();
        pulito = '${parti.join('')}.$dec';
      } else {
        pulito = pulito.replaceAll('.', '');
      }
    } else {
      pulito = pulito.replaceAll(',', '.');
    }

    return double.tryParse(pulito) ?? 0.0;
  }

  static Widget _buildBarraAvanzamentoSmart(int percentualeInt) {
    if (percentualeInt < 100) {
      final int flexRiempito = percentualeInt.clamp(0, 100);
      final int flexVuoto = 100 - flexRiempito;

      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 8,
          color: Colors.white10,
          child: Row(
            children: [
              if (flexRiempito > 0)
                Expanded(
                  flex: flexRiempito,
                  child: Container(color: const Color(0xFFF59E0B)),
                ),
              if (flexVuoto > 0)
                Expanded(
                  flex: flexVuoto,
                  child: const SizedBox(),
                ),
            ],
          ),
        ),
      );
    }

    const int flexVerde = 100;
    final int flexCiano = percentualeInt - 100;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 8,
        color: Colors.white10,
        child: Row(
          children: [
            Expanded(
              flex: flexVerde,
              child: Container(color: const Color(0xFF10B981)),
            ),
            if (flexCiano > 0)
              Expanded(
                flex: flexCiano,
                child: Container(color: const Color(0xFF06B6D4)),
              ),
          ],
        ),
      ),
    );
  }

  static void mostraDialog(BuildContext context, {Color cardColor = const Color(0xFF292524)}) {
    final walletProvider = context.read<WalletProvider>();
    final accounts = walletProvider.accounts;

    if (accounts.length < 2) {
      AppNotifications.mostraInAlto(
        context, 
        'Devi avere almeno due conti per gestire le tasse', 
        type: NotificationType.warning,
      );
      return;
    }

    final double tasseTotaliCalcolate = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));

    final double riservaGiaAccantonata = accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double mancanteReale = (tasseTotaliCalcolate - riservaGiaAccantonata).clamp(0.0, double.infinity);

    final contoPrincipale = accounts.firstWhere(
      (a) => !a.title.toLowerCase().contains('salvadanaio'),
      orElse: () => accounts[0],
    );

    final salvadanaioTasse = accounts.firstWhere(
      (a) => a.title.toLowerCase().contains('salvadanaio tasse'),
      orElse: () => accounts.length > 1 ? accounts[1] : accounts[0],
    );

    final contiDisponibili = accounts
        .where((a) => a.id != salvadanaioTasse.id)
        .toList();

    String contoSorgenteAccantonaId = contiDisponibili.isNotEmpty
        ? contiDisponibili[0].id
        : contoPrincipale.id;

    String contoDestinazioneSbloccoId = contiDisponibili.isNotEmpty
        ? contiDisponibili[0].id
        : contoPrincipale.id;

    bool modalitaAccantona = true;

    final TextEditingController importoController = TextEditingController(
      text: mancanteReale > 0 ? mancanteReale.toStringAsFixed(2).replaceAll('.', ',') : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final double importoInserito = _parseImportoSicuro(importoController.text);
          
          final double nuovaRiservaTotale = modalitaAccantona
              ? (riservaGiaAccantonata + importoInserito)
              : (riservaGiaAccantonata - importoInserito).clamp(0.0, double.infinity);

          final double calcoloPercentualeGreggio = tasseTotaliCalcolate > 0.01 
              ? (nuovaRiservaTotale / tasseTotaliCalcolate * 100) 
              : (nuovaRiservaTotale > 0 ? 100.0 : 0.0);
              
          final int percentualeInt = (calcoloPercentualeGreggio - 100).abs() < 0.1 
              ? 100 
              : calcoloPercentualeGreggio.round();
              
          final double extraCuscinetto = nuovaRiservaTotale > tasseTotaliCalcolate 
              ? nuovaRiservaTotale - tasseTotaliCalcolate 
              : 0.0;

          final Color coloreAttuale = modalitaAccantona ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);

          return AppSecondaryPopup(
            backgroundColor: cardColor,
            icon: modalitaAccantona ? Icons.shield_outlined : Icons.lock_open_rounded,
            iconColor: coloreAttuale,
            titolo: modalitaAccantona ? 'Accantona Tasse' : 'Sblocca Fondi Tasse',
            testoConferma: modalitaAccantona ? 'Metti al Sicuro' : 'Sblocca Cifra',
            onConferma: () {
              if (importoInserito <= 0) {
                AppNotifications.mostraInAlto(
                  context,
                  'Importo non valido! Inserisci una cifra corretta (es. 100 o 11,50).',
                  type: NotificationType.warning,
                );
                return;
              }

              if (modalitaAccantona) {
                final contoSorgente = accounts.firstWhere((a) => a.id == contoSorgenteAccantonaId);

                if (contoSorgente.amount < importoInserito) {
                  AppNotifications.mostraInAlto(
                    context,
                    'Saldo insufficiente su ${contoSorgente.title}!',
                    type: NotificationType.error,
                  );
                  return;
                }

                walletProvider.eseguiGiroconto(
                  daAccountId: contoSorgenteAccantonaId,
                  aAccountId: salvadanaioTasse.id,
                  importo: importoInserito,
                  isAccantonamentoTasse: true,
                );
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(
                  context,
                  'Messo al sicuro il capitale per le tasse da ${contoSorgente.title}! 🛡️',
                  type: NotificationType.success,
                );
              } else {
                if (salvadanaioTasse.amount < importoInserito) {
                  AppNotifications.mostraInAlto(
                    context,
                    'Fondi insufficienti nel Salvadanaio Tasse!',
                    type: NotificationType.error,
                  );
                  return;
                }

                final contoDestinazione = accounts.firstWhere((a) => a.id == contoDestinazioneSbloccoId);

                walletProvider.eseguiGiroconto(
                  daAccountId: salvadanaioTasse.id,
                  aAccountId: contoDestinazioneSbloccoId,
                  importo: importoInserito,
                  isAccantonamentoTasse: false,
                );
                Navigator.pop(ctx);
                AppNotifications.mostraInAlto(
                  context,
                  'Sbloccati ${_formattaValuta(importoInserito)} verso ${contoDestinazione.title}! 🔓',
                  type: NotificationType.warning,
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              modalitaAccantona = true;
                              importoController.text = mancanteReale > 0 ? mancanteReale.toStringAsFixed(2).replaceAll('.', ',') : '';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: modalitaAccantona ? const Color(0xFF3B82F6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                '🛡️ Accantona',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              modalitaAccantona = false;
                              importoController.text = '';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !modalitaAccantona ? const Color(0xFFF59E0B) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                '🔓 Sblocca',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Totale Tasse Dovute:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(_formattaValuta(tasseTotaliCalcolate), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Già in Salvadanaio:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(_formattaValuta(riservaGiaAccantonata), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Copertura: $percentualeInt%',
                          style: TextStyle(
                            color: percentualeInt >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (extraCuscinetto > 0)
                          Text(
                            '+${_formattaInt(extraCuscinetto)} € Cuscinetto',
                            style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildBarraAvanzamentoSmart(percentualeInt),
                  ],
                ),

                const SizedBox(height: 16),

                if (modalitaAccantona) ...[
                  DropdownButtonFormField<String>(
                    value: contoSorgenteAccantonaId,
                    dropdownColor: cardColor,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Preleva la cifra da:',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3B82F6), size: 18),
                    ),
                    items: contiDisponibili.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text('${acc.title} (${_formattaInt(acc.amount)} €)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          contoSorgenteAccantonaId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: contoDestinazioneSbloccoId,
                    dropdownColor: cardColor,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Versa la cifra su:',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFF59E0B), size: 18),
                    ),
                    items: contiDisponibili.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text('${acc.title} (${_formattaInt(acc.amount)} €)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          contoDestinazioneSbloccoId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: importoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: modalitaAccantona ? 'Importo da spostare nel Salvadanaio (€)' : 'Importo da prelevare dal Salvadanaio (€)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: Icon(
                      modalitaAccantona ? Icons.savings_rounded : Icons.payments_rounded, 
                      color: coloreAttuale, 
                      size: 20
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  State<SerbatoioTasseWidget> createState() => _SerbatoioTasseWidgetState();
}

class _SerbatoioTasseWidgetState extends State<SerbatoioTasseWidget> with SingleTickerProviderStateMixin {
  late bool _isEspanso;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _isEspanso = widget.initiallyExpanded;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    final double riservaAccantonata = walletProvider.accounts
        .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, acc) => sum + acc.amount);

    final double mancanteReale = (tasseTotaliCalcolate - riservaAccantonata).clamp(0.0, double.infinity);

    final double percentualeRatio = tasseTotaliCalcolate > 0.01
        ? (riservaAccantonata / tasseTotaliCalcolate).clamp(0.0, 1.0)
        : (riservaAccantonata > 0 ? 1.0 : 0.0);

    final double calcoloPercentualeGreggio = tasseTotaliCalcolate > 0.01 
        ? (riservaAccantonata / tasseTotaliCalcolate * 100) 
        : (riservaAccantonata > 0 ? 100.0 : 0.0);

    final int percentualeTextInt = (calcoloPercentualeGreggio - 100).abs() < 0.1 
        ? 100 
        : calcoloPercentualeGreggio.round();

    final double cuscinettoExtraVal = riservaAccantonata > tasseTotaliCalcolate
        ? (riservaAccantonata - tasseTotaliCalcolate)
        : 0.0;

    final Color statusColor = percentualeTextInt >= 100 
        ? const Color(0xFF10B981) 
        : const Color(0xFFF59E0B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 📌 1. HEADER CON AZIONI SEPARATE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (widget.isCollapsible) {
                        setState(() {
                          _isEspanso = !_isEspanso;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Serbatoio Riserva Tasse',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (widget.isCollapsible) ...[
                          const SizedBox(width: 6),
                          Icon(
                            _isEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: const Color(0xFF1E293B)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percentualeTextInt% Coperto',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 📌 2. CONTENUTO ESPANDIBILE (SFERA CON ONDA LIQUIDA ANIMATA)
            if (!widget.isCollapsible || _isEspanso) ...[
              const SizedBox(height: 18),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => SerbatoioTasseWidget.mostraDialog(context, cardColor: const Color(0xFF1E293B)),
                child: Center(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            width: 120,
                            height: 120,
                            color: Colors.black.withOpacity(0.3),
                            child: AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _LiquidWavePainter(
                                    animationValue: _waveController.value,
                                    percentage: percentualeRatio,
                                    fillColor: statusColor,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.15),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'IN SALVADANAIO',
                              style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8), // 👈 Ora ha spazio per respirare!
                            Text(
                              '${SerbatoioTasseWidget._formattaInt(riservaAccantonata)} €',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4), // 👈 Spazio aumentato
                            Text(
                              'su ${SerbatoioTasseWidget._formattaInt(tasseTotaliCalcolate)} €',
                              style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    mancanteReale > 0 ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                    color: mancanteReale > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mancanteReale > 0
                          ? 'Consiglio: accantona i ${SerbatoioTasseWidget._formattaInt(mancanteReale)} € mancanti per metterti al sicuro.'
                          : (cuscinettoExtraVal > 0
                              ? 'Ottimo! Hai +${SerbatoioTasseWidget._formattaInt(cuscinettoExtraVal)} € di cuscinetto extra protetto.'
                              : 'Ottimo! Hai accantonato tutta la stima fiscale dovuta.'),
                      style: TextStyle(
                        color: mancanteReale > 0 ? const Color(0xFFF59E0B) : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 🎨 PAINTER DELL'ONDA LIQUIDA ANIMATA (Definito a livello globale)
class _LiquidWavePainter extends CustomPainter {
  final double animationValue;
  final double percentage;
  final Color fillColor;

  _LiquidWavePainter({
    required this.animationValue,
    required this.percentage,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (percentage <= 0.0) return;

    final path = Path();
    final double clampedPct = percentage.clamp(0.0, 1.0);
    final double baseHeight = size.height * (1.0 - clampedPct);
    final double waveAmplitude = (clampedPct > 0.02 && clampedPct < 0.98) ? 4.0 : 0.0;

    path.moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final double y = baseHeight +
          math.sin((x / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * waveAmplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withOpacity(0.85),
          fillColor.withOpacity(0.35),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.percentage != percentage ||
        oldDelegate.fillColor != fillColor;
  }
}