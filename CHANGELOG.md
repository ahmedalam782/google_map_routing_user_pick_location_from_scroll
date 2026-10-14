
# [0.1.0] - 2026-10-14

## Changed

- The location picker keeps its own state with Flutter `ChangeNotifier`. A host app can use the widget without `flutter_bloc`, Provider, Riverpod, or GetX.
- Removed `GoogleMapCubit`. Pass an optional `LocationPickerController` when the host needs to move the camera or clear search. If it is omitted, the widget creates and disposes one.
- Added `LocationPickerTheme`. Override any sentence with `LocationPickerText`, any color with `LocationPickerColorRole` (including icon color), and any image with `LocationPickerIconRole`. Unset values stay on the package defaults.
- Each picture accepts a Flutter icon, a PNG, a JPG, or an SVG asset through `LocationPickerGraphic`. Omit it to keep the package image.
- Default picker sentences and connection errors are Arabic. Replace any sentence later with `LocationPickerTheme.textOverrides`.
- Split the package into core, API, data, domain, and presentation. `RegisterModule` registers Dio and the API client, and injectable wires the repository, location service, and controller.
- API calls return `Result` (`Success`, `Error`, `Cancelled`). The governorate call is read through `BaseResponse`. `dartz` is no longer required.
- Pass `MdUserPickLocationGoogleMapConfig` on the picker screen. `copyWith` changes one value there. `main` no longer calls `initialize`.
- Removed the unused plugin stub and its packages: `web`, `flutter_web_plugins`, and `plugin_platform_interface`.
- The screen config chooses the governorate address and whether that search runs. `searchGovernorate: false` skips the call. `governorateEndpoint` can be a path or a full URL.

# [0.0.4] - 2025-5-26

## ✨ Added Polygon support

- 🛣️ **Polygon support**: Added support for drawing polygons on the map, with the ability to define multiple points for both internal and external polygons.

# [0.0.2] - 2025-04-15

## ✨ Added

- 🛣️ **Waypoints support**: Define multiple stop points along the route for more complex navigation flows.
- 🏷️ **Points naming**: Introduced `pointsName` parameter to easily label and identify each location.
- 📄 **Example usage**: Included a simple yet complete usage example in the README for quick integration.

## [0.0.1] - 2025-04-14

### Initial Release

- 🚀 Real-time location tracking: Live updates of the user's current position.
- 🔄 Background service: Keeps tracking location even when the app is in the background.
- 🧭 Route calculation: Calculates and displays the best route between two points.
- 🎨 Customizable map styles: Support for dark mode and other custom themes.
- 📍 Destination reached notification: Informs the user upon reaching their destination.
- 🧊 Smooth animations: Animated camera movements and marker transitions.
