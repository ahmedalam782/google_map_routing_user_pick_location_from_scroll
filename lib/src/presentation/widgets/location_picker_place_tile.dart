import 'package:flutter/material.dart';

import '../controller/location_picker_controller.dart';
import '../../domain/models/places_model/prediction.dart';
import '../theme/location_picker_color.dart';
import '../theme/location_picker_icon.dart';
import '../theme/location_picker_theme.dart';
import 'location_picker_graphic_view.dart';

class LocationPickerPlaceTile extends StatelessWidget {
  const LocationPickerPlaceTile({
    super.key,
    required this.controller,
    required this.theme,
    required this.prediction,
    required this.internal,
    required this.isStart,
  });

  final LocationPickerController controller;
  final LocationPickerTheme theme;
  final Prediction prediction;
  final bool internal;
  final bool isStart;

  Future<void> _open(BuildContext context) async {
    final placeId = prediction.placeId;
    if (placeId == null) return;
    await controller.getPlaceDetails(
      placeId: placeId,
      internal: internal,
      isStart: isStart,
    );
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = theme.colorOf(LocationPickerColorRole.icon);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: () => _open(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: LocationPickerGraphicView(
          graphic: theme.graphicOf(LocationPickerIconRole.history),
          iconColor: iconColor,
          size: 20,
        ),
        title: Text(
          prediction.description ?? '',
          style: TextStyle(
            color: theme.colorOf(LocationPickerColorRole.searchText),
            fontFamily: theme.fontOf(),
          ),
        ),
        trailing: LocationPickerGraphicView(
          graphic: theme.graphicOf(LocationPickerIconRole.trailing),
          iconColor: iconColor,
          size: 20,
        ),
      ),
    );
  }
}
