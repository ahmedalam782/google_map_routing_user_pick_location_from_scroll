import 'package:flutter/material.dart';

import '../controller/location_picker_controller.dart';
import '../theme/location_picker_color.dart';
import '../theme/location_picker_icon.dart';
import '../theme/location_picker_text.dart';
import 'custom_textformfield.dart';
import 'location_picker_graphic_view.dart';

class LocationPickerSearchField extends StatelessWidget {
  const LocationPickerSearchField({
    super.key,
    required this.width,
    required this.controller,
  });

  final double width;
  final LocationPickerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = controller.theme;
        return SizedBox(
          width: width / 1.2,
          child: CustomTextFormFeild(
            focusNode: controller.searchFocusNode,
            controller: controller.searchController,
            label: theme.textOf(LocationPickerText.searchHint),
            textDirection: theme.textDirection,
            cursorColor: theme.colorOf(LocationPickerColorRole.cursor),
            textColor: theme.colorOf(LocationPickerColorRole.searchText),
            hintColor: theme.colorOf(LocationPickerColorRole.searchHint),
            fontFamily: theme.fontOf(),
            color: theme.colorOf(LocationPickerColorRole.searchFill),
            onChange: controller.onSearchChanged,
            prefixIcon: LocationPickerGraphicView(
              graphic: theme.graphicOf(LocationPickerIconRole.search),
              iconColor: theme.colorOf(LocationPickerColorRole.icon),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
