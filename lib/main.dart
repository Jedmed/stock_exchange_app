import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'config/development.dart';

void main() {
  // Enable hot reload for widgets
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with hot reload support
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SET Index Quotes',
      debugShowCheckedModeBanner: Development.showDebugBanner,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
