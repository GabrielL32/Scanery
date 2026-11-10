import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/services/storage_service.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StorageService()),
      ],
      child: const ScaneryApp(),
    ),
  );
}

class ScaneryApp extends StatelessWidget {
  const ScaneryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Scanery',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme(null, themeProvider.seedColor),
      darkTheme: AppTheme.darkTheme(null, themeProvider.seedColor),
      home: const HomeScreen(),
    );
  }
}
