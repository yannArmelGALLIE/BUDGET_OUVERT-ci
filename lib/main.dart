// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/app_controller.dart';
import 'services/audio_service.dart';
import 'services/session_service.dart';
import 'services/api_service.dart';
import 'utils/app_constants.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // ── Initialisation des services ──────────────────────────────────
  // 1. Persistance session (doit être avant runApp pour lire isLoggedIn)
  await SessionService.instance.init();

  // 2. Audio
  AudioService.instance.init();

  // 3. Injecter le token API sauvegardé si session active
  final savedToken = SessionService.instance.authToken;
  if (savedToken != null) {
    ApiService.instance.setToken(savedToken);
  }

  runApp(const BudgetOuvertApp());
}

class BudgetOuvertApp extends StatelessWidget {
  const BudgetOuvertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AppController initialisé avec la session persistée
        ChangeNotifierProvider(
          create: (_) => AppController()..restoreSession(),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CommuneController()),
        ChangeNotifierProvider(create: (_) => SignalController()),
        // ScanController initialisé avec l'historique persisté
        ChangeNotifierProvider(
          create: (_) => ScanController()..restoreHistory(),
        ),
      ],
      child: MaterialApp.router(
        title: 'BudgetOuvert',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: ThemeData(
          fontFamily: AppTextStyles.fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              borderSide: BorderSide.none,
            ),
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}
