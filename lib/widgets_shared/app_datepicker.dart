import 'package:flutter/material.dart';

enum _VistaDatePicker { giorno, mese, anno }

class AppDatePicker extends StatefulWidget {
  final DateTime initialDate;

  const AppDatePicker({
    super.key,
    required this.initialDate,
  });

  static Future<DateTime?> selezionaData(
    BuildContext context, {
    required DateTime dataIniziale,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => AppDatePicker(initialDate: dataIniziale),
    );
  }

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  late DateTime _selectedDate;
  late DateTime _displayedDate;
  _VistaDatePicker _vistaCorrente = _VistaDatePicker.giorno;

  final List<String> _mesiBrevi = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
  ];

  final List<String> _mesiEstesi = [
    'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
    'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedDate = widget.initialDate;
  }

  String _formattaDataTesto(DateTime dt) {
    final gg = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$gg/$mm/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SELEZIONA DATA',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formattaDataTesto(_selectedDate),
                  style: const TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.edit_outlined, color: Color(0xFF2DD4BF), size: 18),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // Header navigazione mese/anno
            _buildHeaderNavigazione(),

            const SizedBox(height: 12),

            // Contenuto dinamico (Giorno -> Mese -> Anno)
            if (_vistaCorrente == _VistaDatePicker.giorno) _buildGrigliaGiorni(),
            if (_vistaCorrente == _VistaDatePicker.mese) _buildGrigliaMesi(),
            if (_vistaCorrente == _VistaDatePicker.anno) _buildGrigliaAnni(),

            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // Footer Pulsanti
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final oggi = DateTime.now();
                    setState(() {
                      _selectedDate = oggi;
                      _displayedDate = oggi;
                      _vistaCorrente = _VistaDatePicker.giorno;
                    });
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2DD4BF)),
                  label: const Text('Oggi', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, _selectedDate),
                      child: const Text('Conferma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderNavigazione() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (_vistaCorrente == _VistaDatePicker.giorno) {
                _vistaCorrente = _VistaDatePicker.anno;
              } else if (_vistaCorrente == _VistaDatePicker.anno) {
                _vistaCorrente = _VistaDatePicker.giorno;
              } else {
                _vistaCorrente = _VistaDatePicker.giorno;
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_mesiEstesi[_displayedDate.month - 1]} ${_displayedDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(
                  _vistaCorrente == _VistaDatePicker.giorno ? Icons.arrow_drop_down_rounded : Icons.arrow_drop_up_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_vistaCorrente == _VistaDatePicker.giorno)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _displayedDate = DateTime(_displayedDate.year, _displayedDate.month - 1);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _displayedDate = DateTime(_displayedDate.year, _displayedDate.month + 1);
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  // 1️⃣ Vista Anni: Cliccando su un anno passa alla selezione del MESE
  Widget _buildGrigliaAnni() {
    final int annoCorrente = DateTime.now().year;
    final List<int> anni = List.generate(12, (index) => (annoCorrente - 5) + index);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: anni.length,
      itemBuilder: (context, index) {
        final anno = anni[index];
        final isSelected = _displayedDate.year == anno;

        return InkWell(
          onTap: () {
            setState(() {
              _displayedDate = DateTime(anno, _displayedDate.month);
              _vistaCorrente = _VistaDatePicker.mese; // 👈 Passa direttamente alla vista Mesi!
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$anno',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  // 2️⃣ Vista Mesi: Cliccando su un mese passa alla selezione del GIORNO
  Widget _buildGrigliaMesi() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final meseIndex = index + 1;
        final isSelected = _displayedDate.month == meseIndex;

        return InkWell(
          onTap: () {
            setState(() {
              _displayedDate = DateTime(_displayedDate.year, meseIndex);
              _vistaCorrente = _VistaDatePicker.giorno; // 👈 Passa alla vista Giorni!
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _mesiBrevi[index],
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  // 3️⃣ Vista Giorni Calendario
  Widget _buildGrigliaGiorni() {
    final int primoGiornoSettimana = DateTime(_displayedDate.year, _displayedDate.month, 1).weekday;
    final int giorniNelMese = DateTime(_displayedDate.year, _displayedDate.month + 1, 0).day;
    final List<String> giorniSettimana = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: giorniSettimana
              .map((g) => SizedBox(
                    width: 32,
                    child: Text(
                      g,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: (primoGiornoSettimana - 1) + giorniNelMese,
          itemBuilder: (context, index) {
            if (index < primoGiornoSettimana - 1) {
              return const SizedBox.shrink();
            }

            final giornoNum = index - (primoGiornoSettimana - 1) + 1;
            final dataCella = DateTime(_displayedDate.year, _displayedDate.month, giornoNum);
            final isSelected = _selectedDate.year == dataCella.year &&
                _selectedDate.month == dataCella.month &&
                _selectedDate.day == dataCella.day;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = dataCella;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2DD4BF) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$giornoNum',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}