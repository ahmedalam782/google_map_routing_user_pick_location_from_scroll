import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../domain/entities/md_on_user_selcted_place.dart';
import '../controller/location_picker_controller.dart';
import '../theme/location_picker_color.dart';
import '../theme/location_picker_icon.dart';
import 'location_picker_confirm_button.dart';
import 'location_picker_current_location_button.dart';
import 'location_picker_graphic_view.dart';
import 'location_picker_map.dart';
import 'location_picker_places_list.dart';
import 'location_picker_progress.dart';
import 'location_picker_search_field.dart';

class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({
    super.key,
    required this.controller,
    required this.width,
    required this.internal,
    required this.isStart,
    required this.onSelected,
    this.mapStyle,
    this.startLocation,
    this.oldLocation,
  });

  final LocationPickerController controller;
  final double width;
  final bool internal;
  final bool isStart;
  final String? mapStyle;
  final LatLng? startLocation;
  final LatLng? oldLocation;
  final void Function(MdOnUserSelectedPlace place) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = controller.theme;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom > 0
        ? MediaQuery.viewInsetsOf(context).bottom
        : 16.0;
    return ModalProgressHUD(
      inAsyncCall: controller.mapState == MapState.loading,
      color: theme.colorOf(LocationPickerColorRole.barrier),
      opacity: 0.5,
      progressIndicator: LocationPickerProgress(
        color: theme.colorOf(LocationPickerColorRole.primary),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Directionality(
          textDirection: theme.textDirection,
          child: Stack(
            children: [
              LocationPickerMap(
                controller: controller,
                mapStyle: mapStyle,
                internal: internal,
                isStart: isStart,
                startLocation: startLocation,
                oldLocation: oldLocation,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 9, top: 16),
                child: LocationPickerSearchField(
                  width: width,
                  controller: controller,
                ),
              ),
              Center(
                child: LocationPickerGraphicView(
                  graphic: theme.graphicOf(
                    isStart
                        ? LocationPickerIconRole.startPin
                        : LocationPickerIconRole.endPin,
                  ),
                  iconColor: theme.colorOf(LocationPickerColorRole.icon),
                ),
              ),
              Positioned.fill(
                top: 80,
                right: 16,
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: width / 1.2,
                    child: Material(
                      color: theme
                          .colorOf(LocationPickerColorRole.surface)
                          .withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LocationPickerPlacesList(
                        controller: controller,
                        internal: internal,
                        isStart: isStart,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: bottomPadding,
            right: 16,
            left: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocationPickerCurrentLocationButton(
                controller: controller,
                theme: theme,
              ),
              const SizedBox(height: 10),
              LocationPickerConfirmButton(
                controller: controller,
                theme: theme,
                internal: internal,
                isStart: isStart,
                onSelected: onSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
