import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// Registers [Dio] for the package API clients.
@module
abstract class RegisterModule {
  @lazySingleton
  Dio dio() => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          followRedirects: false,
        ),
      );
}
