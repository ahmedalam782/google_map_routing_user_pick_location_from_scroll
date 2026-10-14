import 'package:flutter/material.dart';

import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

/// A color job in the location picker.
///
/// [LocationPickerColorRole.icon] tints the search, history, and trailing
/// icons, and the current-location button.
enum LocationPickerColorRole {
  primary,
  onPrimary,
  icon,
  surface,
  searchFill,
  searchText,
  searchHint,
  cursor,
  polygon,
  barrier,
  fabBackground,
}

/// Resolves each [LocationPickerColorRole] from an override, then from
/// [MdUserPickLocationGoogleMapConfig], then from the package default.
mixin LocationPickerColorResolver {
  Color? get primaryColor;
  Color? get onPrimaryColor;
  Color? get iconColor;
  Color? get surfaceColor;
  Color? get searchFillColor;
  Color? get searchTextColor;
  Color? get searchHintColor;
  Color? get cursorColor;
  Color? get polygonColor;
  Color? get barrierColor;
  Color? get fabBackgroundColor;

  Color colorOf(LocationPickerColorRole role) {
    final primary = primaryColor ??
        MdUserPickLocationGoogleMapConfig.current.primaryColor;
    return switch (role) {
      LocationPickerColorRole.primary => primary,
      LocationPickerColorRole.onPrimary => onPrimaryColor ?? Colors.white,
      LocationPickerColorRole.icon => iconColor ?? primary,
      LocationPickerColorRole.surface => surfaceColor ?? Colors.white,
      LocationPickerColorRole.searchFill => searchFillColor ?? Colors.white,
      LocationPickerColorRole.searchText =>
        searchTextColor ?? const Color(0xff242021),
      LocationPickerColorRole.searchHint =>
        searchHintColor ?? const Color(0xff606060),
      LocationPickerColorRole.cursor => cursorColor ?? primary,
      LocationPickerColorRole.polygon => polygonColor ?? Colors.red,
      LocationPickerColorRole.barrier => barrierColor ?? Colors.white,
      LocationPickerColorRole.fabBackground =>
        fabBackgroundColor ?? Colors.white,
    };
  }
}

/// Font used by the picker fields, button, and toasts.
mixin LocationPickerFontResolver {
  String? get fontFamily;

  String fontOf() {
    final fromTheme = fontFamily;
    if (fromTheme != null && fromTheme.isNotEmpty) return fromTheme;
    final fromConfig = MdUserPickLocationGoogleMapConfig.current.fontFamily;
    if (fromConfig.isNotEmpty) return fromConfig;
    return 'Hanimation Arabic';
  }
}
