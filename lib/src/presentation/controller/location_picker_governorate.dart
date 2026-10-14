part of 'location_picker_controller.dart';

mixin LocationPickerGovernorate on LocationPickerControllerBase {
  RegionModel? regionModel;
  Set<Polygon> polygon = {};

  void _recolorPolygons() {
    if (polygon.isEmpty) return;
    final stroke = theme.colorOf(LocationPickerColorRole.polygon);
    final fill = stroke.withValues(alpha: theme.polygonFillOpacity);
    polygon = polygon
        .map(
          (item) => item.copyWith(
            strokeColorParam: stroke,
            fillColorParam: fill,
          ),
        )
        .toSet();
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
        _convertToGoogleLatLng(
          regionModel!.geometry.coordinates[0]
              .map((e) => LatLng(e[1], e[0]))
              .toList(),
        ),
      );
      return inside;
    } catch (e) {
      debugPrint('Error in chackInternalOrNot: $e');
      return false;
    }
  }

  Future<void> getGovernorates({
    required bool internal,
    bool isStart = false,
    LatLng? startLocation,
  }) async {
    mapState = MapState.loading;
    _notify();
    final result = await googleMapRepoImpl.getGovernorate(
      currentLocation: startLocation ?? currentLocation,
    );
    result.fold(
      onSuccess: (success) {
        final r = success.data!.data!;
        regionModel = r;
        if (internal) {
          final Polygon polygon = Polygon(
            polygonId: PolygonId('${r.polygonId}_inverse'),
            points: const [
              LatLng(37.5, 38.5),
              LatLng(37.5, 48.6),
              LatLng(29.0, 48.6),
              LatLng(29.0, 38.5),
              LatLng(37.5, 38.5)
            ],
            holes: [
              r.geometry.coordinates[0].map((e) => LatLng(e[1], e[0])).toList(),
            ],
            strokeWidth: 2,
            strokeColor: theme.colorOf(LocationPickerColorRole.polygon),
            fillColor: theme
                .colorOf(LocationPickerColorRole.polygon)
                .withValues(alpha: theme.polygonFillOpacity),
          );
          this.polygon.add(polygon);
        } else {
          if (!isStart) {
            final Polygon polygon = Polygon(
              polygonId: PolygonId(r.polygonId),
              points: r.geometry.coordinates[0]
                  .map((e) => LatLng(e[1], e[0]))
                  .toList(),
              strokeWidth: 2,
              strokeColor: theme.colorOf(LocationPickerColorRole.polygon),
              fillColor: theme
                  .colorOf(LocationPickerColorRole.polygon)
                  .withValues(alpha: theme.polygonFillOpacity),
            );
            this.polygon.add(polygon);
          }
        }
        mapState = MapState.loaded;
        _notify();
      },
      onError: (error) {
        mapState = MapState.error;
        _reportRaw(_messageOf(error.exception));
      },
    );
  }
}

List<mp.LatLng> _convertToGoogleLatLng(List<LatLng> mpList) {
  return mpList
      .map((point) => mp.LatLng(point.latitude, point.longitude))
      .toList();
}
