import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

String? _currentMessage;
ToastificationItem? _currentToast;

void _clearCurrentToast(ToastificationItem item) {
  if (_currentToast == item) {
    _currentMessage = null;
    _currentToast = null;
  }
}

void showToastificationWidget({
  required String message,
  required BuildContext context,
  ToastificationType notificationType = ToastificationType.error,
  int duration = 3,
}) {
  if (_currentMessage == message && _currentToast != null) {
    return;
  }

  _currentMessage = message;

  if (_currentToast != null) {
    toastification.dismiss(_currentToast!);
  }
  toastification.dismissAll(delayForAnimation: false);

  _currentToast = toastification.show(
    context: context,
    title: Text(
      textAlign: TextAlign.center,
      message,
      maxLines: 3,
    ),
    type: notificationType,
    style: ToastificationStyle.flat,
    alignment: Alignment.topCenter,
    direction: TextDirection.rtl,
    autoCloseDuration: Duration(seconds: duration),
    callbacks: ToastificationCallbacks(
      onAutoCompleteCompleted: _clearCurrentToast,
      onDismissed: _clearCurrentToast,
      onCloseButtonTap: _clearCurrentToast,
    ),
  );
}

void dismissToastificationWidget() {
  _currentMessage = null;
  if (_currentToast != null) {
    toastification.dismiss(_currentToast!);
    _currentToast = null;
  }
  toastification.dismissAll(delayForAnimation: false);
}
