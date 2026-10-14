import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

import '../controller/location_picker_controller.dart';
import '../theme/location_picker_text.dart';
import 'location_picker_toast.dart';

class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({
    super.key,
    required this.controller,
    required this.mapStyle,
    required this.internal,
    this.isStart = true,
    this.startLocation,
    this.oldLocation,
  });

  final LocationPickerController controller;
  final String? mapStyle;
  final bool internal;
  final bool isStart;
  final LatLng? startLocation;
  final LatLng? oldLocation;

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  LatLng _location = const LatLng(35.27088501447092, 46.055900529026985);

  void _onCameraIdle() {
    final controller = widget.controller;
    controller.selectedLocation = _location;
    if (!MdUserPickLocationGoogleMapConfig.current.searchGovernorate) {
      controller.selectedPlaceName(_location);
      return;
    }
    if (widget.internal) {
      if (controller.regionModel == null) return;
      if (controller.chackInternalOrNot(_location)) {
        controller.selectedPlaceName(_location);
      } else {
        LocationPickerToast.showText(
          context,
          controller.theme,
          LocationPickerText.insideBoundary,
        );
      }
      return;
    }
    if (widget.isStart) {
      controller.selectedPlaceName(_location);
      return;
    }
    if (controller.regionModel == null) return;
    if (controller.chackInternalOrNot(_location)) {
      LocationPickerToast.showText(
        context,
        controller.theme,
        LocationPickerText.outsideBoundary,
      );
      return;
    }
    controller.selectedPlaceName(_location);
  }

  Future<void> _onMapCreated(GoogleMapController mapController) async {
    final controller = widget.controller;
    controller.googleMapController = mapController;
    final mapStyle = widget.mapStyle;
    if (mapStyle != null) {
      await controller.getMapStyle(mapStyle: mapStyle);
    }
    await controller.getLocationMyCurrentLocation(
      startLocation: widget.startLocation,
      isStart: widget.isStart,
      internal: widget.internal,
      oldLocation: widget.oldLocation,
    );
    if (MdUserPickLocationGoogleMapConfig.current.searchGovernorate &&
        controller.regionModel == null) {
      await controller.getGovernorates(
        startLocation: widget.startLocation,
        internal: widget.internal,
        isStart: widget.isStart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GoogleMap(
      markers: controller.markers,
      polylines: controller.polyLines,
      polygons: controller.polygon,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      rotateGesturesEnabled: false,
      compassEnabled: false,
      initialCameraPosition: controller.cameraPosition,
      myLocationEnabled: false,
      onCameraMove: (position) {
        setState(() {
          _location = position.target;
        });
      },
      onCameraIdle: _onCameraIdle,
      onMapCreated: _onMapCreated,
    );
  }
}
