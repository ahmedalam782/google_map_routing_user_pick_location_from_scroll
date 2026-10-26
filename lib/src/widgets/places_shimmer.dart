import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWrapper extends StatelessWidget {
  const ShimmerWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFE0E0E0),
          highlightColor: const Color(0xFFF5F5F5),
          period: const Duration(milliseconds: 1500),
          child: child,
        ),
      );
}

class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({super.key, this.height, this.width, this.radius = 8});
  final double? height, width;
  final double radius;

  @override
  Widget build(BuildContext context) => ShimmerWrapper(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}

/// Skeleton rows with the same layout as the prediction rows.
class PlacesShimmer extends StatelessWidget {
  const PlacesShimmer({super.key, this.length = 5});
  final int length;

  @override
  Widget build(BuildContext context) => ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: length,
        itemBuilder: (_, __) => const ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          leading: ShimmerBlock(height: 20, width: 20, radius: 10),
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ShimmerBlock(height: 16, width: 220),
          ),
          trailing: ShimmerBlock(height: 16, width: 16, radius: 4),
        ),
      );
}
