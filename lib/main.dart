import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/neon_theme.dart';
import 'auth/auth_screen.dart';
import 'home/home_screen.dart';
import 'core/models/app_user.dart';
import 'core/services/local_auth_service.dart';
import 'core/services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<LocalAuthService>(create: (_) => LocalAuthService()),
        Provider<LocalStorageService>(create: (_) => LocalStorageService()),
      ],
      child: const SplitSmartApp(),
    ),
  );
}

class SplitSmartApp extends StatelessWidget {
  const SplitSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitSmart',
      theme: NeonTheme.themeData,
      themeMode: ThemeMode.dark, // Force dark mode for Neon Protocol
      home: StreamBuilder<AppUser?>(
        stream: context.read<LocalAuthService>().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
