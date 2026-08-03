import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/notifications_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formattaTempo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Adesso';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} ore fa';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color _coloreTipo(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return const Color(0xFF10B981); // Verde
      case AppNotificationType.warning:
        return const Color(0xFFF59E0B); // Arancio
      case AppNotificationType.error:
        return const Color(0xFFEF4444); // Rosso
      case AppNotificationType.info:
      default:
        return const Color(0xFF3B82F6); // Blu
    }
  }

  IconData _iconaTipo(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return Icons.check_circle_rounded;
      case AppNotificationType.warning:
        return Icons.warning_amber_rounded;
      case AppNotificationType.error:
        return Icons.error_outline_rounded;
      case AppNotificationType.info:
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationsProvider>();
    final lista = notifProvider.notifiche;
    final int nonLette = notifProvider.nonLetteCount;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F12),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Centro Notifiche',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (nonLette > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$nonLette',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (lista.isNotEmpty) ...[
            // Segna tutte come lette
            IconButton(
              tooltip: 'Segna tutte come lette',
              icon: const Icon(Icons.done_all_rounded, color: Color(0xFF2DD4BF), size: 20),
              onPressed: () => context.read<NotificationsProvider>().segnaTutteComeLette(),
            ),
            // Svuota storico
            IconButton(
              tooltip: 'Svuota notifiche',
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white38, size: 20),
              onPressed: () => context.read<NotificationsProvider>().svuotaTutto(),
            ),
          ],
        ],
      ),
      body: lista.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, color: Colors.white.withOpacity(0.15), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Nessuna notifica presente',
                    style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final n = lista[index];
                final colore = _coloreTipo(n.type);

                return Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    context.read<NotificationsProvider>().eliminaNotifica(n.id);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  ),
                  child: InkWell(
                    onTap: () => context.read<NotificationsProvider>().segnaComeLetta(n.id),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: n.letta
                            ? const Color(0xFF141417).withOpacity(0.6)
                            : const Color(0xFF1C1C21),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: n.letta
                              ? Colors.white.withOpacity(0.05)
                              : colore.withOpacity(0.4),
                          width: n.letta ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colore.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_iconaTipo(n.type), color: colore, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.titolo,
                                        style: TextStyle(
                                          color: n.letta ? Colors.white70 : Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formattaTempo(n.data),
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.messaggio,
                                  style: TextStyle(
                                    color: n.letta ? Colors.white38 : Colors.white70,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!n.letta) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colore,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}