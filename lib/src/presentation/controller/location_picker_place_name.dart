part of 'location_picker_controller.dart';

mixin LocationPickerPlaceName on LocationPickerSearch {
  LatLng? selectedLocation;
  String? locationName;
  Timer? _placeNameTimer;
  int _placeNameToken = 0;
  Completer<void>? _placeNameDone;

  Future<void> selectedPlaceName(LatLng latLng) {
    final token = ++_placeNameToken;
    _placeNameTimer?.cancel();
    final previous = _placeNameDone;
    if (previous != null && !previous.isCompleted) {
      previous.complete();
    }
    final done = Completer<void>();
    _placeNameDone = done;
    _placeNameTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        if (token != _placeNameToken || _disposed) return;
        final address = await LocationPickerOsm.getPlaceName(
          latLng.latitude,
          latLng.longitude,
          languageCode: theme.placeLanguageCode,
          unknownLabel: theme.textOf(LocationPickerText.unknownPlace),
        );
        if (token != _placeNameToken || _disposed) return;
        locationName = address;
        searchController.text = address;
        _notify();
      } catch (error) {
        if (token != _placeNameToken || _disposed) return;
        debugPrint('Error in selectedPlaceName: $error');
        locationName = theme.textOf(LocationPickerText.unknownPlace);
        searchController.text = locationName!;
        _notify();
      } finally {
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
  }
}
