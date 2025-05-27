import 'package:flutter/material.dart';

import '../../config/constants.dart';

class RoofCatchmentView extends StatefulWidget {
  const RoofCatchmentView({super.key});

  @override
  State<RoofCatchmentView> createState() => _RoofCatchmentViewState();
}

class _RoofCatchmentViewState extends State<RoofCatchmentView> {
  @override
  Widget build(BuildContext context) {
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
    );
  }
}
