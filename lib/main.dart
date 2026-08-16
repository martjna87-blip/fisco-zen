import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/1_setup_screen.dart';       // La vecchia schermata
import 'screens/1_onboarding_wizard.dart';
import 'screens/1_main_menu.dart';
import 'data/wallet_provider.dart';
import 'data/notifications_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'data/ateco_database.dart';
import 'data/ateco_uploader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👇 AGGIUNGI QUESTA RIGA TEMPORANEA per caricare la lista su FireBase:
  // await AtecoUploader.caricaTuttoSuFirebase();

  await AtecoDatabase.sincronizzaCodiciDaFirebase();
  
  // 🛡️ ATTIVAZIONE CRASHLYTICS (Solo su dispositivi mobili iOS/Android)
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: const FiscOnApp(),
    ),
  );
}

class FiscOnApp extends StatelessWidget {
  const FiscOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, child) {
        return MaterialApp(
          title: 'FiscON',
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
          builder: (context, childWidget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(wallet.textScaleFactor),
              ),
              child: childWidget!,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFlow();
  }

  Future<void> _checkFlow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final bool isCompleted = prefs.getBool('onboarding_completed') ?? false;
    final bool isPiva = prefs.getBool('isPartitaIVA') ?? true;

    if (!mounted) return;

    if (!authProvider.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
      );
    } else if (isCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainMenu(hasPartitaIva: isPiva),
        ),
      );
    } else {
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