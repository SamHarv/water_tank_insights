import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/constants.dart';
import 'disclaimer_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Button state for animation
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: mediaHeight * 0.3),
                  child: Hero(tag: "logo", child: Image.asset(logo)),
                ),
                Stack(
                  children: [
                    // Stroked text as border.
                    Text(
                      "Water Tank Insights",
                      style: GoogleFonts.openSans(
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Open Sans",
                          foreground:
                              Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 5
                                ..color = black,
                        ),
                      ),
                    ),
                    // Solid text as fill.
                    Text(
                      "Water Tank Insights",
                      style: GoogleFonts.openSans(
                        textStyle: const TextStyle(
                          fontFamily: "Open Sans",
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "When water is the new gold, we help protect yours.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Tooltip(
                  message: "Continue to next step",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 300),
                    child: InkWell(
                      borderRadius: kBorderRadius,
                      onTap: () {
                        // Handle button press animation
                        setState(() {
                          isPressed = true;
                        });
                        Future.delayed(const Duration(milliseconds: 150)).then((
                          value,
                        ) {
                          setState(() {
                            isPressed = false;
                          });
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DisclaimerView(),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        width: mediaWidth * 0.8,
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: white,
                          border: Border.all(color: black, width: 3),
                          borderRadius: kBorderRadius,
                          boxShadow: [isPressed ? BoxShadow() : kShadow],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text("Begin", style: subHeadingStyle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
