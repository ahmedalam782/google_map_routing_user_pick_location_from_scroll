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
import 'package:geolocator/geolocator.dart';
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

//? getLocation
  Future<void> getLocationMyCurrentLocation(
      {LatLng? startLocation,
      LatLng? oldLocation,
      bool isStart = false,
      bool internal = false}) async {
    try {
      mapState = MapState.loading;
      emit(GetCurrentLocationLoadingState());
      Future.delayed(const Duration(seconds: 5));
      final Position locationData = await locationService.getLocation();
      currentLocationLatLang = LatLng(
        locationData.latitude,
        locationData.longitude,
      );

      currentLocation = oldLocation ??
          LatLng(locationData.latitude, locationData.longitude);
      var myCameraPosition = (!internal && !isStart)
          ? CameraPosition(target: oldLocation ?? currentLocation, zoom: 9)
          : CameraPosition(target: oldLocation ?? currentLocation, zoom: 17);
      // Check if cubit is closed before animating camera
      if (!isClosed) {
        await googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            myCameraPosition,
          ),
        );
      } else {
        emit(GetLocationErrorState(errorMessage: 'Cubit is closed.'));
        return;
      }
      updateCurrentLocationMarker();
      selectedLocation = currentLocation;
      selectedPlaceName(currentLocation);
      mapState = MapState.loaded;
      emit(GetLocationSuccessState());
    } on LocationServiceException catch (_) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'Please Check your location Serveice  '));
    } on LocationPermissionException catch (_) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'Please Check your  Location Permission '));
    } on PlatformException catch (e) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'Get Location Failed: ${e.message ?? e.toString()}'));
    } catch (e) {
      mapState = MapState.error;
      emit(GetLocationErrorState(
          errorMessage: 'An unexpected location error occurred.'));
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
        if (token != _placeNameToken || isClosed) return;
        final address =
            await getPlaceNameOSM(latLng.latitude, latLng.longitude);
        if (token != _placeNameToken || isClosed) return;
        locationName = address;
        searchController.text = address;
        emit(SelectedLocationNameState());
      } catch (error) {
        if (token != _placeNameToken || isClosed) return;
        debugPrint('Error in selectedPlaceName: $error');
        locationName = 'Unknown';
        searchController.text = locationName!;
        emit(SelectedLocationNameState());
      } finally {
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
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

  void clear() {
    searchController.clear();
    predictions = [];
    sessionToken = null;
    emit(ClearState());
  }

//? getPredictions
  Uuid uuid = const Uuid();
  String? sessionToken;
  List<Prediction> predictions = [];
  TextEditingController searchController = TextEditingController();
  Future<void> getPredictions() async {
    if (searchController.text.isEmpty) {
      predictions = [];
      emit(GetPredictionsSuccessState());
      return;
    }
    sessionToken ??= uuid.v4();
    final result = await googleMapRepoImpl.getPredictions(
        input: searchController.text, sessionToken: sessionToken!);
    result.fold((l) => emit(GetPredictionsErrorState(errorMessage: l.message)),
        (r) {
      predictions = r.predictions!;
      emit(GetPredictionsSuccessState());
    });
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

  Future<void> getPlaceDetails({
    required String placeId,
    bool internal = false,
    bool isStart = false,
  }) async {
    final result = await googleMapRepoImpl.getPlaceDetails(placeId: placeId);
    result.fold((l) {
      emit(GetPlaceDetailsErrorState(errorMessage: l.message));
    }, (r) async {
      if (isStart && !internal) {
        _onSearchAdd(r);
        emit(GetPlaceDetailsSuccessState());
        return;
      }
      if (internal) {
        if (regionModel == null) {
          emit(GetPlaceDetailsErrorState(
              errorMessage: 'الرجاء الانتظار لتحميل بيانات المنطقة'));
          return;
        }

        bool inside = chackInternalOrNot(LatLng(
            r.result!.geometry!.location!.lat!,
            r.result!.geometry!.location!.lng!));
        if (inside) {
          _onSearchAdd(r);
        } else {
          emit(GetPlaceDetailsErrorState(
              errorMessage:
                  'يرجى اختيار موقع داخل الحدود المحددة، حيث أن هذه رحلة داخلية'));
          return;
        }
      } else {
        if (regionModel == null) {
          emit(GetPlaceDetailsErrorState(
              errorMessage: 'الرجاء الانتظار لتحميل بيانات المنطقة'));
          return;
        }

        bool inside = chackInternalOrNot(LatLng(
            r.result!.geometry!.location!.lat!,
            r.result!.geometry!.location!.lng!));
        if (inside) {
          emit(GetPlaceDetailsErrorState(
              errorMessage:
                  'يرجى اختيار موقع خارج الحدود المحددة، حيث أن هذه رحلة خارجية'));
          return;
        } else {
          _onSearchAdd(r);
        }
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

  void _onSearchAdd(PlaceDetailsModel r) async {
    placeDetailsLocation = LatLng(
        r.result!.geometry!.location!.lat!, r.result!.geometry!.location!.lng!);

    googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          placeDetailsLocation.latitude,
          placeDetailsLocation.longitude,
        ),
        16,
      ),
    );
    clear();
  }

  RegionModel? regionModel;
  Set<Polygon> polygon = {};
  //? get governorates
  MapState mapState = MapState.initial;
  Future<void> getGovernorates({
    required bool internal,
    bool isStart = false,
    LatLng? startLocation,
  }) async {
    mapState = MapState.loading;
    emit(GetGovernoratesLoadingState());
    final result = await googleMapRepoImpl.getGovernorate(
      currentLocation: startLocation ?? currentLocation,
    );
    result.fold((l) {
      mapState = MapState.error;
      emit(GetGovernoratesErrorState(errorMessage: l.message));
    }, (r) {
      regionModel = r;
      if (internal) {
        final Polygon polygon = Polygon(
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
        this.polygon.add(polygon);
      } else {
        if (!isStart) {
          final Polygon polygon = Polygon(
            polygonId: PolygonId(r.polygonId),
            points:
                r.geometry.coordinates[0].map((e) => LatLng(e[1], e[0])).toList(),
            strokeWidth: 2,
            strokeColor: Colors.red,
            fillColor: Colors.red.withValues(alpha: 0.15),
          );
          this.polygon.add(polygon);
        }
      }
      emit(GetGovernoratesSuccessState());
      mapState = MapState.loaded;
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
