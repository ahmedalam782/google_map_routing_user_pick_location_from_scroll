import '../theme/location_picker_text.dart';

/// Something the location picker wants to tell the user.
///
/// [text] is a sentence the theme can translate. [rawMessage] is a message
/// that came from the server and is shown as-is.
class LocationPickerNotice {
  const LocationPickerNotice({
    required this.id,
    this.text,
    this.detail,
    this.rawMessage,
  });

  final int id;
  final LocationPickerText? text;
  final String? detail;
  final String? rawMessage;
}
