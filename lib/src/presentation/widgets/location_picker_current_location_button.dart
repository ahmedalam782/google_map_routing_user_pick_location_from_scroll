import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controller/location_picker_controller.dart';
import '../theme/location_picker_color.dart';
import '../theme/location_picker_icon.dart';
import '../theme/location_picker_theme.dart';
import 'location_picker_graphic_view.dart';

class LocationPickerCurrentLocationButton extends StatelessWidget {
  const LocationPickerCurrentLocationButton({
    super.key,
    required this.controller,
    required this.theme,
  });

  final LocationPickerController controller;
  final LocationPickerTheme theme;

  void _moveToCurrentLocation() {
    final target = controller.currentLocationLatLang;
    if (target == null) return;
    controller.googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
    );
    controller.updateCurrentLocationMarker();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        side: BorderSide(color: Colors.transparent),
      ),
      elevation: 1,
      backgroundColor: theme.colorOf(LocationPickerColorRole.fabBackground),
      onPressed: _moveToCurrentLocation,
      child: SizedBox(
        height: 46,
        width: 46,
        child: LocationPickerGraphicView(
          graphic: theme.graphicOf(LocationPickerIconRole.currentLocationButton),
          iconColor: theme.colorOf(LocationPickerColorRole.icon),
          size: 24,
        ),
      ),
    );
  }
}
