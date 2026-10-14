import 'package:dio/dio.dart';

abstract class Failure implements Exception {
  final String message;

  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);

  factory ServerFailure.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure('انتهت مهلة الاتصال بالخادم');
      case DioExceptionType.sendTimeout:
        return ServerFailure('انتهت مهلة إرسال الطلب');
      case DioExceptionType.receiveTimeout:
        return ServerFailure('انتهت مهلة استلام الرد');
      case DioExceptionType.badCertificate:
        return ServerFailure('شهادة الاتصال غير صالحة');
      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
            e.response!.statusCode!, e.response?.data!);
      case DioExceptionType.cancel:
        return ServerFailure('تم إلغاء الطلب');
      case DioExceptionType.connectionError:
        return ServerFailure('لا يوجد اتصال بالإنترنت');
      case DioExceptionType.unknown:
        ServerFailure('Unknown error: ${e.message}');
        if (e.error != null) {
          ServerFailure('Error details: ${e.error}');
        }
        return ServerFailure('حدث خطأ، يرجى المحاولة مرة أخرى');
      case DioExceptionType.transformTimeout:
        return ServerFailure('انتهت مهلة معالجة البيانات');
    }
  }

  factory ServerFailure.fromResponse(int statusCode, dynamic response) {
    if (statusCode == 404) {
      return ServerFailure('لم يتم العثور على الطلب، يرجى المحاولة لاحقاً');
    } else if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 406 ||
        statusCode == 500) {
      return ServerFailure(
          response['Message'] ?? response['message'] ?? response['error']);
    } else {
      return ServerFailure('حدث خطأ، يرجى المحاولة مرة أخرى');
    }
  }
}
