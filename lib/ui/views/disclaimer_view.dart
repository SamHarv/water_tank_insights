import 'package:flutter/material.dart';

import '../../config/constants.dart';
import 'location_view.dart';

class DisclaimerView extends StatefulWidget {
  const DisclaimerView({super.key});

  @override
  State<DisclaimerView> createState() => _DisclaimerViewState();
}

class _DisclaimerViewState extends State<DisclaimerView> {
  // Button state for animation
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leadingWidth: 120,
        leading: IconButton(
          icon: Padding(
            padding: kPadding,
            child: Icon(Icons.arrow_back_ios_new),
          ),
          color: white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Hero(
            tag: "logo",
            child: Padding(padding: kPadding, child: Image.asset(logo)),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: [
                // Disclaimer text
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Container(
                    width: mediaWidth * 0.8,
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: black, width: 3),
                      borderRadius: kBorderRadius,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          spacing: 24,
                          children: [
                            Text(
                              "Estimate how many days of water inventory you have "
                              "in your water tank based on current inventory, "
                              "predicted rainfall, and estimated water usage to "
                              "better manage your supply.",
                              style: subHeadingStyle,
                            ),
                            Text(
                              "This tool uses calculations to estinmate water "
                              "intake and usage, and may not reflect actual "
                              "intake and usage. Results should not be relied "
                              "upon for critical decisions without "
                              "professional advice. Data entered into this app "
                              "will be stored on your device and kept private.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Agree & Continue button
                Tooltip(
                  message: "Agree to disclaimer and continue",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
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
                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationView(),
                            ),
                          );
                        });
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
                            child: Text(
                              "Agree & Continue",
                              style: subHeadingStyle,
                            ),
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
