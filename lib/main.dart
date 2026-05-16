// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/app_controller.dart';
import 'services/firebase_auth_service.dart';
import 'services/session_service.dart';
import 'utils/app_router.dart';
import 'utils/app_constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Phase 1 : initialisation Firebase ────────────────────────────────────
// APRÈS
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialisation des services
  await SessionService.instance.init();
  await FirebaseAuthService
      .init(); // Restaure la session citoyen si elle existe

  runApp(const BudgetOuvertApp());
}

class BudgetOuvertApp extends StatelessWidget {
  const BudgetOuvertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SessionService>.value(value: SessionService.instance),
        ChangeNotifierProvider(create: (_) => AppController()),
      ],
      child: MaterialApp.router(
        title: 'BudgetOuvert',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: ThemeData(
          fontFamily: AppTextStyles.fontFamily,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}
