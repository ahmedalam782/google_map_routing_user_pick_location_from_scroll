part of 'location_picker_controller.dart';

mixin LocationPickerCurrentLocation on LocationPickerPlaceName {
  late String mapStyleString;
  bool isChangeStart = false;

  Future<void> getLocationMyCurrentLocation({
    LatLng? startLocation,
    LatLng? oldLocation,
    bool isStart = false,
    bool internal = false,
  }) async {
    try {
      mapState = MapState.loading;
      _notify();
      Future.delayed(const Duration(seconds: 5));
      final Position locationData = await locationService.getLocation();
      currentLocationLatLang = LatLng(
        locationData.latitude,
        locationData.longitude,
      );

      currentLocation =
          oldLocation ?? LatLng(locationData.latitude, locationData.longitude);
      var myCameraPosition = (!internal && !isStart)
          ? CameraPosition(target: oldLocation ?? currentLocation, zoom: 9)
          : CameraPosition(target: oldLocation ?? currentLocation, zoom: 17);
      if (!_disposed) {
        await googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            myCameraPosition,
          ),
        );
      } else {
        _report(LocationPickerText.pickerClosed);
        return;
      }
      updateCurrentLocationMarker();
      selectedLocation = currentLocation;
      selectedPlaceName(currentLocation);
      mapState = MapState.loaded;
      _notify();
    } on LocationServiceException catch (_) {
      mapState = MapState.error;
      _report(LocationPickerText.locationServiceDisabled);
    } on LocationPermissionException catch (_) {
      mapState = MapState.error;
      _report(LocationPickerText.locationPermissionDenied);
    } on PlatformException catch (e) {
      mapState = MapState.error;
      _report(
        LocationPickerText.locationFailed,
        detail: e.message ?? e.toString(),
      );
    } catch (e) {
      mapState = MapState.error;
      _report(LocationPickerText.unexpectedLocationError);
    }
  }

  Future<void> getMapStyle({
    required String mapStyle,
  }) async {
    mapStyleString = await rootBundle.loadString(mapStyle);
    // ignore: deprecated_member_use
    googleMapController!.setMapStyle(mapStyleString);
    _notify();
  }

  void activeChangeStart() {
    isChangeStart = true;
    _notify();
  }

  Future<void> updateStartLocation(LatLng latLng) async {
    isChangeStart = false;
    markers
        .removeWhere((marker) => marker.markerId.value == 'selectedLocation');
    markers.add(
      Marker(
        markerId: const MarkerId('selectedLocation'),
        position: latLng,
        icon:
            await theme.graphicOf(LocationPickerIconRole.startPin).toMapMarker(
                  iconColor: theme.colorOf(LocationPickerColorRole.icon),
                ),
      ),
    );
  }

  Future<void> updateCurrentLocationMarker() async {
    markers
        .removeWhere((marker) => marker.markerId.value == 'currentLocation');
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentLocationLatLang!,
        icon: await theme
            .graphicOf(LocationPickerIconRole.currentLocation)
            .toMapMarker(
              iconColor: theme.colorOf(LocationPickerColorRole.icon),
            ),
      ),
    );

    _notify();
  }
}
