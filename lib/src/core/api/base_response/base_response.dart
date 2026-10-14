/// Backend envelope: `{ success|status, message, data }`.
///
/// When the body is the payload itself, [data] is parsed from that body.
class BaseResponse<T> {
  final bool? success;
  final String? message;
  final T? data;

  const BaseResponse({
    this.success,
    this.message,
    this.data,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final raw = json['data'];
    final Map<String, dynamic>? payload = raw is Map
        ? Map<String, dynamic>.from(raw)
        : json.containsKey('data')
            ? null
            : json;

    return BaseResponse<T>(
      success: json['success'] is bool
          ? json['success'] as bool
          : json['status'] is bool
              ? json['status'] as bool
              : null,
      message: (json['message'] ?? json['Message'])?.toString(),
      data: payload == null ? null : fromJsonT(payload),
    );
  }
}
