# Plan: use the location picker without Flutter Bloc

Status: plan only. No package code changes in this step.

Branch: `docs/state-free-location-picker`

## What this fixes

`MdSoftGoogleMapUserPickLocationFromScroll` works only through `GoogleMapCubit` and `flutter_bloc`. The widget creates a `BlocProvider`, and search, the places list, the map, and the current-location button all rebuild with `BlocBuilder` / `BlocConsumer`.

A host app that uses `setState`, Provider, Riverpod, GetX, or no state library still has to depend on `flutter_bloc`, because the package exports the cubit and cannot run without it.

The package should own its screen state. Any Flutter app can drop in the same widget and read the picked place from the existing `selectedPlace` callback. The host does not supply a cubit, and the package does not read the host's state.

## Current coupling

| Piece | Where | Why it blocks other apps |
| --- | --- | --- |
| `BlocProvider` + `BlocConsumer` | `lib/google_map_routing.dart` | Screen cannot build without Bloc |
| `BlocBuilder` | search field and places list | UI updates only when a cubit state is emitted |
| `GoogleMapCubit` passed into child widgets | map, search, current-location button | Every child imports Bloc types |
| Public export of `google_map_cubit.dart` | `lib/google_map_routing.dart` | Host code is invited to depend on the cubit |
| `flutter_bloc: ^9.1.1` | `pubspec.yaml` | Required dependency for every consumer |

The cubit also holds the real data as normal fields (`markers`, `predictions`, `selectedLocation`, `locationName`, `polygon`, `mapState`). Emitted classes such as `GetLocationSuccessState` are mostly rebuild signals. That logic can move to a controller that calls `notifyListeners()` instead of `emit()`.

## Target shape

Keep one public widget and one result callback. Replace the cubit with a package-owned controller built on Flutter's `ChangeNotifier`.

```dart
MdSoftGoogleMapUserPickLocationFromScroll(
  internal: false,
  isStart: true,
  mapStyle: 'assets/json/map_style.json',
  selectedPlace: (place) {
    // place.selectedLocation, place.pointName
  },
)
```

Optional, for an app that wants to move the camera or clear search from its own button:

```dart
final picker = LocationPickerController();

MdSoftGoogleMapUserPickLocationFromScroll(
  controller: picker,
  internal: true,
  selectedPlace: (place) {},
)
```

If `controller` is omitted, the widget creates and disposes its own controller. The host never has to know about Bloc.

Inside the package:

- `LocationPickerController extends ChangeNotifier` holds the fields that live on `GoogleMapCubit` today.
- `ListenableBuilder` replaces `BlocBuilder` and `BlocConsumer`.
- Errors call the existing toast helper from the widget listener, using a small `LocationPickerNotice` (message only), instead of `GetLocationErrorState` and the other error states.
- `flutter_bloc` is removed from `dependencies`.
- `GoogleMapCubit` and `GoogleMapState` are deleted after the move. The example app does not import them.

## Behavior that stays the same

- Search debounce (150 ms) and place predictions.
- Place details, then camera move to that place.
- OSM reverse geocode for the name under the pin, including the 600 ms debounce and the one-request-per-second queue.
- Internal trip must stay inside the governorate polygon. External destination must stay outside it. Start point on an external trip skips that check.
- Loading overlay while location or governorate data is loading.
- Current-location button, custom map style, Arabic layout, confirm button text `تثبيت النقطة`.
- `MdUserPickLocationGoogleMapConfig.initialize` stays the setup entry.

## Work order

1. Add `lib/src/controller/location_picker_controller.dart`.
   Move methods from `GoogleMapCubit` without changing their rules: location, map style, markers, predictions, place details, polygon check, governorates, OSM name lookup.
   Replace every `emit(...)` with `notifyListeners()`.
   Guard with a disposed flag the same way the cubit guards `isClosed`.
2. Add `lib/src/controller/location_picker_notice.dart` for error text the widget shows in a toast. Success paths only notify listeners.
3. Change `MdSoftGoogleMapUserPickLocationFromScroll` to own the controller with `ListenableBuilder`.
   Pass the controller into `GoogleMapWidget`, `SearchTextFormFeild`, `PlacesListWidget`, and `UserFloatingActionButton`.
   Remove `flutter_bloc` imports from `lib/google_map_routing.dart`.
4. Stop exporting `google_map_cubit.dart`. Export the controller only if apps need the optional handle.
5. Delete `lib/src/cubit/google_map_cubit.dart` and `lib/src/cubit/google_map_state.dart`.
6. Remove `flutter_bloc` from `pubspec.yaml`. Run `flutter pub get` in the package and in `example/`.
7. Update `CHANGELOG.md` and the README usage section: the widget callback is enough; Bloc is not required.
8. Bump the package version. This drops a public export (`GoogleMapCubit`), so the next version is `0.1.0`.

## Files

| File | Action |
| --- | --- |
| `lib/src/controller/location_picker_controller.dart` | Add. Logic moved from the cubit |
| `lib/src/controller/location_picker_notice.dart` | Add. Error message for toasts |
| `lib/google_map_routing.dart` | Swap Bloc widgets for `ListenableBuilder` |
| `lib/src/cubit/google_map_cubit.dart` | Delete after the move |
| `lib/src/cubit/google_map_state.dart` | Delete after the move |
| `pubspec.yaml` | Remove `flutter_bloc` |
| `example/lib/main.dart` | Keep the same widget usage; confirm it still compiles |
| `README.md`, `CHANGELOG.md` | Document the callback-only usage |

Repositories, models, `LocationService`, and `MdUserPickLocationGoogleMapConfig` stay as they are.

## Checks before calling it done

- Example app: open the map, scroll the pin, confirm a point, and read `selectedPlace`.
- Search a place name, tap a prediction, and see the camera move.
- `internal: true` rejects a point outside the polygon. `internal: false` with `isStart: false` rejects a point inside it.
- Deny location permission and confirm the toast still appears.
- `flutter analyze` on the package and the example, with no `flutter_bloc` import left under `lib/`.

## Out of scope

- No new state package (Provider, Riverpod, GetX) inside this package.
- No change to polygon math, OSM calls, or the Google Places repository.
- No second public widget. One widget, optional controller.
