import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

/// Reverse geocoding through OpenStreetMap Nominatim.
class LocationPickerOsm {
  LocationPickerOsm._();

  static final Map<String, String> _cache = {};
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      headers: const {
        'Accept': 'application/json',
        'Accept-Language': 'ar',
      },
    ),
  );
  static Future<void> _chain = Future<void>.value();
  static DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  /// Nominatim allows one request per second. Queue calls so scrolling
  /// the map does not get blocked with HTTP 429.
  static Future<T> _runSlot<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _chain = _chain.catchError((_) {}).then((_) async {
      final wait = _nextSlot.difference(DateTime.now());
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
      _nextSlot = DateTime.now().add(const Duration(seconds: 1));
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  static Future<String> getPlaceName(
    double lat,
    double lng, {
    String languageCode = 'ar',
    String unknownLabel = 'غير معروف',
  }) async {
    final key =
        '$languageCode:${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final cached = _cache[key];
    if (cached != null && cached.isNotEmpty) return cached;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final address = await _runSlot(
          () => _reverseGeocode(lat, lng, languageCode: languageCode),
        );
        if (address != null && address.isNotEmpty) {
          _cache[key] = address;
          return address;
        }
        return unknownLabel;
      } catch (e) {
        debugPrint('OSM request failed: $e');
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    return unknownLabel;
  }

  static Future<String?> _reverseGeocode(
    double lat,
    double lng, {
    required String languageCode,
  }) async {
    final userAgent =
        MdUserPickLocationGoogleMapConfig.current.userAgent.trim();
    final response = await _dio.get<dynamic>(
      '/reverse',
      queryParameters: <String, dynamic>{
        'lat': lat,
        'lon': lng,
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': languageCode,
      },
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'User-Agent': userAgent.isEmpty
              ? 'MdSoftGoogleMapUserPickLocationFromScroll/1.0 (info@mdsoft.com)'
              : userAgent,
          'Accept-Language': languageCode,
        },
      ),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'OSM reverse geocode failed (${response.statusCode})',
      );
    }
    return _addressFrom(response.data);
  }

  static String? _addressFrom(dynamic data) {
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    if (map == null || map['error'] != null) return null;

    final rawAddress = map['address'];
    if (rawAddress is Map) {
      final address = Map<String, dynamic>.from(rawAddress);
      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      final parts = <String?>[
        pick(const ['state', 'province', 'region']),
        pick(const ['city', 'town', 'village', 'municipality']),
        pick(const ['city_district', 'suburb', 'quarter', 'neighbourhood']),
        pick(const ['road', 'pedestrian', 'street']),
      ].whereType<String>().toList();

      final unique = <String>[];
      for (final part in parts) {
        if (!unique.contains(part)) unique.add(part);
      }
      if (unique.isNotEmpty) return unique.join(' - ');
    }

    final display = map['display_name'];
    if (display is String && display.trim().isNotEmpty) return display.trim();
    return null;
  }
}
