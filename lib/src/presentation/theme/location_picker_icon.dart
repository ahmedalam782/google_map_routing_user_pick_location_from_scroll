import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/app_images.dart';
import '../../core/utils/extension.dart';

/// An image slot on the location picker.
enum LocationPickerIconRole {
  search,
  history,
  trailing,
  startPin,
  endPin,
  currentLocation,
  currentLocationButton,
}

/// Where a [LocationPickerGraphic] gets its picture.
enum LocationPickerGraphicSource { icon, asset }

/// One picture for a picker slot.
///
/// Leave the theme field null to keep the package image. Pass
/// [LocationPickerGraphic.icon] for a Flutter icon, or
/// [LocationPickerGraphic.asset] for a PNG, JPG, SVG, or any other asset path.
class LocationPickerGraphic {
  const LocationPickerGraphic.icon(
    this.icon, {
    this.size,
    this.color,
  })  : asset = null,
        source = LocationPickerGraphicSource.icon;

  const LocationPickerGraphic.asset(
    this.asset, {
    this.size,
    this.color,
  })  : icon = null,
        source = LocationPickerGraphicSource.asset;

  final LocationPickerGraphicSource source;
  final IconData? icon;
  final String? asset;
  final double? size;

  /// Tint for an icon or an SVG. A PNG or JPG keeps its own pixels unless
  /// this is set.
  final Color? color;

  bool get isSvg {
    final path = asset?.toLowerCase();
    return path != null && path.endsWith('.svg');
  }

  @override
  bool operator ==(Object other) {
    return other is LocationPickerGraphic &&
        source == other.source &&
        icon == other.icon &&
        asset == other.asset &&
        size == other.size &&
        color == other.color;
  }

  @override
  int get hashCode => Object.hash(source, icon, asset, size, color);

  Future<BitmapDescriptor> toMapMarker({required Color iconColor}) {
    final tint = color ?? iconColor;
    final markerSize = size ?? 48;
    return switch (source) {
      LocationPickerGraphicSource.icon =>
        _iconMarker(icon!, markerSize, tint),
      LocationPickerGraphicSource.asset when isSvg =>
        _svgMarker(asset!, markerSize, tint),
      LocationPickerGraphicSource.asset =>
        asset!.toBitmapDescriptor(devicePixelRatio: 2.5),
    };
  }

  static Future<BitmapDescriptor> _iconMarker(
    IconData icon,
    double size,
    Color color,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
    painter.layout();
    painter.paint(canvas, Offset.zero);
    final image = await recorder.endRecording().toImage(
          painter.width.ceil().clamp(1, 512),
          painter.height.ceil().clamp(1, 512),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _svgMarker(
    String asset,
    double size,
    Color color,
  ) async {
    final pictureInfo = await vg.loadPicture(SvgAssetLoader(asset), null);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = pictureInfo.size.width == 0 ? 1.0 : pictureInfo.size.width;
    final height = pictureInfo.size.height == 0 ? 1.0 : pictureInfo.size.height;
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size, size),
      Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
    canvas.scale(size / width, size / height);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();
    final image =
        await recorder.endRecording().toImage(size.ceil(), size.ceil());
    pictureInfo.picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}

/// Chooses the picture for each [LocationPickerIconRole].
///
/// A null field keeps the image shipped with the package.
mixin LocationPickerIconResolver {
  LocationPickerGraphic? get search;
  LocationPickerGraphic? get history;
  LocationPickerGraphic? get trailing;
  LocationPickerGraphic? get startPin;
  LocationPickerGraphic? get endPin;
  LocationPickerGraphic? get currentLocationMarker;
  LocationPickerGraphic? get currentLocationButton;

  LocationPickerGraphic graphicOf(LocationPickerIconRole role) {
    return switch (role) {
      LocationPickerIconRole.search =>
        search ?? const LocationPickerGraphic.asset(AppImages.search, size: 20),
      LocationPickerIconRole.history => history ??
          const LocationPickerGraphic.asset(AppImages.clock, size: 20),
      LocationPickerIconRole.trailing => trailing ??
          const LocationPickerGraphic.asset(AppImages.frame, size: 20),
      LocationPickerIconRole.startPin =>
        startPin ?? const LocationPickerGraphic.asset(AppImages.point),
      LocationPickerIconRole.endPin =>
        endPin ?? const LocationPickerGraphic.asset(AppImages.endLocation),
      LocationPickerIconRole.currentLocation => currentLocationMarker ??
          const LocationPickerGraphic.asset(AppImages.currentLocation),
      LocationPickerIconRole.currentLocationButton => currentLocationButton ??
          const LocationPickerGraphic.icon(Icons.location_searching, size: 24),
    };
  }
}

