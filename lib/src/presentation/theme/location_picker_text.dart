/// Every user-facing sentence in the location picker.
///
/// The widget asks the theme for a sentence by this name. It does not keep
/// its own copies of the words.
enum LocationPickerText {
  searchHint,
  confirmPoint,
  insideBoundary,
  outsideBoundary,
  waitForRegion,
  locationServiceDisabled,
  locationPermissionDenied,
  locationFailed,
  unexpectedLocationError,
  pickerClosed,
  unknownPlace,
}

/// Arabic sentences shipped with the package.
///
/// A host app replaces any sentence through [LocationPickerTheme.textOverrides]
/// and leaves the rest on these defaults.
mixin LocationPickerDefaultCopy {
  static const Map<LocationPickerText, String> values = {
    LocationPickerText.searchHint: 'الى اين تود الذهاب؟...',
    LocationPickerText.confirmPoint: 'تثبيت النقطة',
    LocationPickerText.insideBoundary:
        'يرجى اختيار موقع داخل الحدود المحددة، حيث أن هذه رحلة داخلية',
    LocationPickerText.outsideBoundary:
        'يرجى اختيار موقع خارج الحدود المحددة، حيث أن هذه رحلة خارجية',
    LocationPickerText.waitForRegion: 'الرجاء الانتظار لتحميل بيانات المنطقة',
    LocationPickerText.locationServiceDisabled:
        'يرجى التحقق من تشغيل خدمة الموقع',
    LocationPickerText.locationPermissionDenied:
        'يرجى السماح بالوصول إلى الموقع',
    LocationPickerText.locationFailed: 'فشل تحديد الموقع: {detail}',
    LocationPickerText.unexpectedLocationError:
        'حدث خطأ غير متوقع أثناء تحديد الموقع.',
    LocationPickerText.pickerClosed: 'تم إغلاق اختيار الموقع.',
    LocationPickerText.unknownPlace: 'غير معروف',
  };

  static String of(LocationPickerText text) => values[text]!;
}

/// Turns a [LocationPickerText] into the sentence the user should read.
mixin LocationPickerCopyResolver {
  Map<LocationPickerText, String> get textOverrides;

  String textOf(LocationPickerText text, {String? detail}) {
    final raw = textOverrides[text] ?? LocationPickerDefaultCopy.of(text);
    if (!raw.contains('{detail}')) return raw;
    return raw.replaceAll('{detail}', detail ?? '');
  }
}
