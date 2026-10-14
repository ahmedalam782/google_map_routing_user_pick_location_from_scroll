import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/core/error/failure.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/data/services/location_service.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/domain/models/geometry/geometry.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/domain/models/place_details_model/place_details_model.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/domain/models/places_model/prediction.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/domain/repositories/google_map_repo.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/presentation/theme/location_picker_color.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/presentation/theme/location_picker_icon.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/presentation/theme/location_picker_text.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/presentation/theme/location_picker_theme.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';
import 'package:uuid/uuid.dart';

import 'location_picker_notice.dart';
import 'location_picker_osm.dart';
import 'map_state.dart';

export 'map_state.dart';

part 'location_picker_current_location.dart';
part 'location_picker_governorate.dart';
part 'location_picker_place_name.dart';
part 'location_picker_search.dart';

/// Shared picker state used by the named controller mixins.
abstract class LocationPickerControllerBase extends ChangeNotifier {
  LocationPickerControllerBase({
    required this.googleMapRepoImpl,
    required this.locationService,
    required this.theme,
  });

  LocationPickerTheme theme;
  final GoogleMapRepo googleMapRepoImpl;
  final LocationService locationService;

  GoogleMapController? googleMapController;
  final FocusNode searchFocusNode = FocusNode();
  CameraPosition cameraPosition = const CameraPosition(
    target: LatLng(0.0, 0.0),
    bearing: 0.0,
    tilt: 0.0,
    zoom: 0,
  );

  Set<Marker> markers = {};
  Set<Polyline> polyLines = {};
  late LatLng currentLocation;
  LatLng? currentLocationLatLang;
  LatLng? carLocation;
  MapState mapState = MapState.initial;

  LocationPickerNotice? notice;
  int _noticeId = 0;
  bool _disposed = false;

  Color get primaryColor => theme.colorOf(LocationPickerColorRole.primary);

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _report(LocationPickerText text, {String? detail}) {
    if (_disposed) return;
    notice = LocationPickerNotice(id: ++_noticeId, text: text, detail: detail);
    notifyListeners();
  }

  void _reportRaw(String message) {
    if (_disposed) return;
    notice = LocationPickerNotice(id: ++_noticeId, rawMessage: message);
    notifyListeners();
  }

  String _messageOf(Exception? exception) {
    if (exception is Failure) return exception.message;
    return exception?.toString() ?? '';
  }
}

/// Screen state for the location picker.
///
/// The package owns this controller. A host app can pass one in when it needs
/// to move the camera or clear search, and it does not need a state-management
/// package to do that.
@injectable
class LocationPickerController extends LocationPickerControllerBase
    with
        LocationPickerGovernorate,
        LocationPickerSearch,
        LocationPickerPlaceName,
        LocationPickerCurrentLocation {
  LocationPickerController(
    GoogleMapRepo googleMapRepoImpl,
    LocationService locationService, {
    @factoryParam LocationPickerTheme? theme,
  }) : super(
          googleMapRepoImpl: googleMapRepoImpl,
          locationService: locationService,
          theme: theme ?? const LocationPickerTheme(),
        );

  void applyTheme(LocationPickerTheme value) {
    if (theme == value) return;
    theme = value;
    _recolorPolygons();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _placeNameTimer?.cancel();
    _searchDebounce?.cancel();
    searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
  }
}
