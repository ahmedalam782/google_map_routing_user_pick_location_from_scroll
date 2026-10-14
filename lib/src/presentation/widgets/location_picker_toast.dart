import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/location_picker_text.dart';
import '../theme/location_picker_theme.dart';

/// Shows one picker message. A new call replaces the toast already on screen.
class LocationPickerToast {
  const LocationPickerToast._();

  static ToastificationItem? _current;

  static void showText(
    BuildContext context,
    LocationPickerTheme theme,
    LocationPickerText text,
  ) {
    showMessage(context, theme, theme.textOf(text));
  }

  static void showMessage(
    BuildContext context,
    LocationPickerTheme theme,
    String message,
  ) {
    final current = _current;
    if (current != null) {
      toastification.dismiss(current);
    }
    toastification.dismissAll(delayForAnimation: false);
    _current = toastification.show(
      context: context,
      title: LocationPickerToastTitle(
        message: message,
        fontFamily: theme.fontOf(),
      ),
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      alignment: Alignment.topCenter,
      direction: theme.textDirection,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}

class LocationPickerToastTitle extends StatelessWidget {
  const LocationPickerToastTitle({
    super.key,
    required this.message,
    required this.fontFamily,
  });

  final String message;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      maxLines: 3,
      style: TextStyle(fontFamily: fontFamily),
    );
  }
}
