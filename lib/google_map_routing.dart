import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'md_user_pick_location_google_map_config.dart';
import 'src/core/dependency_injection/injectable_config.dart';
import 'src/domain/entities/md_on_user_selcted_place.dart';
import 'src/presentation/controller/location_picker_controller.dart';
import 'src/presentation/controller/location_picker_notice.dart';
import 'src/presentation/theme/location_picker_theme.dart';
import 'src/presentation/widgets/location_picker_screen.dart';
import 'src/presentation/widgets/location_picker_toast.dart';

class MdSoftGoogleMapUserPickLocationFromScroll extends StatefulWidget {
  final String? mapStyle;
  final bool isUser;
  final LatLng? startLocation;
  final bool? internal;
  final bool isStart;
  final LatLng? oldLocation;
  final LocationPickerController? controller;
  final LocationPickerTheme theme;
  final MdUserPickLocationGoogleMapConfig? config;

  final void Function(MdOnUserSelectedPlace)? selectedPlace;

  const MdSoftGoogleMapUserPickLocationFromScroll({
    super.key,
    this.startLocation,
    this.mapStyle,
    this.isUser = false,
    required this.internal,
    required this.selectedPlace,
    this.isStart = true,
    this.oldLocation,
    this.controller,
    this.theme = const LocationPickerTheme(),
    required this.config,
  });

  @override
  State<MdSoftGoogleMapUserPickLocationFromScroll> createState() =>
      _MdSoftGoogleMapUserPickLocationFromScrollState();
}

class _MdSoftGoogleMapUserPickLocationFromScrollState
    extends State<MdSoftGoogleMapUserPickLocationFromScroll> {
  LocationPickerController? _ownedController;
  int _lastNoticeId = 0;

  LocationPickerController get _controller =>
      widget.controller ?? _ownedController!;

  void _applyConfig() {
    (widget.config ??
            const MdUserPickLocationGoogleMapConfig(
              apiKey: null,
              baseUrl: null,
              searchGovernorate: false,
            ))
        .apply();
  }

  LocationPickerController _newController() {
    configureDependencies();
    return getIt<LocationPickerController>(param1: widget.theme);
  }

  @override
  void initState() {
    super.initState();
    _applyConfig();
    if (widget.controller == null) {
      _ownedController = _newController();
    } else {
      widget.controller!.theme = widget.theme;
    }
    _controller.addListener(_onNotice);
  }

  @override
  void didUpdateWidget(
    covariant MdSoftGoogleMapUserPickLocationFromScroll oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _applyConfig();
    }
    if (oldWidget.controller != widget.controller) {
      _swapController(oldWidget);
    }
    if (widget.theme != _controller.theme) {
      _controller.applyTheme(widget.theme);
    }
  }

  void _swapController(MdSoftGoogleMapUserPickLocationFromScroll oldWidget) {
    final previousOwned = _ownedController;
    (oldWidget.controller ?? previousOwned)?.removeListener(_onNotice);
    if (widget.controller != null) {
      _ownedController = null;
      if (previousOwned != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          previousOwned.dispose();
        });
      }
    } else {
      _ownedController ??= _newController();
    }
    _controller.addListener(_onNotice);
  }

  void _onNotice() {
    final notice = _controller.notice;
    if (notice == null || notice.id == _lastNoticeId) return;
    _lastNoticeId = notice.id;
    final message = _messageFor(notice);
    final theme = widget.theme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      LocationPickerToast.showMessage(context, theme, message);
    });
  }

  String _messageFor(LocationPickerNotice notice) {
    final text = notice.text;
    if (text == null) return notice.rawMessage ?? '';
    return widget.theme.textOf(text, detail: notice.detail);
  }

  @override
  void dispose() {
    _controller.removeListener(_onNotice);
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LocationPickerScreen(
          controller: _controller,
          width: width,
          internal: widget.internal ?? false,
          isStart: widget.isStart,
          mapStyle: widget.mapStyle,
          startLocation: widget.startLocation,
          oldLocation: widget.oldLocation,
          onSelected: widget.selectedPlace ?? (_) {},
        );
      },
    );
  }
}
