import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AppImagePickerSheet {
  /// Mostra la modale di scelta e restituisce l'immagine selezionata (o null se l'utente annulla)
  static Future<XFile?> mostra(BuildContext context, {String titolo = 'Carica Immagine'}) async {
    final picker = ImagePicker();

    return await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 36),
          decoration: const BoxDecoration(
            color: Color(0xFF1F2428), // Ardesia Scura FiscON
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ➖ Pillola superiore (Handle)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              
              // 📝 Titolo Dinamico
              Text(
                titolo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 📸 Opzione 1: Fotocamera
              _buildOpzione(
                context,
                icona: Icons.camera_alt_rounded,
                colore: const Color(0xFF2DD4BF), // Verde Ottanio
                testo: 'Scatta una foto',
                sottotitolo: 'Usa la fotocamera del dispositivo',
                onTap: () async {
                  final XFile? foto = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70, // ⚡ Ottimizzato per AI: peso ridotto del 90%
                    maxWidth: 1200,   // ⚡ Risoluzione massima ideale per testo scontrini
                  );
                  if (context.mounted) Navigator.pop(context, foto);
                },
              ),
              
              const SizedBox(height: 12),

              // 🖼️ Opzione 2: Galleria
              _buildOpzione(
                context,
                icona: Icons.photo_library_rounded,
                colore: const Color(0xFF3B82F6), // Blu FiscON
                testo: 'Scegli dalla galleria',
                sottotitolo: 'Carica un\'immagine salvata',
                onTap: () async {
                  final XFile? foto = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                    maxWidth: 1200,
                  );
                  if (context.mounted) Navigator.pop(context, foto);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🎨 Helper per le voci della modale
  static Widget _buildOpzione(
    BuildContext context, {
    required IconData icona,
    required Color colore,
    required String testo,
    required String sottotitolo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colore.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icona, color: colore, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(testo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(sottotitolo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}