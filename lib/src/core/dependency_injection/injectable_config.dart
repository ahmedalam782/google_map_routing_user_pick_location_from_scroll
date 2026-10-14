import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injectable_config.config.dart';

/// Container for this package. It is not the app's [GetIt.instance], so
/// registering Dio here does not replace the host app's Dio.
final GetIt getIt = GetIt.asNewInstance();

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() {
  if (getIt.isRegistered<Dio>()) return;
  getIt.init();
}
