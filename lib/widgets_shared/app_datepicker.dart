import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 🇮🇹 FORMATTATORE CHE INSERISCE IN AUTOMATICO LE BARRE NELLA DATA (es. 05/08/2026)
class _DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);

    var newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        newText += '/';
      }
      newText += text[i];
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AppDatePicker {
  /// 📅 Mostra il calendario FiscON con tasto "Oggi" (Reset rapido al mese odierno) e Matita ✏️
  static Future<DateTime?> selezionaData(
    BuildContext context, {
    required DateTime dataIniziale,
    DateTime? primaData,
    DateTime? ultimaData,
  }) async {
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext ctx) {
        return _AppDatePickerDialog(
          initialDate: dataIniziale,
          firstDate: primaData ?? DateTime(2020),
          lastDate: ultimaData ?? DateTime(2035),
        );
      },
    );
  }
}

class _AppDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<_AppDatePickerDialog> {
  late DateTime _selectedDate;
  bool _isTextInputMode = false;
  final TextEditingController _textController = TextEditingController();
  String? _errorText;

  // 🔑 KEY PER FORZARE IL RESET DEL CALENDARIO AL MESE CORRENTE QUANDO SI PREME "OGGI"
  int _calendarResetKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _textController.text = _formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final g = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$g/$m/${dt.year}';
  }

  void _parseAndConfirmTextDate() {
    final text = _textController.text.trim();
    final parti = text.split('/');
    if (parti.length == 3) {
      final giorno = int.tryParse(parti[0]);
      final mese = int.tryParse(parti[1]);
      final anno = int.tryParse(parti[2]);

      if (giorno != null && mese != null && anno != null) {
        try {
          final dt = DateTime(anno, mese, giorno);
          if (dt.isAfter(widget.firstDate.subtract(const Duration(days: 1))) &&
              dt.isBefore(widget.lastDate.add(const Duration(days: 1)))) {
            Navigator.of(context).pop(dt);
            return;
          }
        } catch (_) {}
      }
    }

    setState(() {
      _errorText = 'Data non valida. Usa GG/MM/AAAA';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2DD4BF),
          onPrimary: Colors.black,
          surface: Color(0xFF18181B),
          onSurface: Colors.white,
        ),
        dialogBackgroundColor: const Color(0xFF18181B),
      ),
      child: Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        child: Container(
          width: 330,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 1. HEADER CON DATA SELEZIONATA E PULSANTE MATITA ✏️ / CALENDARIO 📅
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELEZIONA DATA',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isTextInputMode = !_isTextInputMode;
                        _errorText = null;
                        if (_isTextInputMode) {
                          _textController.text = _formatDate(_selectedDate);
                        }
                      });
                    },
                    tooltip: _isTextInputMode ? 'Scegli dal calendario' : 'Scrivi data manualmente',
                    icon: Icon(
                      _isTextInputMode ? Icons.calendar_today_rounded : Icons.edit_rounded,
                      color: const Color(0xFF2DD4BF),
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 12),

              // 📌 2. BODY: CALENDARIO OPPURE CAMPO DI TESTO CON MATITA ✏️
              if (_isTextInputMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_DateSlashFormatter()],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Data (GG/MM/AAAA)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      hintText: '05/08/2026',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 16),
                      errorText: _errorText,
                      prefixIcon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF2DD4BF)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
                      ),
                    ),
                    onSubmitted: (_) => _parseAndConfirmTextDate(),
                  ),
                ),
              ] else ...[
                // 📅 CALENDARIO CON KEY DINAMICA PER RESET ISTANTANEO AL TAP SU "OGGI"
                SizedBox(
                  height: 260,
                  child: CalendarDatePicker(
                    key: ValueKey(_calendarResetKey), // 👈 Quando cambia, il calendario torna in modalità giorno e sul mese corrente!
                    initialDate: _selectedDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    onDateChanged: (DateTime newDate) {
                      setState(() {
                        _selectedDate = newDate;
                      });
                    },
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 12),

              // 📌 3. FOOTER: TASTO "OGGI" A SINISTRA E ANNULLA/CONFERMA A DESTRA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ⚡ PULSANTE "OGGI" (FUNZIONA DA RESET AL MESE ODIERNO SENZA CHIUDERE)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime.now();
                        _calendarResetKey++; // 👈 Forza il reset della vista al mese di oggi
                        if (_isTextInputMode) {
                          _textController.text = _formatDate(_selectedDate);
                        }
                      });
                    },
                    icon: const Icon(Icons.today_rounded, color: Color(0xFF2DD4BF), size: 18),
                    label: const Text(
                      'Oggi',
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // AZIONI DESTRA: ANNULLA & CONFERMA
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text(
                          'Annulla',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DD4BF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          if (_isTextInputMode) {
                            _parseAndConfirmTextDate();
                          } else {
                            Navigator.of(context).pop(_selectedDate);
                          }
                        },
                        child: const Text(
                          'Conferma',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}