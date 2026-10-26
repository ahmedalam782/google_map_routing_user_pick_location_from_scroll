part of 'google_map_cubit.dart';

abstract class GoogleMapState {
  const GoogleMapState();
}

class GoogleMapInitial extends GoogleMapState {}

class GetLocationSuccessState extends GoogleMapState {}

class ChangeStartState extends GoogleMapState {}

class GetCurrentLocationLoadingState extends GoogleMapState {}

class GetLocationErrorState extends GoogleMapState {
  String errorMessage;

  GetLocationErrorState({required this.errorMessage});
}

class GetMapStyleSuccessState extends GoogleMapState {}

class GetPredictionsErrorState extends GoogleMapState {
  String errorMessage;

  GetPredictionsErrorState({required this.errorMessage});
}

class GetPredictionsLoadingState extends GoogleMapState {}

class GetPredictionsSuccessState extends GoogleMapState {}

class GetPlaceDetailsSuccessState extends GoogleMapState {}

class GetPlaceDetailsErrorState extends GoogleMapState {
  String errorMessage;

  GetPlaceDetailsErrorState({required this.errorMessage});
}

class SetMarkersSuccessState extends GoogleMapState {}

class SetEditIndexSuccessState extends GoogleMapState {}

class ClearState extends GoogleMapState {}

class GetGovernoratesLoadingState extends GoogleMapState {}

class GetGovernoratesSuccessState extends GoogleMapState {}

class SelectedLocationNameState extends GoogleMapState {}

class OutsideIraqState extends GoogleMapState {}

class GetGovernoratesErrorState extends GoogleMapState {
  String errorMessage;

  GetGovernoratesErrorState({required this.errorMessage});
}
