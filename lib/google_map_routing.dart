import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../src/models/md_on_user_selcted_place.dart';
import '../src/cubit/google_map_cubit.dart';
import '../src/utils/app_images.dart';
import '../src/utils/constants.dart';
import '../src/services/toastification_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../src/widgets/custom_button.dart';
import '../src/widgets/places_shimmer.dart';
import '../src/widgets/custom_textformfield.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
export '../src/cubit/google_map_cubit.dart';
export '../src/repositories/google_map_repo_impl.dart';
export '../src/services/location_service.dart';
export '../src/utils/constants.dart';
export '../src/utils/app_images.dart';

class MdSoftGoogleMapUserPickLocationFromScroll extends StatelessWidget {
  final String? mapStyle;
  final bool isUser;
  final LatLng? startLocation;
  final bool internal;
  final bool isStart;
  final LatLng? oldLocation;

  final void Function(MdOnUserSelectedPlace) selectedPlace;

  const MdSoftGoogleMapUserPickLocationFromScroll({
    super.key,
    this.startLocation,
    this.mapStyle,
    this.isUser = false,
    required this.internal,
    required this.selectedPlace,
    this.isStart = true,
    this.oldLocation,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    return BlocProvider(
      create: (context) => GoogleMapCubit(),
      child: BlocConsumer<GoogleMapCubit, GoogleMapState>(
        listener: (context, state) {
          if (state is GetLocationErrorState) {
            showToastificationWidget(
              message: state.errorMessage,
              context: context,
            );
          }
          if (state is GetPlaceDetailsErrorState) {
            showToastificationWidget(
              message: state.errorMessage,
              context: context,
            );
          }
          if (state is OutsideIraqState) {
            showToastificationWidget(
              message: 'يرجى اختيار موقع داخل العراق',
              context: context,
            );
          }
          if (state is GetGovernoratesErrorState) {
            showToastificationWidget(
              message: state.errorMessage,
              context: context,
            );
          }
        },
        builder: (context, state) {
          var cubit = context.read<GoogleMapCubit>();
          var bottomPadding = MediaQuery.viewInsetsOf(context).bottom > 0
              ? MediaQuery.viewInsetsOf(context).bottom
              : 16.0;
          return ModalProgressHUD(
            inAsyncCall: cubit.mapState == MapState.loading,
            color: Colors.white,
            opacity: 0.5,
            progressIndicator: Center(
                child: CircularProgressIndicator(
              color: MdUserPickLocationGoogleMapConfig.primaryColor,
            )),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: Stack(
                  children: [
                    GoogleMapWidget(
                      internal: internal,
                      startLocation: startLocation,
                      isUser: isUser,
                      cubit: cubit,
                      mapStyle: mapStyle,
                      isStart: isStart,
                      oldLocation: oldLocation,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 16,
                        end: 16,
                        top: 16,
                      ),
                      child: SearchTextFormFeild(
                        width: width,
                        internal: internal,
                        cubit: cubit,
                      ),
                    ),
                    Center(
                      child: IgnorePointer(
                        child: Image.asset(
                            isStart ? AppImages.point : AppImages.endLocation),
                      ),
                    ),
                    if (cubit.isLoadingPredictions ||
                        cubit.predictions.isNotEmpty)
                      Positioned(
                        top: 76,
                        right: 16,
                        left: 16,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                          ),
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.96),
                            elevation: 4,
                            shadowColor: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: PlacesListWidget(
                              internal: internal,
                              isStart: isStart,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Padding(
                padding:
                    EdgeInsets.only(bottom: bottomPadding, right: 16, left: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isPhone) ...[
                      ZoomButton(
                        icon: Icons.add,
                        onPressed: () => cubit.googleMapController
                            ?.animateCamera(CameraUpdate.zoomIn()),
                      ),
                      const SizedBox(height: 10),
                      ZoomButton(
                        icon: Icons.remove,
                        onPressed: () => cubit.googleMapController
                            ?.animateCamera(CameraUpdate.zoomOut()),
                      ),
                      const SizedBox(height: 10),
                    ],
                    UserFloatingActionButton(
                        bottomPadding: bottomPadding, cubit: cubit),
                    const SizedBox(height: 10),
                    CustomButton(
                        onTap: () async {
                          final loc = cubit.selectedLocation;
                          if (loc == null) return;
                          final inIraq =
                              cubit.isInIraq ?? cubit.isPointInIraqSync(loc);
                          if (!inIraq) {
                            showToastificationWidget(
                              message: 'يرجى اختيار موقع داخل العراق',
                              context: context,
                            );
                            return;
                          }
                          if (internal) {
                            if (cubit.regionModel != null &&
                                !cubit.chackInternalOrNot(loc)) {
                              showToastificationWidget(
                                message:
                                    'يرجى اختيار موقع داخل الحدود المحددة، حيث أن هذه رحلة داخلية',
                                context: context,
                              );
                              return;
                            }
                          } else if (!isStart) {
                            if (cubit.regionModel != null &&
                                cubit.chackInternalOrNot(loc)) {
                              showToastificationWidget(
                                message:
                                    'يرجى اختيار موقع خارج الحدود المحددة، حيث أن هذه رحلة خارجية',
                                context: context,
                              );
                              return;
                            }
                          }
                          if (cubit.isResolvingPlaceName ||
                              (cubit.locationName == null ||
                                  cubit.locationName!.trim().isEmpty)) {
                            await cubit.ensurePlaceResolved().timeout(
                                  const Duration(milliseconds: 900),
                                  onTimeout: () {},
                                );
                          }
                          final finalLoc = cubit.selectedLocation ?? loc;
                          final finalName =
                              (cubit.locationName?.trim().isNotEmpty == true)
                                  ? cubit.locationName!.trim()
                                  : (cubit.searchController.text
                                          .trim()
                                          .isNotEmpty
                                      ? cubit.searchController.text.trim()
                                      : 'موقع على الخريطة');
                          selectedPlace.call(MdOnUserSelectedPlace(
                            selectedLocation: finalLoc,
                            pointName: finalName,
                          ));
                        },
                        text: 'تثبيت النقطة'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Phones have pinch-to-zoom, so the zoom buttons are only for web/desktop.
bool get _isPhone =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class ZoomButton extends StatelessWidget {
  const ZoomButton({super.key, required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        side: BorderSide(color: Colors.transparent),
      ),
      elevation: 1,
      backgroundColor: Colors.white,
      onPressed: onPressed,
      child: Icon(icon, color: MdUserPickLocationGoogleMapConfig.primaryColor),
    );
  }
}

class UserFloatingActionButton extends StatelessWidget {
  const UserFloatingActionButton({
    super.key,
    required this.bottomPadding,
    required this.cubit,
  });
  final double bottomPadding;
  final GoogleMapCubit cubit;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        side: BorderSide(color: Colors.transparent),
      ),
      elevation: 1,
      backgroundColor: Colors.white,
      onPressed: () {
        final target = cubit.currentLocationLatLang ?? cubit.selectedLocation;
        if (target == null) return;
        cubit.googleMapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 16,
          ),
        ));
        if (cubit.currentLocationLatLang != null) {
          cubit.updateCurrentLocationMarker();
        }
      },
      child: SizedBox(
        height: 46,
        width: 46,
        child: Icon(
          Icons.location_searching,
          weight: 24,
          color: MdUserPickLocationGoogleMapConfig.primaryColor,
        ),
      ),
    );
  }
}

class SearchTextFormFeild extends StatelessWidget {
  const SearchTextFormFeild({
    super.key,
    required this.width,
    required this.cubit,
    this.internal = false,
    this.index = 0,
  });

  final double width;
  final bool internal;
  final GoogleMapCubit cubit;
  final int index;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoogleMapCubit, GoogleMapState>(
      builder: (context, state) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: cubit.searchController,
          builder: (context, value, _) {
            final hasText = value.text.isNotEmpty;
            final isResolving = cubit.isResolvingPlaceName &&
                !cubit.searchFocusNode.hasFocus &&
                !hasText;
            return SizedBox(
              width: double.infinity,
              child: CustomTextFormFeild(
                focusNode: cubit.searchFocusNode,
                controller: cubit.searchController,
                haveShadow: true,
                label: isResolving
                    ? 'جاري تحديد العنوان ...'
                    : 'الى اين تود الذهاب؟...',
                onTap: () {
                  if (cubit.searchController.text.isNotEmpty &&
                      cubit.searchController.text == cubit.locationName) {
                    cubit.searchController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: cubit.searchController.text.length,
                    );
                  }
                },
                onChange: (val) => cubit.onSearchChanged(val),
                prefixIcon: isResolving
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : SvgPicture.asset(
                        AppImages.search,
                        height: 20,
                        width: 20,
                        fit: BoxFit.scaleDown,
                      ),
                suffixIconButton: hasText
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xff606060),
                        ),
                        onPressed: () {
                          cubit.clear();
                          cubit.searchFocusNode.requestFocus();
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class PlacesListWidget extends StatelessWidget {
  final bool internal;
  final bool isStart;
  const PlacesListWidget({
    super.key,
    required this.internal,
    required this.isStart,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoogleMapCubit, GoogleMapState>(
      builder: (context, state) {
        var cubit = context.read<GoogleMapCubit>();
        if (cubit.isLoadingPredictions && cubit.predictions.isEmpty) {
          return const PlacesShimmer();
        }
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: cubit.predictions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 0.6,
            color: Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final prediction = cubit.predictions[index];
            final mainText =
                prediction.structuredFormatting?.mainText?.trim() ??
                    prediction.description ??
                    '';
            final secondaryText =
                prediction.structuredFormatting?.secondaryText?.trim();
            return Material(
              type: MaterialType.transparency,
              child: ListTile(
                dense: true,
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  await cubit.getPlaceDetails(
                    placeId: prediction.placeId!,
                    fallbackTitle: prediction.description ?? mainText,
                    internal: internal,
                    isStart: isStart,
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: SvgPicture.asset(
                  AppImages.clock,
                  height: 20,
                  width: 20,
                  fit: BoxFit.scaleDown,
                ),
                title: Text(
                  mainText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff242021),
                    fontFamily: MdUserPickLocationGoogleMapConfig.fontFamily,
                  ),
                ),
                subtitle: (secondaryText != null && secondaryText.isNotEmpty)
                    ? Text(
                        secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: const Color(0xff606060),
                          fontFamily:
                              MdUserPickLocationGoogleMapConfig.fontFamily,
                        ),
                      )
                    : null,
                trailing: SvgPicture.asset(
                  AppImages.frame,
                  height: 20,
                  width: 20,
                  fit: BoxFit.scaleDown,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({
    super.key,
    required this.cubit,
    required this.mapStyle,
    required this.isUser,
    required this.startLocation,
    required this.internal,
    this.isStart = true,
    this.oldLocation,
  });
  final bool isUser;
  final bool internal;
  final GoogleMapCubit cubit;
  final String? mapStyle;
  final LatLng? startLocation;
  final bool isStart;
  final LatLng? oldLocation;

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  late LatLng location = widget.oldLocation ??
      widget.startLocation ??
      const LatLng(33.3152, 44.3661);
  bool _hasMovedCamera = false;

  @override
  Widget build(BuildContext context) {
    final initialTarget = widget.oldLocation ??
        widget.startLocation ??
        widget.cubit.selectedLocation ??
        const LatLng(33.3152, 44.3661);
    final initialZoom = (!widget.internal && !widget.isStart) ? 9.0 : 16.0;

    return GoogleMap(
      markers: widget.cubit.markers,
      polylines: widget.cubit.polyLines,
      polygons: widget.cubit.polygon,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      rotateGesturesEnabled: false,
      compassEnabled: false,
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: initialZoom,
      ),
      myLocationEnabled: false,
      onCameraMove: (position) {
        _hasMovedCamera = true;
        location = position.target;
        widget.cubit.selectedLocation = location;
        widget.cubit.isInIraq = widget.cubit.isPointInIraqSync(location);
      },
      onCameraIdle: () {
        if (!_hasMovedCamera && widget.cubit.selectedLocation == null) {
          return;
        }
        final target = _hasMovedCamera
            ? location
            : (widget.cubit.selectedLocation ?? location);
        widget.cubit.selectedLocation = target;
        widget.cubit.isInIraq = widget.cubit.isPointInIraqSync(target);

        if (widget.cubit.isNextCameraIdleFromSearch) {
          widget.cubit.isNextCameraIdleFromSearch = false;
          return;
        }

        if (widget.internal) {
          if (widget.cubit.regionModel == null) {
            widget.cubit.selectedPlaceName(target);
            return;
          }

          bool inSide = widget.cubit.chackInternalOrNot(target);
          if (inSide) {
            widget.cubit.selectedPlaceName(target);
          } else {
            showToastificationWidget(
              message:
                  'يرجى اختيار موقع داخل الحدود المحددة، حيث أن هذه رحلة داخلية',
              context: context,
            );
          }
        } else {
          if (widget.isStart) {
            widget.cubit.selectedPlaceName(target);
            return;
          }
          if (widget.cubit.regionModel == null) {
            widget.cubit.selectedPlaceName(target);
            return;
          }
          bool inSide = widget.cubit.chackInternalOrNot(target);
          if (inSide) {
            showToastificationWidget(
              message:
                  'يرجى اختيار موقع خارج الحدود المحددة، حيث أن هذه رحلة خارجية',
              context: context,
            );
          } else {
            widget.cubit.selectedPlaceName(target);
          }
        }
      },
      onMapCreated: (GoogleMapController controller) async {
        widget.cubit.googleMapController = controller;
        if (widget.mapStyle != null) {
          unawaited(widget.cubit.getMapStyle(mapStyle: widget.mapStyle!));
        }

        if (widget.cubit.regionModel == null &&
            (widget.startLocation != null || widget.oldLocation != null)) {
          unawaited(
            widget.cubit.getGovernorates(
              startLocation: widget.startLocation ?? widget.oldLocation,
              internal: widget.internal,
              isStart: widget.isStart,
            ),
          );
        }

        await widget.cubit.getLocationMyCurrentLocation(
          startLocation: widget.startLocation,
          isStart: widget.isStart,
          internal: widget.internal,
          oldLocation: widget.oldLocation,
        );

        if (widget.cubit.regionModel == null) {
          unawaited(
            widget.cubit.getGovernorates(
              startLocation: widget.startLocation,
              internal: widget.internal,
              isStart: widget.isStart,
            ),
          );
        }
      },
    );
  }
}
