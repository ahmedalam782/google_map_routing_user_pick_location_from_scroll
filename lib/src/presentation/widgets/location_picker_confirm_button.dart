import 'package:flutter/material.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

import '../controller/location_picker_controller.dart';
import '../../domain/entities/md_on_user_selcted_place.dart';
import '../theme/location_picker_color.dart';
import '../theme/location_picker_text.dart';
import '../theme/location_picker_theme.dart';
import 'custom_button.dart';
import 'location_picker_toast.dart';

class LocationPickerConfirmButton extends StatelessWidget {
  const LocationPickerConfirmButton({
    super.key,
    required this.controller,
    required this.theme,
    required this.internal,
    required this.isStart,
    required this.onSelected,
  });

  final LocationPickerController controller;
  final LocationPickerTheme theme;
  final bool internal;
  final bool isStart;
  final void Function(MdOnUserSelectedPlace place) onSelected;

  void _confirm(BuildContext context) {
    final location = controller.selectedLocation;
    if (location == null) return;
    final place = MdOnUserSelectedPlace(
      selectedLocation: location,
      pointName: controller.locationName ?? '',
    );
    if (!MdUserPickLocationGoogleMapConfig.current.searchGovernorate) {
      onSelected(place);
      return;
    }
    if (internal) {
      if (controller.chackInternalOrNot(location)) {
        onSelected(place);
      } else {
        LocationPickerToast.showText(
          context,
          theme,
          LocationPickerText.insideBoundary,
        );
      }
      return;
    }
    if (isStart) {
      onSelected(place);
      return;
    }
    if (controller.chackInternalOrNot(location)) {
      LocationPickerToast.showText(
        context,
        theme,
        LocationPickerText.outsideBoundary,
      );
      return;
    }
    onSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      onTap: () => _confirm(context),
      color: theme.colorOf(LocationPickerColorRole.primary),
      textStyle: TextStyle(
        fontSize: 19,
        color: theme.colorOf(LocationPickerColorRole.onPrimary),
        fontFamily: theme.fontOf(),
      ),
      text: theme.textOf(LocationPickerText.confirmPoint),
    );
  }
}
