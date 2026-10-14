import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'location_picker_color.dart';
import 'location_picker_icon.dart';
import 'location_picker_text.dart';

/// Visual and written settings for the location picker.
///
/// Pass one theme into [MdSoftGoogleMapUserPickLocationFromScroll]. Override
/// only the sentences, colors, and icons that should change. Mixins fill in
/// the rest from the package defaults and from the map config.
class LocationPickerTheme
    with
        LocationPickerCopyResolver,
        LocationPickerColorResolver,
        LocationPickerIconResolver,
        LocationPickerFontResolver {
  const LocationPickerTheme({
    this.textOverrides = const {},
    this.primaryColor,
    this.onPrimaryColor,
    this.iconColor,
    this.surfaceColor,
    this.searchFillColor,
    this.searchTextColor,
    this.searchHintColor,
    this.cursorColor,
    this.polygonColor,
    this.barrierColor,
    this.fabBackgroundColor,
    this.fontFamily,
    this.textDirection = TextDirection.rtl,
    this.placeLanguageCode = 'ar',
    this.search,
    this.history,
    this.trailing,
    this.startPin,
    this.endPin,
    this.currentLocationMarker,
    this.currentLocationButton,
    this.polygonFillOpacity = 0.15,
  });

  @override
  final Map<LocationPickerText, String> textOverrides;
  @override
  final Color? primaryColor;
  @override
  final Color? onPrimaryColor;

  /// Tint for Flutter icons and SVG assets. PNG and JPG files keep their own
  /// pixels unless the graphic sets its own color.
  @override
  final Color? iconColor;
  @override
  final Color? surfaceColor;
  @override
  final Color? searchFillColor;
  @override
  final Color? searchTextColor;
  @override
  final Color? searchHintColor;
  @override
  final Color? cursorColor;
  @override
  final Color? polygonColor;
  @override
  final Color? barrierColor;
  @override
  final Color? fabBackgroundColor;
  @override
  final String? fontFamily;

  /// Layout direction for the picker and its toasts.
  final TextDirection textDirection;

  /// Language sent to the place-name lookup. `ar` matches the default copy.
  final String placeLanguageCode;

  /// Search icon. Null keeps the package SVG.
  @override
  final LocationPickerGraphic? search;

  /// Place-history icon. Null keeps the package SVG.
  @override
  final LocationPickerGraphic? history;

  /// Place-row trailing icon. Null keeps the package SVG.
  @override
  final LocationPickerGraphic? trailing;

  /// Pin shown while choosing the start point. Null keeps the package photo.
  @override
  final LocationPickerGraphic? startPin;

  /// Pin shown while choosing the end point. Null keeps the package photo.
  @override
  final LocationPickerGraphic? endPin;

  /// Marker for the device location. Null keeps the package photo.
  @override
  final LocationPickerGraphic? currentLocationMarker;

  /// Button that recenters on the device. Null keeps the location icon.
  @override
  final LocationPickerGraphic? currentLocationButton;

  /// Alpha used when the polygon color is painted on the map.
  final double polygonFillOpacity;

  @override
  bool operator ==(Object other) {
    return other is LocationPickerTheme &&
        mapEquals(textOverrides, other.textOverrides) &&
        primaryColor == other.primaryColor &&
        onPrimaryColor == other.onPrimaryColor &&
        iconColor == other.iconColor &&
        surfaceColor == other.surfaceColor &&
        searchFillColor == other.searchFillColor &&
        searchTextColor == other.searchTextColor &&
        searchHintColor == other.searchHintColor &&
        cursorColor == other.cursorColor &&
        polygonColor == other.polygonColor &&
        barrierColor == other.barrierColor &&
        fabBackgroundColor == other.fabBackgroundColor &&
        fontFamily == other.fontFamily &&
        textDirection == other.textDirection &&
        placeLanguageCode == other.placeLanguageCode &&
        search == other.search &&
        history == other.history &&
        trailing == other.trailing &&
        startPin == other.startPin &&
        endPin == other.endPin &&
        currentLocationMarker == other.currentLocationMarker &&
        currentLocationButton == other.currentLocationButton &&
        polygonFillOpacity == other.polygonFillOpacity;
  }

  @override
  int get hashCode => Object.hashAll([
        _textHash(textOverrides),
        primaryColor,
        onPrimaryColor,
        iconColor,
        surfaceColor,
        searchFillColor,
        searchTextColor,
        searchHintColor,
        cursorColor,
        polygonColor,
        barrierColor,
        fabBackgroundColor,
        fontFamily,
        textDirection,
        placeLanguageCode,
        search,
        history,
        trailing,
        startPin,
        endPin,
        currentLocationMarker,
        currentLocationButton,
        polygonFillOpacity,
      ]);

  static int _textHash(Map<LocationPickerText, String> map) {
    final keys = map.keys.toList()..sort((a, b) => a.index.compareTo(b.index));
    return Object.hashAll([
      for (final key in keys) Object.hash(key, map[key]),
    ]);
  }
}
