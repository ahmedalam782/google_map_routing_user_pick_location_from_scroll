import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';

import '../../api/google_map_api.dart';
import '../../core/api/api_error_handler.dart';
import '../../core/api/base_response/base_response.dart';
import '../../core/api/base_response/result.dart';
import '../../domain/models/geometry/geometry.dart';
import '../../domain/models/place_details_model/place_details_model.dart';
import '../../domain/models/places_model/places_model.dart';
import '../../domain/repositories/google_map_repo.dart';

@Injectable(as: GoogleMapRepo)
class GoogleMapRepoImpl extends GoogleMapRepo {
  GoogleMapRepoImpl({required this.api});

  final GoogleMapApi api;

  @override
  Future<Result<PlacesModel>> getPredictions({
    required String input,
    required String sessionToken,
  }) {
    return executeApi(
      () => api.getPredictions(
        input: input,
        sessionToken: sessionToken,
      ),
    );
  }

  @override
  Future<Result<PlaceDetailsModel>> getPlaceDetails({
    required String placeId,
  }) {
    return executeApi(() => api.getPlaceDetails(placeId: placeId));
  }

  @override
  Future<Result<BaseResponse<RegionModel>>> getGovernorate({
    required LatLng currentLocation,
  }) {
    return executeApi(
      () => api.getGovernorate(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      ),
    );
  }
}
