import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/1_setup_screen.dart';       // La vecchia schermata
import 'screens/1_onboarding_wizard.dart';  // Il nuovo questionario
import 'data/wallet_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      ),
      
      // 👈 Avviamo la nuova schermata importata da 1_onboarding_wizard.dart
      home: OnboardingWizard(), 
    );
  }
}