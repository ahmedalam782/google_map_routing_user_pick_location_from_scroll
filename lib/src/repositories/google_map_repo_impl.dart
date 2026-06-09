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

class GoogleMapRepoImpl extends GoogleMapRepo {
  final DioClient dioClient;

  GoogleMapRepoImpl({required this.dioClient});
  final String apiKey = MdUserPickLocationGoogleMapConfig.apiKey;

  @override
  Future<Either<Failure, PlacesModel>> getPredictions(
      {required String input, required String sessionToken}) async {
    try {
      final response = await dioClient.get(
        '${EndPoints.placesBaseUrl}autocomplete/json?key=$apiKey&input=$input&sessiontoken=$sessionToken',
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
  }) async {
    try {
      final response = await dioClient.get(
          '${EndPoints.placesBaseUrl}details/json?key=$apiKey&place_id=$placeId');
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
