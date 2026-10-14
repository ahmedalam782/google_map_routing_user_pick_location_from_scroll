part of 'location_picker_controller.dart';

mixin LocationPickerSearch on LocationPickerGovernorate {
  Timer? _searchDebounce;
  final Uuid uuid = const Uuid();
  String? sessionToken;
  List<Prediction> predictions = [];
  final TextEditingController searchController = TextEditingController();
  late LatLng placeDetailsLocation;
  List<LatLng> placeDetailsLocationList = [];
  int editIndex = 0;
  bool isEditPlace = false;

  void onSearchChanged(String? query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (_disposed) return;
      if (query != null && query.isNotEmpty) {
        getPredictions();
      } else {
        clear();
      }
    });
  }

  void clear() {
    searchController.clear();
    predictions = [];
    sessionToken = null;
    _notify();
  }

  void setEditIndex(int index) {
    editIndex = index;
    isEditPlace = true;
    _notify();
  }

  Future<void> getPredictions() async {
    if (searchController.text.isEmpty) {
      predictions = [];
      _notify();
      return;
    }
    sessionToken ??= uuid.v4();
    final result = await googleMapRepoImpl.getPredictions(
      input: searchController.text,
      sessionToken: sessionToken!,
    );
    result.fold(
      onSuccess: (success) {
        predictions = success.data!.predictions!;
        _notify();
      },
      onError: (error) => _reportRaw(_messageOf(error.exception)),
    );
  }

  Future<void> getPlaceDetails({
    required String placeId,
    bool internal = false,
    bool isStart = false,
  }) async {
    final result = await googleMapRepoImpl.getPlaceDetails(placeId: placeId);
    result.fold(
      onSuccess: (success) async {
        final r = success.data!;
        if (!MdUserPickLocationGoogleMapConfig.current.searchGovernorate) {
          _onSearchAdd(r);
          _notify();
          return;
        }
        if (isStart && !internal) {
          _onSearchAdd(r);
          _notify();
          return;
        }
        if (internal) {
          if (regionModel == null) {
            _report(LocationPickerText.waitForRegion);
            return;
          }

          bool inside = chackInternalOrNot(LatLng(
            r.result!.geometry!.location!.lat!,
            r.result!.geometry!.location!.lng!,
          ));
          if (inside) {
            _onSearchAdd(r);
          } else {
            _report(LocationPickerText.insideBoundary);
            return;
          }
        } else {
          if (regionModel == null) {
            _report(LocationPickerText.waitForRegion);
            return;
          }

          bool inside = chackInternalOrNot(LatLng(
            r.result!.geometry!.location!.lat!,
            r.result!.geometry!.location!.lng!,
          ));
          if (inside) {
            _report(LocationPickerText.outsideBoundary);
            return;
          } else {
            _onSearchAdd(r);
          }
        }
        _notify();
      },
      onError: (error) => _reportRaw(_messageOf(error.exception)),
    );
  }

  void _onSearchAdd(PlaceDetailsModel r) async {
    placeDetailsLocation = LatLng(
      r.result!.geometry!.location!.lat!,
      r.result!.geometry!.location!.lng!,
    );

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
}
