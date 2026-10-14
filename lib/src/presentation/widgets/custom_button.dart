import 'package:flutter/material.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';

class CustomButton extends StatelessWidget {
  final String? text;
  final double? widthPadding;
  final Function()? onTap;
  final Widget? widget;
  final double? borderRadius;
  final double? height;
  final double? width;
  final Color? color;
  final bool? haveBorder;
  final bool? isSecColor;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    this.text,
    this.haveBorder = false,
    this.height,
    this.color,
    this.width,
    this.borderRadius,
    required this.onTap,
    this.widget,
    this.textStyle,
    this.isSecColor,
    this.widthPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          color: color ??
              MdUserPickLocationGoogleMapConfig.current.primaryColor),
      height: height ?? 50,
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.black12,
          backgroundColor: color ?? Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
        ),
        onPressed: onTap,
        child: text != null
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text!,
                  style: textStyle ??
                      TextStyle(
                          fontSize: 19,
                          color: Colors.white,
                          fontFamily:
                              MdUserPickLocationGoogleMapConfig
                                  .current.fontFamily),
                ),
              )
            : widget,
      ),
    );
  }
}
