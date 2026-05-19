import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sannybunnies/services/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sannybunnies/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  await initializeDateFormatting('ru', null);

  
  try {
    await Firebase.initializeApp();
    print('Firebase initialized');
  } catch (e, st) {
    print('Firebase init failed: $e\n$st');
  }
  
  
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    print('FlutterError.onError: ${details.exception}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    print('PlatformDispatcher.onError: $error\n$stack');
    return true;
  };
  
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('seen_preview') ?? false;
  runApp(MyApp(seenPreview: seen));
}

class MyApp extends StatelessWidget {
  final bool seenPreview;
  const MyApp({Key? key, required this.seenPreview}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFF131010),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
      ),
      home: AuthWrapper(seenPreview: seenPreview),
      debugShowCheckedModeBanner: false,
    );
  }
}

