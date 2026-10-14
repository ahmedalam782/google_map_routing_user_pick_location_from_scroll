import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/failure.dart';
import 'base_response/result.dart';

Future<Result<T>> executeApi<T>(Future<T> Function() apiCall) async {
  try {
    final result = await apiCall();
    return Success<T>(data: result);
  } on DioException catch (ex, stackTrace) {
    if (ex.type == DioExceptionType.cancel) {
      return Cancelled<T>();
    }
    if (kDebugMode) {
      debugPrint('DioException caught: $ex\n$stackTrace');
    }
    return Error<T>(exception: ServerFailure.fromDioError(ex));
  } on Failure catch (ex) {
    return Error<T>(exception: ex);
  } catch (ex, stackTrace) {
    if (kDebugMode) {
      debugPrint('Unexpected error: $ex\n$stackTrace');
    }
    return Error<T>(exception: ServerFailure(ex.toString()));
  }
}
