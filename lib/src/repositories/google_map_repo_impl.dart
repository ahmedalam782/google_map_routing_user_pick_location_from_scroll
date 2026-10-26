import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/api/dio_client.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/api/end_points.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/api/failure.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/models/geometry/geometry.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/models/place_details_model/place_details_model.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/models/places_model/places_model.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/repositories/google_map_repo.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/utils/constants.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/src/utils/geocode_address_line.dart';

class GoogleMapRepoImpl extends GoogleMapRepo {
  final DioClient dioClient;

  GoogleMapRepoImpl({required this.dioClient});
  final String apiKey = MdUserPickLocationGoogleMapConfig.apiKey;

  @override
  Future<Either<Failure, PlacesModel>> getPredictions(
      {required String input, required String sessionToken}) async {
    try {
      final response = await dioClient.get(
        '${EndPoints.placesBaseUrl}autocomplete/json',
        queryParameters: {
          'input': input,
          'sessiontoken': sessionToken,
          'language': 'ar',
          'components': 'country:iq',
          'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        return Right(PlacesModel.fromJson(response.data));
      } else {
        return Left(ServerFailure(response.statusMessage ?? ''));
      }
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaceDetailsModel>> getPlaceDetails({
    required String placeId,
    String? sessionToken,
  }) async {
    try {
      final response = await dioClient.get(
        '${EndPoints.placesBaseUrl}details/json',
        queryParameters: {
          'place_id': placeId,
          if (sessionToken != null) 'sessiontoken': sessionToken,
          'language': 'ar',
          'fields': 'geometry',
          'key': apiKey,
        },
      );
      if (response.statusCode == 200) {
        return Right(PlaceDetailsModel.fromJson(response.data));
      } else {
        return Left(ServerFailure(response.statusMessage ?? ''));
      }
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlaceNameResult>> getPlaceName({
    required double lat,
    required double lng,
  }) async {
    try {
      final nearby = _nearbyPlace(lat, lng); // starts now, awaited below
      final response = await dioClient.get(
        '${EndPoints.mapsBaseUrl}geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'region': 'iq',
          'language': 'ar',
          'key': apiKey,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic> || data['status'] != 'OK') {
        return Left(ServerFailure(
            'Geocode status: ${data is Map ? data['status'] : data.runtimeType}'));
      }
      final line = geocodeAddressLine(data, nearby: await nearby).trim();
      if (line.isEmpty) return Left(ServerFailure('Geocode gave no name'));
      return Right((name: line, countryCode: _countryCode(data)));
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  static String? _countryCode(Map<String, dynamic> data) {
    for (final result in (data['results'] as List?) ?? const []) {
      for (final c in ((result as Map)['address_components'] as List?) ?? const []) {
        final types = List<String>.from((c as Map)['types'] ?? const []);
        if (types.contains('country')) return c['short_name']?.toString();
      }
    }
    return null;
  }

  /// Optional "near" landmark; any failure just means no `قرب …` part.
  Future<String?> _nearbyPlace(double lat, double lng) async {
    try {
      final response = await dioClient.get(
        '${EndPoints.placesBaseUrl}nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': 80,
          'language': 'ar',
          'key': apiKey,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      for (final item in (data['results'] as List?) ?? const []) {
        final place = item as Map;
        final types = List<String>.from(place['types'] ?? const []);
        // Streets and cities are not a "near" landmark.
        if (types.contains('political') ||
            types.contains('route') ||
            types.contains('locality')) {
          continue;
        }
        final name = (place['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Either<Failure, RegionModel>> getGovernorate(
      {required LatLng currentLocation}) async {
    try {
      final response = await dioClient.get(
          '${MdUserPickLocationGoogleMapConfig.baseUrl}governorates/me',
          queryParameters: {
            'lat': currentLocation.latitude,
            'lng': currentLocation.longitude
          });

      return Right(RegionModel.fromJson(response.data));
    } on DioException catch (e) {
      debugPrint('Error getting governorate: ${e.message}');
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
