// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:water_tank_insights/data/postcodes.dart';
import 'package:water_tank_insights/logic/services/postcode_service.dart';
import 'package:water_tank_insights/logic/services/supabase_service.dart';
import 'package:water_tank_insights/ui/views/api_demo.dart';

import 'config/constants.dart';
import 'ui/views/home_view.dart';

// flutter run -d chrome --web-experimental-hot-reload

/// [main] function is entry point of the app
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const WaterTankInsights());
}

class WaterTankInsights extends StatelessWidget {
  const WaterTankInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      theme: ThemeData(
        fontFamily: GoogleFonts.openSans().fontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: blue, secondary: black),
        textTheme: GoogleFonts.openSansTextTheme().apply(
          bodyColor: black,
          displayColor: black,
        ),
        scaffoldBackgroundColor: blue,
        appBarTheme: AppBarTheme(
          color: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: black),
        ),
      ),
      home: const HomeView(),
    );
  }
}
