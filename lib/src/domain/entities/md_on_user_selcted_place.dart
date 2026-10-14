import 'package:google_maps_flutter/google_maps_flutter.dart';

class MdOnUserSelectedPlace {
  LatLng selectedLocation;
  String pointName;

  MdOnUserSelectedPlace({
    required this.selectedLocation,
    required this.pointName,
  });
}
