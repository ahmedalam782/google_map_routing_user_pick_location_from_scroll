# Use the location picker

Status: ready to call from a screen. Version `0.1.0`.

Branch: `docs/state-free-location-picker`

Platforms: Android, iOS, and web. The map plugin does not run on Windows, macOS, or Linux.

The package owns the screen state with `ChangeNotifier`. The host does not add Bloc, Provider, Riverpod, or GetX. Do not call a setup method from `main`.

## Imports

```dart
import 'package:mdsoft_google_map_user_pick_location_from_scroll/google_map_routing.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';
```

## Screen

Put this on the page that opens the map. `config`, `internal`, and `selectedPlace` are required, and each one may be null.

```dart
MdSoftGoogleMapUserPickLocationFromScroll(
  config: const MdUserPickLocationGoogleMapConfig(
    apiKey: 'YOUR_API_KEY',
    baseUrl: 'https://your-server/api/',
    searchGovernorate: true,
    governorateEndpoint: 'governorates/me',
  ).copyWith(fontFamily: 'Hanimation Arabic'),
  internal: false,
  isStart: true,
  mapStyle: 'assets/json/map_style.json',
  startLocation: const LatLng(35.1772740409823, 45.98494988507281),
  selectedPlace: (place) {
    // place.selectedLocation, place.pointName
  },
)
```

`copyWith` changes one value on that screen. A path in `governorateEndpoint` is joined to `baseUrl`. A value that starts with `http` is the full address.

```dart
config: const MdUserPickLocationGoogleMapConfig(
  apiKey: 'YOUR_API_KEY',
  baseUrl: 'https://your-server/api/',
).copyWith(
  governorateEndpoint: 'https://other-server/api/regions/current',
  governorateLatitudeQuery: 'lat',
  governorateLongitudeQuery: 'lng',
)
```

Turn the governorate request off when this screen should save the pin with no polygon:

```dart
config: const MdUserPickLocationGoogleMapConfig(
  apiKey: 'YOUR_API_KEY',
  baseUrl: null,
  searchGovernorate: false,
)
```

Pass null when this screen has nothing to send. A null `config` skips the governorate request. A null `internal` is treated as `false`. A null `selectedPlace` does nothing on confirm.

```dart
MdSoftGoogleMapUserPickLocationFromScroll(
  config: null,
  internal: null,
  selectedPlace: null,
)
```

## What the screen does

- Search waits 150 ms, then loads place predictions.
- A picked place moves the camera there.
- The name under the pin comes from OpenStreetMap, with a 600 ms wait and one request per second.
- `searchGovernorate: true` loads the region. `internal: true` keeps the point inside that polygon. `internal: false` with `isStart: false` keeps the point outside it. `isStart: true` skips that check.
- `searchGovernorate: false` does not call the region URL. Confirm saves the pin.
- The loading overlay stays up while location or the region is loading.
- Default sentences are Arabic. Confirm says `تثبيت النقطة`.

## Host project

- Android and iOS: Maps key and location permission in the native project.
- Web: Google Maps JavaScript script in `web/index.html`, and location permission in the browser.
- `main` only starts the app. The key and the server belong on the picker screen.
