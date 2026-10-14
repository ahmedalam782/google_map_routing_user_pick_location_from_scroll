import 'package:flutter/material.dart';

import '../controller/location_picker_controller.dart';
import 'location_picker_place_tile.dart';

class LocationPickerPlacesList extends StatelessWidget {
  const LocationPickerPlacesList({
    super.key,
    required this.controller,
    required this.internal,
    required this.isStart,
  });

  final LocationPickerController controller;
  final bool internal;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final predictions = controller.predictions;
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            return LocationPickerPlaceTile(
              controller: controller,
              theme: controller.theme,
              prediction: predictions[index],
              internal: internal,
              isStart: isStart,
            );
          },
        );
      },
    );
  }
}
