import 'package:flutter/material.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

import 'dotted_border_painter.dart';

class DottedContainer extends StatelessWidget {
  final void Function()? onTap;
  final String title;
  final Widget? imageOrIcon;

  const DottedContainer({
    super.key,
    required this.onTap,
    required this.title,
    this.imageOrIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(),
      child: InkWell(
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  imageOrIcon ??
                      const Icon(
                        Icons.add_circle_rounded,
                        size: 24,
                        color: Colors.black,
                      ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontFamily: MdUserPickLocationGoogleMapConfig.current.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
