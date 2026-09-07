import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/ludo_colors.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
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
