import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;import '../data/auth_provider.dart';
import '../data/wallet_provider.dart';
import '../main.dart';
import '3_4_PI_pro_upgrade.dart';
import '1_main_menu.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _apriLink(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossibile aprire il link web.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Errore apertura URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Utente FiscON';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Stile scuro FiscON
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profilo & Impostazioni',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 SEZIONE ACCOUNT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF2DD4BF),
                    child: Icon(Icons.person, color: Color(0xFF0F172A), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Connesso',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 👑 SEZIONE PIANO & ABBONAMENTO
            const Text(
              'ABBONAMENTO & PROFILO FISCALE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B)),
                    title: Text(
                      walletProvider.isProUser ? 'FiscON PRO Attivo' : 'Passa a FiscON PRO',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      walletProvider.isProUser
                          ? 'Tutte le funzioni sbloccate'
                          : 'Sblocca riserva tasse e pianificazione',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () {
                      Navigator.push(
                        context,
MaterialPageRoute(builder: (context) => const ProUpgradeSheet(funzionalita: 'Profilo PRO')),                      );
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.calculate_outlined, color: Color(0xFF2DD4BF)),
                    title: const Text(
                      'Codice ATECO & Tasse',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'ATECO: ${walletProvider.codiceAteco} • Coeff: ${(walletProvider.coeffRedditivita * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () {
                      // Qui in futuro collegheremo il wizard di modifica profilo fiscale
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modifica profilo fiscale in arrivo!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ⚖️ SEZIONE LEGALE & GDPR
            const Text(
              'LEGALE & PRIVACY',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF2DD4BF)),
                    title: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
                    onTap: () => _apriLink(context, 'https://www.iubenda.com'), // Sostituiremo col link reale
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Color(0xFF2DD4BF)),
                    title: const Text(
                      'Termini e Condizioni di Servizio',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
                    onTap: () => _apriLink(context, 'https://www.iubenda.com'), // Sostituiremo col link reale
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 🚪 PULSANTE LOGOUT
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text(
                  'Esci dall\'account',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}