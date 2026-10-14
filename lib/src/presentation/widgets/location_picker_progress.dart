import 'package:flutter/material.dart';

class LocationPickerProgress extends StatelessWidget {
  const LocationPickerProgress({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: color));
  }
}
