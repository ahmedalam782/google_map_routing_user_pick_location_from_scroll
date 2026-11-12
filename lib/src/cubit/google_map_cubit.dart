import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:mdsoft_google_map_user_pick_location_from_scroll/google_map_routing.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/api/dio_client.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/models/geometry/geometry.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/models/place_details_model/place_details_model.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/models/places_model/prediction.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/repositories/google_map_repo.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/utils/extension.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
part 'google_map_state.dart';

class GoogleMapCubit extends Cubit<GoogleMapState> {
  GoogleMapCubit() : super(GoogleMapInitial());
  GoogleMapController? googleMapController;
  GoogleMapRepo googleMapRepoImpl =
      GoogleMapRepoImpl(dioClient: DioClient(Dio()));
  LocationService locationService = LocationService();
  FocusNode searchFocusNode = FocusNode();
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

  @override
  Future<void> emit(GoogleMapState state) async {
    if (!isClosed) {
      return super.emit(state);
    }
  }

  @override
  Future<void> close() {
    _placeNameTimer?.cancel();
    _placeNameCancelToken?.cancel();
    _searchDebounceTimer?.cancel();
    _predictionsCancelToken?.cancel();
    searchFocusNode.dispose();
    searchController.dispose();
    return super.close();
  }

  static LatLng? _lastKnownLocation;

//? getLocation
  Future<void> getLocationMyCurrentLocation(
      {LatLng? startLocation,
      LatLng? oldLocation,
      bool isStart = false,
      bool internal = false}) async {
    try {
      final immediateTarget =
          oldLocation ?? startLocation ?? _lastKnownLocation;
      if (immediateTarget != null) {
        currentLocation = oldLocation ?? immediateTarget;
        currentLocationLatLang ??= _lastKnownLocation ?? immediateTarget;
        selectedLocation = currentLocation;
        final initialCam = (!internal && !isStart)
            ? CameraPosition(target: currentLocation, zoom: 9)
            : CameraPosition(target: currentLocation, zoom: 17);
        googleMapController?.moveCamera(
          CameraUpdate.newCameraPosition(initialCam),
        );
        selectedPlaceName(currentLocation, debounce: Duration.zero);
        mapState = MapState.loaded;
        emit(GetLocationSuccessState());

        // Refresh actual GPS in background if oldLocation wasn't explicitly set
        locationService.getLocation().then((locationData) {
          final gps = LatLng(locationData.latitude, locationData.longitude);
          _lastKnownLocation = gps;
          currentLocationLatLang = gps;
          if (!isClosed) {
            updateCurrentLocationMarker();
          }
        }).catchError((_) {});
        return;
      }

      mapState = MapState.loading;
      emit(GetCurrentLocationLoadingState());
      final LocationData locationData = await locationService.getLocation();
      final gps = LatLng(
        locationData.latitude,
        locationData.longitude,
      );
      _lastKnownLocation = gps;
      currentLocationLatLang = gps;

      currentLocation = oldLocation ?? gps;
      var myCameraPosition = (!internal && !isStart)
          ? CameraPosition(target: oldLocation ?? currentLocation, zoom: 9)
          : CameraPosition(target: oldLocation ?? currentLocation, zoom: 17);
      // Check if cubit is closed before animating camera
      if (!isClosed) {
        googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            myCameraPosition,
          ),
        );
      } else {
        emit(GetLocationErrorState(errorMessage: 'حدث خطأ غير متوقع'));
        return;
      }
      updateCurrentLocationMarker();
      selectedLocation = currentLocation;
      selectedPlaceName(currentLocation, debounce: Duration.zero);
      mapState = MapState.loaded;
      emit(GetLocationSuccessState());
    } on LocationServiceException catch (_) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'يرجى التأكد من تفعيل خدمة الموقع'));
    } on LocationPermissionException catch (_) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'يرجى التأكد من السماح بالوصول إلى الموقع'));
    } on PlatformException catch (_) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'فشل في تحديد الموقع، يرجى المحاولة مرة أخرى'));
    } catch (e) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'حدث خطأ غير متوقع أثناء تحديد الموقع'));
    }
  }

//? getMapStyle
  late String mapStyleString;
  Color primaryColor = MdUserPickLocationGoogleMapConfig.primaryColor!;
  Future<void> getMapStyle(
      {required String mapStyle, Color? primaryColor}) async {
    mapStyleString = await rootBundle.loadString(mapStyle);
    this.primaryColor = primaryColor ?? this.primaryColor;
    // ignore: deprecated_member_use
    googleMapController!.setMapStyle(mapStyleString);
    emit(GetMapStyleSuccessState());
  }

  ///? change is change value
  bool isChangeStart = false;
  void activeChangeStart() {
    isChangeStart = true;
    emit(ChangeStartState());
  }

  Future<void> updateStartLocation(LatLng latLng) async {
    isChangeStart = false;
    markers
        .removeWhere((marker) => marker.markerId.value == 'selectedLocation');
    markers.add(
      Marker(
        markerId: const MarkerId('selectedLocation'),
        position: latLng,
        icon: await AppImages.point.toBitmapDescriptor(devicePixelRatio: 2.5),
      ),
    );
  }

  static final Map<String, String> _osmCache = {};
  static final Dio _osmDio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      headers: const {
        'Accept': 'application/json',
        'Accept-Language': 'ar',
      },
    ),
  );
  static Future<void> _osmChain = Future<void>.value();
  static DateTime _osmNextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  /// Nominatim allows one request per second. Queue calls so scrolling
  /// the map does not get blocked with HTTP 429.
  static Future<T> _runOsmSlot<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _osmChain = _osmChain.catchError((_) {}).then((_) async {
      final wait = _osmNextSlot.difference(DateTime.now());
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
      _osmNextSlot = DateTime.now().add(const Duration(seconds: 1));
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  static Future<String> getPlaceNameOSM(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final cached = _osmCache[key];
    if (cached != null && cached.isNotEmpty) return cached;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final address = await _runOsmSlot(() => _reverseGeocodeOsm(lat, lng));
        if (address != null && address.isNotEmpty) {
          _osmCache[key] = address;
          return address;
        }
        return 'Unknown';
      } catch (e) {
        debugPrint('OSM request failed: $e');
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    return 'Unknown';
  }

  static Future<String?> _reverseGeocodeOsm(double lat, double lng) async {
    final userAgent = MdUserPickLocationGoogleMapConfig.userAgent.trim();
    final response = await _osmDio.get<dynamic>(
      '/reverse',
      queryParameters: <String, dynamic>{
        'lat': lat,
        'lon': lng,
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'ar',
      },
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent': userAgent.isEmpty
              ? 'MdSoftGoogleMapUserPickLocationFromScroll/1.0 (info@mdsoft.com)'
              : userAgent,
        },
      ),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'OSM reverse geocode failed (${response.statusCode})',
      );
    }
    return _addressFromOsm(response.data);
  }

  static String? _addressFromOsm(dynamic data) {
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    if (map == null || map['error'] != null) return null;

    final rawAddress = map['address'];
    if (rawAddress is Map) {
      final address = Map<String, dynamic>.from(rawAddress);
      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      final parts = <String?>[
        pick(const ['state', 'province', 'region']),
        pick(const ['city', 'town', 'village', 'municipality']),
        pick(const ['city_district', 'suburb', 'quarter', 'neighbourhood']),
        pick(const ['road', 'pedestrian', 'street']),
      ].whereType<String>().toList();

      final unique = <String>[];
      for (final part in parts) {
        if (!unique.contains(part)) unique.add(part);
      }
      if (unique.isNotEmpty) return unique.join(' - ');
    }

    final display = map['display_name'];
    if (display is String && display.trim().isNotEmpty) return display.trim();
    return null;
  }

  static final Map<String, PlaceNameResult> _placeNameCache = {};

  /// Approximate boundary polygon of Iraq (lat, lng).
  static const List<mp.LatLng> _iraqBoundary = [
    mp.LatLng(37.38, 42.35),
    mp.LatLng(37.15, 44.80),
    mp.LatLng(35.80, 46.20),
    mp.LatLng(33.50, 46.15),
    mp.LatLng(31.00, 47.80),
    mp.LatLng(29.95, 48.60),
    mp.LatLng(29.06, 46.55),
    mp.LatLng(31.90, 39.00),
    mp.LatLng(32.30, 38.79),
    mp.LatLng(33.37, 38.80),
    mp.LatLng(34.40, 41.20),
    mp.LatLng(36.90, 41.30),
  ];

  /// Instant offline check whether [latLng] is inside Iraq (or inside the loaded governorate polygon).
  bool isPointInIraqSync(LatLng latLng) {
    if (regionModel != null && chackInternalOrNot(latLng)) {
      return true;
    }
    return mp.PolygonUtil.containsLocation(
      mp.LatLng(latLng.latitude, latLng.longitude),
      _iraqBoundary,
      true,
    );
  }

  /// Whether the selected point is in Iraq; null while it is still unknown.
  bool? isInIraq;
  bool isResolvingPlaceName = false;
  CancelToken? _placeNameCancelToken;

  /// Google title (cached per ~11 m cell), falling back to OSM.
  Future<PlaceNameResult> _placeName(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) async {
    final cell = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final cached = _placeNameCache[cell];
    if (cached != null) return cached;
    final result = await googleMapRepoImpl.getPlaceName(
      lat: lat,
      lng: lng,
      cancelToken: cancelToken,
    );
    final found = result.fold<PlaceNameResult?>((_) => null, (r) => r);
    if (found != null) {
      _placeNameCache[cell] = found; // never cache failures
      return found;
    }
    if (cancelToken?.isCancelled ?? false) {
      throw DioException.requestCancelled(
        requestOptions: RequestOptions(path: ''),
        reason: 'cancelled',
      );
    }
    return (name: await getPlaceNameOSM(lat, lng), countryCode: null);
  }

  LatLng? selectedLocation;
  String? locationName;
  Timer? _placeNameTimer;
  int _placeNameToken = 0;
  Completer<void>? _placeNameDone;

  Future<void> selectedPlaceName(
    LatLng latLng, {
    Duration debounce = const Duration(milliseconds: 120),
  }) {
    final token = ++_placeNameToken;
    selectedLocation = latLng;
    isInIraq = isPointInIraqSync(latLng);
    _placeNameTimer?.cancel();
    _placeNameCancelToken?.cancel();
    final previous = _placeNameDone;
    if (previous != null && !previous.isCompleted) {
      previous.complete();
    }
    final done = Completer<void>();
    _placeNameDone = done;

    final cell =
        '${latLng.latitude.toStringAsFixed(4)},${latLng.longitude.toStringAsFixed(4)}';
    final cached = _placeNameCache[cell];
    if (cached != null) {
      locationName = cached.name;
      isInIraq = cached.countryCode == null
          ? isPointInIraqSync(latLng)
          : cached.countryCode == 'IQ';
      isResolvingPlaceName = false;
      if (!searchFocusNode.hasFocus) {
        searchController.text = cached.name;
      }
      emit(SelectedLocationNameState());
      if (isInIraq == false) emit(OutsideIraqState());
      done.complete();
      return done.future;
    }

    isResolvingPlaceName = true;
    // Drop the previous address so the field shows the loading title instead
    // of a stale name while the new one is looked up.
    if (!searchFocusNode.hasFocus) searchController.clear();
    emit(ResolvingLocationNameState());

    Future<void> runLookup() async {
      final cancelToken = CancelToken();
      _placeNameCancelToken = cancelToken;
      try {
        if (token != _placeNameToken || isClosed) return;
        final place = await _placeName(
          latLng.latitude,
          latLng.longitude,
          cancelToken: cancelToken,
        );
        if (token != _placeNameToken || isClosed) return;
        locationName = place.name;
        isInIraq = place.countryCode == null
            ? isPointInIraqSync(latLng)
            : place.countryCode == 'IQ';
        isResolvingPlaceName = false;
        if (!searchFocusNode.hasFocus) {
          searchController.text = place.name;
        }
        emit(SelectedLocationNameState());
        if (isInIraq == false) emit(OutsideIraqState());
      } catch (error) {
        if (token != _placeNameToken || isClosed) return;
        debugPrint('Error in selectedPlaceName: $error');
        locationName = locationName?.isNotEmpty == true
            ? locationName
            : 'موقع على الخريطة';
        isInIraq = isPointInIraqSync(latLng);
        isResolvingPlaceName = false;
        if (!searchFocusNode.hasFocus) {
          searchController.text = locationName!;
        }
        emit(SelectedLocationNameState());
      } finally {
        if (token == _placeNameToken) {
          isResolvingPlaceName = false;
        }
        if (!done.isCompleted) done.complete();
      }
    }

    if (debounce == Duration.zero) {
      runLookup();
    } else {
      _placeNameTimer = Timer(debounce, runLookup);
    }
    return done.future;
  }

  /// Ensures the current [selectedLocation] has a resolved name (used if the
  /// user taps confirm immediately while a lookup is still in flight).
  Future<void> ensurePlaceResolved() async {
    final loc = selectedLocation;
    if (loc == null) return;
    isInIraq ??= isPointInIraqSync(loc);
    if (!isResolvingPlaceName &&
        locationName != null &&
        locationName!.trim().isNotEmpty) {
      return;
    }
    _placeNameTimer?.cancel();
    await selectedPlaceName(loc, debounce: Duration.zero);
  }

  //? updateCurrentLocationMarker
  Future<void> updateCurrentLocationMarker() async {
    markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentLocationLatLang!,
        icon: await AppImages.currentLocation
            .toBitmapDescriptor(devicePixelRatio: 2.5),
      ),
    );

    emit(SetMarkersSuccessState());
  }

  void clear({bool keepText = false}) {
    _predictionsCancelToken?.cancel();
    _searchDebounceTimer?.cancel();
    if (!keepText) {
      searchController.clear();
    }
    predictions = [];
    isLoadingPredictions = false;
    sessionToken = null;
    emit(ClearState());
  }

//? getPredictions
  Uuid uuid = const Uuid();
  String? sessionToken;
  List<Prediction> predictions = [];
  bool isLoadingPredictions = false;
  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  CancelToken? _predictionsCancelToken;
  static final Map<String, List<Prediction>> _predictionsCache = {};
  int _predictionsToken = 0;

  void onSearchChanged(String? query) {
    _searchDebounceTimer?.cancel();
    final trimmed = query?.trim() ?? '';
    if (trimmed.isEmpty) {
      _predictionsCancelToken?.cancel();
      predictions = [];
      isLoadingPredictions = false;
      emit(ClearState());
      return;
    }
    final cached = _predictionsCache[trimmed];
    if (cached != null) {
      _predictionsCancelToken?.cancel();
      predictions = cached;
      isLoadingPredictions = false;
      emit(GetPredictionsSuccessState());
      return;
    }
    _searchDebounceTimer = Timer(
      const Duration(milliseconds: 220),
      getPredictions,
    );
  }

  Future<void> getPredictions() async {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      predictions = [];
      isLoadingPredictions = false;
      emit(GetPredictionsSuccessState());
      return;
    }
    final cached = _predictionsCache[query];
    if (cached != null) {
      predictions = cached;
      isLoadingPredictions = false;
      emit(GetPredictionsSuccessState());
      return;
    }
    final token = ++_predictionsToken;
    _predictionsCancelToken?.cancel();
    final cancelToken = CancelToken();
    _predictionsCancelToken = cancelToken;

    sessionToken ??= uuid.v4();
    isLoadingPredictions = true;
    emit(GetPredictionsLoadingState());
    final bias = selectedLocation ?? currentLocationLatLang;
    final result = await googleMapRepoImpl.getPredictions(
      input: query,
      sessionToken: sessionToken!,
      locationBias: bias,
      cancelToken: cancelToken,
    );
    if (token != _predictionsToken || isClosed) return;
    isLoadingPredictions = false;
    result.fold(
      (l) {
        if (l.message != 'cancelled') {
          emit(GetPredictionsErrorState(errorMessage: l.message));
        }
      },
      (r) {
        predictions = r.predictions ?? [];
        if (predictions.isNotEmpty) {
          _predictionsCache[query] = predictions;
        }
        emit(GetPredictionsSuccessState());
      },
    );
  }

//? getPlaceDetails
  late LatLng placeDetailsLocation;
  List<LatLng> placeDetailsLocationList = [];
  int editIndex = 0;
  bool isEditPlace = false;
  void setEditIndex(int index) {
    editIndex = index;
    isEditPlace = true;
    emit(SetEditIndexSuccessState());
  }

  bool isNextCameraIdleFromSearch = false;

  Future<void> getPlaceDetails({
    required String placeId,
    String? fallbackTitle,
    bool internal = false,
    bool isStart = false,
  }) async {
    predictions = [];
    isLoadingPredictions = false;
    if (fallbackTitle != null && fallbackTitle.trim().isNotEmpty) {
      searchController.text = fallbackTitle.trim();
    }
    emit(ClearState());

    final result = await googleMapRepoImpl.getPlaceDetails(
        placeId: placeId, sessionToken: sessionToken);
    sessionToken = null;
    result.fold((l) {
      emit(GetPlaceDetailsErrorState(errorMessage: l.message));
    }, (r) async {
      final targetLatLng = LatLng(
        r.result!.geometry!.location!.lat!,
        r.result!.geometry!.location!.lng!,
      );
      if (isStart && !internal) {
        _onSearchAdd(r, fallbackTitle: fallbackTitle);
        emit(GetPlaceDetailsSuccessState());
        return;
      }
      if (internal) {
        if (regionModel != null) {
          bool inside = chackInternalOrNot(targetLatLng);
          if (!inside) {
            emit(GetPlaceDetailsErrorState(
                errorMessage:
                    'يرجى اختيار موقع داخل الحدود المحددة، حيث أن هذه رحلة داخلية'));
            return;
          }
        }
        _onSearchAdd(r, fallbackTitle: fallbackTitle);
      } else {
        if (regionModel != null) {
          bool inside = chackInternalOrNot(targetLatLng);
          if (inside) {
            emit(GetPlaceDetailsErrorState(
                errorMessage:
                    'يرجى اختيار موقع خارج الحدود المحددة، حيث أن هذه رحلة خارجية'));
            return;
          }
        }
        _onSearchAdd(r, fallbackTitle: fallbackTitle);
      }
      emit(GetPlaceDetailsSuccessState());
    });
  }

  bool chackInternalOrNot(LatLng r) {
    if (regionModel == null) {
      debugPrint('chackInternalOrNot: regionModel is null');
      return false;
    }

    bool isPointInPolygon(mp.LatLng point, List<mp.LatLng> polygon) {
      return mp.PolygonUtil.containsLocation(point, polygon, true);
    }

    mp.LatLng userPoint = mp.LatLng(r.latitude, r.longitude);

    try {
      bool inside = isPointInPolygon(
          userPoint,
          convertToGoogleLatLng(
            regionModel!.geometry.coordinates[0]
                .map((e) => LatLng(e[1], e[0]))
                .toList(),
          ));
      return inside;
    } catch (e) {
      debugPrint('Error in chackInternalOrNot: $e');
      return false;
    }
  }

  void _onSearchAdd(PlaceDetailsModel r, {String? fallbackTitle}) async {
    placeDetailsLocation = LatLng(
        r.result!.geometry!.location!.lat!, r.result!.geometry!.location!.lng!);

    final title = (r.result?.name?.trim().isNotEmpty == true
            ? r.result!.name!.trim()
            : null) ??
        (r.result?.formattedAddress?.trim().isNotEmpty == true
            ? r.result!.formattedAddress!.trim()
            : null) ??
        fallbackTitle?.trim();

    _placeNameTimer?.cancel();
    _placeNameCancelToken?.cancel();
    _placeNameToken++;
    selectedLocation = placeDetailsLocation;
    isInIraq = true;
    isResolvingPlaceName = false;
    if (title != null && title.isNotEmpty) {
      locationName = title;
      searchController.text = title;
      final cell =
          '${placeDetailsLocation.latitude.toStringAsFixed(4)},${placeDetailsLocation.longitude.toStringAsFixed(4)}';
      _placeNameCache[cell] = (name: title, countryCode: 'IQ');
    }

    markers.removeWhere((marker) => marker.markerId.value == 'searchedPlace');
    if (title != null && title.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('searchedPlace'),
          position: placeDetailsLocation,
          infoWindow: InfoWindow(title: title),
          alpha: 0.9,
        ),
      );
    }

    isNextCameraIdleFromSearch = true;
    // Not awaited: on web the animation future can stall and block the zoom.
    googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: placeDetailsLocation, zoom: 16),
      ),
    );
    clear(keepText: true); // also emits, rebuilding the map with the new marker
    emit(SelectedLocationNameState());
    if (title != null && title.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      try {
        await googleMapController
            ?.showMarkerInfoWindow(const MarkerId('searchedPlace'));
      } catch (e) {
        debugPrint('showMarkerInfoWindow failed: $e');
      }
    }
  }

  RegionModel? regionModel;
  static RegionModel? _cachedRegionModel;
  static LatLng? _cachedRegionLocation;
  Set<Polygon> polygon = {};
  //? get governorates
  MapState mapState = MapState.initial;

  void _applyRegionPolygon(
    RegionModel r, {
    required bool internal,
    required bool isStart,
  }) {
    regionModel = r;
    polygon.clear();
    if (internal) {
      final Polygon poly = Polygon(
        polygonId: PolygonId('${r.polygonId}_inverse'),
        points: const // Outer boundary covering Iraq region
            [
          LatLng(37.5, 38.5), // Top-left (Northwest)
          LatLng(37.5, 48.6), // Top-right (Northeast)
          LatLng(29.0, 48.6), // Bottom-right (Southeast)
          LatLng(29.0, 38.5), // Bottom-left (Southwest)
          LatLng(37.5, 38.5) // Close the polygon
        ],
        holes: [
          r.geometry.coordinates[0].map((e) => LatLng(e[1], e[0])).toList(),
        ],
        strokeWidth: 2,
        strokeColor: Colors.red,
        fillColor: Colors.red.withValues(alpha: 0.15), // Outside red
      );
      polygon.add(poly);
    } else {
      if (!isStart) {
        final Polygon poly = Polygon(
          polygonId: PolygonId(r.polygonId),
          points:
              r.geometry.coordinates[0].map((e) => LatLng(e[1], e[0])).toList(),
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withValues(alpha: 0.15),
        );
        polygon.add(poly);
      }
    }
  }

  Future<void> getGovernorates({
    required bool internal,
    bool isStart = false,
    LatLng? startLocation,
  }) async {
    final target = startLocation ?? currentLocation;
    if (_cachedRegionModel != null && _cachedRegionLocation != null) {
      final dLat = (target.latitude - _cachedRegionLocation!.latitude).abs();
      final dLng = (target.longitude - _cachedRegionLocation!.longitude).abs();
      if (dLat < 0.05 && dLng < 0.05) {
        _applyRegionPolygon(
          _cachedRegionModel!,
          internal: internal,
          isStart: isStart,
        );
        emit(GetGovernoratesSuccessState());
        return;
      }
    }

    emit(GetGovernoratesLoadingState());
    final result = await googleMapRepoImpl.getGovernorate(
      currentLocation: target,
    );
    result.fold((l) {
      emit(GetGovernoratesErrorState(errorMessage: l.message));
    }, (r) {
      _cachedRegionModel = r;
      _cachedRegionLocation = target;
      _applyRegionPolygon(r, internal: internal, isStart: isStart);
      emit(GetGovernoratesSuccessState());
    });
  }
}

List<mp.LatLng> convertToGoogleLatLng(List<LatLng> mpList) {
  return mpList
      .map((point) => mp.LatLng(point.latitude, point.longitude))
      .toList();
}

enum MapState {
  initial,
  loading,
  loaded,
  error,
}
