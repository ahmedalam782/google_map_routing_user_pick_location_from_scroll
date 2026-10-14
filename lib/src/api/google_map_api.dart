import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

import '../core/api/base_response/base_response.dart';
import '../core/error/failure.dart';
import '../domain/models/geometry/geometry.dart';
import '../domain/models/place_details_model/place_details_model.dart';
import '../domain/models/places_model/places_model.dart';
/// HTTP calls for places and governorates.
///
/// This class only talks to the network and turns the body into a model.
@injectable
class GoogleMapApi {
  const GoogleMapApi(this.dio);

  final Dio dio;

  Future<PlacesModel> getPredictions({
    required String input,
    required String sessionToken,
  }) async {
    final config = MdUserPickLocationGoogleMapConfig.current;
    final response = await dio.get(
      '${config.placesRoot}autocomplete/json',
      queryParameters: {
        'key': config.apiKey ?? '',
        'input': input,
        'sessiontoken': sessionToken,
      },
    );
    return PlacesModel.fromJson(_asMap(response.data));
  }

  Future<PlaceDetailsModel> getPlaceDetails({
    required String placeId,
  }) async {
    final config = MdUserPickLocationGoogleMapConfig.current;
    final response = await dio.get(
      '${config.placesRoot}details/json',
      queryParameters: {
        'key': config.apiKey ?? '',
        'place_id': placeId,
      },
    );
    return PlaceDetailsModel.fromJson(_asMap(response.data));
  }

  Future<BaseResponse<RegionModel>> getGovernorate({
    required double latitude,
    required double longitude,
  }) async {
    final config = MdUserPickLocationGoogleMapConfig.current;
    final response = await dio.get(
      config.governorateUrl,
      queryParameters: {
        config.governorateLatitudeQuery: latitude,
        config.governorateLongitudeQuery: longitude,
      },
    );
    final envelope = BaseResponse<RegionModel>.fromJson(
      _asMap(response.data),
      RegionModel.fromJson,
    );
    if (envelope.success == false || envelope.data == null) {
      throw ServerFailure(
        envelope.message ?? 'حدث خطأ، يرجى المحاولة مرة أخرى',
      );
    }
    return envelope;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ServerFailure('حدث خطأ، يرجى المحاولة مرة أخرى');
  }
}
