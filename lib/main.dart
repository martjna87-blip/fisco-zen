import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/1_setup_screen.dart';       // La vecchia schermata
import 'screens/1_onboarding_wizard.dart';
import 'screens/1_main_menu.dart';
import 'data/wallet_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 1. FORZA LA MODALITÀ EDGE-TO-EDGE SUL DISPOSITIVO
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 🎨 2. CONFIGURAZIONE BARRA DI STATO E NAVIGAZIONE 100% TRASPARENTI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Barra orologio/batteria trasparente
      statusBarIconBrightness: Brightness.light, // Icone bianche su Android
      statusBarBrightness: Brightness.dark, // iOS: scritte bianche (orologio/batteria)
      systemNavigationBarColor: Colors.transparent, // Barra gesti in basso trasparente
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const FiscoZenApp(),
    ),
  );
}

class FiscoZenApp extends StatelessWidget {
  const FiscoZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fisco Zen',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      locale: const Locale('it', 'IT'),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101012),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// 🚦 SMISTATORE AUTOMATICO ALL'AVVIO
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isCompleted = prefs.getBool('onboarding_completed') ?? false;
    final bool isPiva = prefs.getBool('isPartitaIVA') ?? true;

    if (!mounted) return;

    if (isCompleted) {
      // ✅ Questionario completato: va direttamente alla Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainMenu(hasPartitaIva: isPiva),
        ),
      );
    } else {
      // 🆕 Primo avvio: apre il Questionario
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingWizard(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080B0C),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2DD4BF)),
      ),
    );
  }
}