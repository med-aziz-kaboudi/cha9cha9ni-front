import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'core/services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load saved language
  await LanguageService().loadLanguage();
  
  runApp(const Cha9cha9niApp());
}

class Cha9cha9niApp extends StatelessWidget {
  const Cha9cha9niApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();
    
    return ValueListenableBuilder<Locale>(
      valueListenable: languageService.currentLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Cha9cha9ni',
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('fr'),
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          builder: (context, child) {
            // Force RTL for Arabic
            return Directionality(
              textDirection: locale.languageCode == 'ar' 
                  ? TextDirection.rtl 
                  : TextDirection.ltr,
              child: child!,
            );
          },
          home: const AppEntry(),
        );
      },
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _showSplash = true;

  void _onSplashFinished() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onFinished: _onSplashFinished);
    }
    return const OnboardingScreen();
  }
}
