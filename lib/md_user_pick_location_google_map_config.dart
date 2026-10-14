import 'package:flutter/material.dart';

/// Key, server, color, and font for one location picker screen.
///
/// Pass it to [MdSoftGoogleMapUserPickLocationFromScroll]. Use [copyWith]
/// on that screen when one value should change.
class MdUserPickLocationGoogleMapConfig {
  const MdUserPickLocationGoogleMapConfig({
    required this.apiKey,
    required this.baseUrl,
    this.primaryColor = const Color(0xffD60020),
    this.fontFamily = 'Hanimation Arabic',
    this.userAgent =
        'MdSoftGoogleMapUserPickLocationFromScroll/1.0 (info@mdsoft.com)',
    this.searchGovernorate = true,
    this.governorateEndpoint = 'governorates/me',
    this.governorateLatitudeQuery = 'lat',
    this.governorateLongitudeQuery = 'lng',
    this.placesBaseUrl = 'https://maps.googleapis.com/maps/api/place/',
  });

  final String? apiKey;
  final String? baseUrl;
  final Color primaryColor;
  final String fontFamily;
  final String userAgent;

  /// When true, the screen loads the governorate polygon from [governorateEndpoint].
  final bool searchGovernorate;

  /// Path or full URL for the governorate call.
  ///
  /// A path is joined to [baseUrl]. A value that starts with `http` is used
  /// as the full address.
  final String governorateEndpoint;

  final String governorateLatitudeQuery;
  final String governorateLongitudeQuery;

  /// Google Places root. Autocomplete and details are appended to it.
  final String placesBaseUrl;

  static const MdUserPickLocationGoogleMapConfig _fallback =
      MdUserPickLocationGoogleMapConfig(
    apiKey: null,
    baseUrl: null,
    searchGovernorate: false,
  );

  static MdUserPickLocationGoogleMapConfig _current = _fallback;

  /// The config applied by the picker screen that is open.
  static MdUserPickLocationGoogleMapConfig get current => _current;

  /// Makes this the config used by the picker that is about to open.
  void apply() {
    _current = this;
  }

  String get placesRoot {
    final root = placesBaseUrl.trim();
    if (root.isEmpty) return 'https://maps.googleapis.com/maps/api/place/';
    return root.endsWith('/') ? root : '$root/';
  }

  String get governorateUrl {
    final endpoint = governorateEndpoint.trim();
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    final rootValue = baseUrl ?? '';
    final root = rootValue.endsWith('/') ? rootValue : '$rootValue/';
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$root$path';
  }

  MdUserPickLocationGoogleMapConfig copyWith({
    String? apiKey,
    String? baseUrl,
    Color? primaryColor,
    String? fontFamily,
    String? userAgent,
    bool? searchGovernorate,
    String? governorateEndpoint,
    String? governorateLatitudeQuery,
    String? governorateLongitudeQuery,
    String? placesBaseUrl,
  }) {
    return MdUserPickLocationGoogleMapConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      userAgent: userAgent ?? this.userAgent,
      searchGovernorate: searchGovernorate ?? this.searchGovernorate,
      governorateEndpoint: governorateEndpoint ?? this.governorateEndpoint,
      governorateLatitudeQuery:
          governorateLatitudeQuery ?? this.governorateLatitudeQuery,
      governorateLongitudeQuery:
          governorateLongitudeQuery ?? this.governorateLongitudeQuery,
      placesBaseUrl: placesBaseUrl ?? this.placesBaseUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MdUserPickLocationGoogleMapConfig &&
        other.apiKey == apiKey &&
        other.baseUrl == baseUrl &&
        other.primaryColor == primaryColor &&
        other.fontFamily == fontFamily &&
        other.userAgent == userAgent &&
        other.searchGovernorate == searchGovernorate &&
        other.governorateEndpoint == governorateEndpoint &&
        other.governorateLatitudeQuery == governorateLatitudeQuery &&
        other.governorateLongitudeQuery == governorateLongitudeQuery &&
        other.placesBaseUrl == placesBaseUrl;
  }

  @override
  int get hashCode => Object.hash(
        apiKey,
        baseUrl,
        primaryColor,
        fontFamily,
        userAgent,
        searchGovernorate,
        governorateEndpoint,
        governorateLatitudeQuery,
        governorateLongitudeQuery,
        placesBaseUrl,
      );
}
