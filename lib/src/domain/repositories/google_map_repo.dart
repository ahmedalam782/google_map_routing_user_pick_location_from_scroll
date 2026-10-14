import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/api/base_response/base_response.dart';
import '../../core/api/base_response/result.dart';
import '../models/geometry/geometry.dart';
import '../models/place_details_model/place_details_model.dart';
import '../models/places_model/places_model.dart';

abstract class GoogleMapRepo {
  Future<Result<PlacesModel>> getPredictions({
    required String input,
    required String sessionToken,
  });

  Future<Result<PlaceDetailsModel>> getPlaceDetails({
    required String placeId,
  });

  Future<Result<BaseResponse<RegionModel>>> getGovernorate({
    required LatLng currentLocation,
  });
}
