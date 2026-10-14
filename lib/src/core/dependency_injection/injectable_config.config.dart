// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../api/google_map_api.dart' as _i267;
import '../../data/repositories/google_map_repo_impl.dart' as _i1056;
import '../../data/services/location_service.dart' as _i211;
import '../../domain/repositories/google_map_repo.dart' as _i220;
import '../../presentation/controller/location_picker_controller.dart'
    as _i1008;
import '../../presentation/theme/location_picker_theme.dart' as _i435;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.factory<_i211.LocationService>(() => _i211.LocationService());
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio());
    gh.factory<_i267.GoogleMapApi>(() => _i267.GoogleMapApi(gh<_i361.Dio>()));
    gh.factory<_i220.GoogleMapRepo>(
        () => _i1056.GoogleMapRepoImpl(api: gh<_i267.GoogleMapApi>()));
    gh.factoryParam<_i1008.LocationPickerController, _i435.LocationPickerTheme?,
        dynamic>((
      theme,
      _,
    ) =>
        _i1008.LocationPickerController(
          gh<_i220.GoogleMapRepo>(),
          gh<_i211.LocationService>(),
          theme: theme,
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
