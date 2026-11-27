import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/ludo_colors.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/deep_link_service.dart';
import 'services/sound_haptic_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase.initializeApp note: $e");
  }
  await SoundHapticService.init();
  await DeepLinkService.instance.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const LudoApp());
}

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: DeepLinkService.navigatorKey,
      title: 'Ludo Supreme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: LudoColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          surface: LudoColors.surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: LudoColors.surfaceDark,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
