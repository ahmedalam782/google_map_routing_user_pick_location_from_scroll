import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/location_picker_icon.dart';

/// Draws a [LocationPickerGraphic].
///
/// [size] wins over [LocationPickerGraphic.size]. A raster image with no size
/// uses its own pixel size, which keeps the default pin photos unchanged.
class LocationPickerGraphicView extends StatelessWidget {
  const LocationPickerGraphicView({
    super.key,
    required this.graphic,
    required this.iconColor,
    this.size,
  });

  final LocationPickerGraphic graphic;
  final Color iconColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final tint = graphic.color ?? iconColor;
    final resolvedSize = size ?? graphic.size;
    return switch (graphic.source) {
      LocationPickerGraphicSource.icon => Icon(
          graphic.icon,
          size: resolvedSize ?? 24,
          color: tint,
        ),
      LocationPickerGraphicSource.asset when graphic.isSvg => SvgPicture.asset(
          graphic.asset!,
          height: resolvedSize ?? 20,
          width: resolvedSize ?? 20,
          fit: BoxFit.scaleDown,
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        ),
      LocationPickerGraphicSource.asset => Image.asset(
          graphic.asset!,
          height: resolvedSize,
          width: resolvedSize,
          fit: BoxFit.contain,
          color: graphic.color,
          colorBlendMode: graphic.color == null ? null : BlendMode.srcIn,
        ),
    };
  }
}
