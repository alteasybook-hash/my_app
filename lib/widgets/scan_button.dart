import 'package:flutter/material.dart';
import '../screens/scan_screen.dart';

class ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScanScreen()),
        );
      },
      child: Icon(Icons.camera_alt),
    );
  }
}