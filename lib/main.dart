import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/constants.dart';
import 'ui/views/home_view.dart';

//TODO: download csv/ presist data locally?

void main() {
  runApp(const WaterTankInsights());
}

class WaterTankInsights extends StatelessWidget {
  const WaterTankInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Tank Insights',
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
