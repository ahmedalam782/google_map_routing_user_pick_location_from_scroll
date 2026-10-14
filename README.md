# mdsoft_google_map_user_pick_location_from_scroll 🗺️

A powerful Flutter package that allows users to pick locations on Google Maps and create routes with multiple waypoints. Perfect for ride-sharing apps, delivery services, or any application requiring customized location selection and route planning.

---

## Features ✨

- 🛣️ **Polygon support**: Added support for drawing polygons on the map, with the ability to define multiple points for both internal and external polygons.
- **Interactive location picking**: Users can select start and destination points directly on the map
- **Multiple waypoints support**: Add multiple stops along a route
- **Customizable map styles**: Apply custom map themes (dark mode, light mode, etc.)
- **Arabic language support**: Built-in support for Arabic UI
- **Location search**: Search functionality to find locations by name/address

---

## Installation 📦

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  # mdsoft_google_map_user_pick_location_from_scroll : ^<latest_version>
  mdsoft_google_map_user_pick_location_from_scroll:
    git: "https://github.com/Salah3mer/google_map_routing_user_pick_location_from_scroll.git"
```

---

## Required Permissions 🔒

- **Android**: Add the following permissions to your `android/app/src/main/AndroidManifest.xml` file

```xml

<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools" package="com.example.example">
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>

<application

<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_API_KEY"/>
     </activity>
     ....
     </activity>
  ...>
```

- Add the following dependencies to your `android/gradle/wrapper/gradle-wrapper.properties` file

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
```

- Add the following dependencies to your `android/app/build.gradle` file

```gradle
android {
   compileSdk = 35
   ndkVersion = "25.1.8937393"

   compileOptions {
       sourceCompatibility = JavaVersion.VERSION_1_8
       targetCompatibility = JavaVersion.VERSION_1_8
   }

   kotlinOptions {
       jvmTarget = JavaVersion.VERSION_1_8
   }
}
```

- Add the following dependencies to your `android/settings.gradle` file

```gradle
plugins {
   id "com.android.application" version "8.3.2" apply false
}
```

- **iOS**: Add the following permissions to your `ios/Runner/Info.plist` file

```plist
<!-- Info.plist snippet for iOS -->
<dict>
  <!-- Location Permissions -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>This app requires access to your location to provide routing features.</string>
  <key>NSLocationAlwaysUsageDescription</key>
  <string>This app requires always-on location access for background navigation.</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>This app needs access to your location both in the foreground and background for route tracking.</string>

  <!-- Background Modes: Enable location updates in the background -->
  <key>UIBackgroundModes</key>
  <array>
      <string>location</string>
  </array>
  <!-- Internet access is granted by default; no explicit key needed for INTERNET permission. -->

  <!-- For notifications, iOS requires you to request permission at runtime via UNUserNotificationCenter -->
</dict>
```

---

- **Web**: Add the following permissions to your `web/index.html` file in the `head` section

`<script src="https://maps.googleapis.com/maps/api/js?key=APIKEY"></script>`

## Usage 🚀

1. Before running the app, ensure you have set up all necessary permissions (location, notification) and API keys (Google Maps API key) in your `AndroidManifest.xml` and `Info.plist` files.

2. Pass `MdUserPickLocationGoogleMapConfig` on the screen that opens the picker. `main` does not set it. Use `copyWith` on that screen when one value should change.

### Implementing the Location Picker

To use the location picker in your app, include the `MdSoftGoogleMapUserPickLocationFromScroll` widget in your widget tree:

```dart
MdSoftGoogleMapUserPickLocationFromScroll(
  config: const MdUserPickLocationGoogleMapConfig(
    apiKey: 'YOUR_API_KEY',
    baseUrl: 'YourBaseUrl',
    searchGovernorate: true,
    governorateEndpoint: 'governorates/me',
  ).copyWith(
    primaryColor: Colors.blue,
    fontFamily: 'Your Font Family',
  ),
  isUser: true, // Set to true for user mode, false for driver mode
  mapStyle: 'assets/json/map_style.json', // Path to your custom map style JSON file (optional)
  isStart: false, /// for chinging pin

  internal: false, // added if  you wont to make it internal or not
  startLocation:
            const LatLng(35.1772740409823, 45.98494988507281),
  selectedPlace: (val) {
       /// on tap it give you the selectedLocation LatLang
        log('selectedLocation Place: ${val.selectedLocation}');
       ///  give you the selectedLocation  point name
        log('pointName Place: ${val.pointName}');

        },
),
```

The picker keeps its own state with Flutter `ChangeNotifier`. You do not add `flutter_bloc`, Provider, Riverpod, or GetX to use it. The `selectedPlace` callback is the result.

Pass a `LocationPickerController` only when your own widget needs to move the camera or clear search:

```dart
final picker = LocationPickerController();

MdSoftGoogleMapUserPickLocationFromScroll(
  controller: picker,
  internal: true,
  selectedPlace: (place) {},
);
```

If `controller` is omitted, the widget creates and disposes one for you.

### Text, colors, and icons

Pass one `LocationPickerTheme` to change the words, the icon color, and the rest of the picker. Each sentence, color, and image has an enum name. You only set the ones you want to change.

```dart
MdSoftGoogleMapUserPickLocationFromScroll(
  internal: false,
  theme: const LocationPickerTheme(
    iconColor: Colors.blue,
    primaryColor: Colors.blue,
    textDirection: TextDirection.ltr,
    placeLanguageCode: 'en',
    textOverrides: {
      LocationPickerText.searchHint: 'Where do you want to go?',
      LocationPickerText.confirmPoint: 'Save point',
    },
  ),
  selectedPlace: (place) {},
)
```

`iconColor` tints Flutter icons and SVG files. A PNG or JPG keeps its own pixels. Leave a picture unset to keep the package default. Replace one with either a Flutter icon or an asset path:

```dart
theme: LocationPickerTheme(
  search: const LocationPickerGraphic.icon(Icons.search),
  startPin: const LocationPickerGraphic.asset('assets/images/pin.png'),
  currentLocationButton: const LocationPickerGraphic.asset(
    'assets/images/locate.svg',
  ),
)
```

## Complete Example

Here's a complete example integrating the location picker in your Flutter application:

```dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/google_map_routing.dart';
import 'package:mdsoft_google_map_user_pick_location_from_scroll/md_user_pick_location_google_map_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification permissions
  await Permission.notification.isDenied.then((value) async {
    if (value) {
      await Permission.notification.request();
    }
  });

  // Handle permanently denied notification permissions
  await Permission.notification.isPermanentlyDenied.then((value) async {
    if (value) {
      await openAppSettings();
    }
  });

  // Request location permissions
  await requestLocationPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Picker Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Picker Demo'),
      ),
      body: MdSoftGoogleMapUserPickLocationFromScroll(
        config: const MdUserPickLocationGoogleMapConfig(
          apiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
          baseUrl: 'YourBaseUrl',
        ).copyWith(fontFamily: 'Hanimation'),
        isUser: true, // User mode
        mapStyle: 'assets/json/map_style.json', // Custom map style (optional)
        floatingActionButtonIcon: const Icon(
          Icons.my_location,
          color: Colors.black
        ),
        selectedPlace: (MdOnUserSelectedPlace selectedPlaces) {
          // Handle the selected locations
          log('Starting location: ${selectedPlaces.selectedStartLocationLatLng}');
          log('Destination locations: ${selectedPlaces.selectedEndLocationLatLng}');
          log('Location names: ${selectedPlaces.pointsName}');

          // Navigate to a new screen with the selected locations
          // or process the data as needed
        },
      ),
    );
  }
}

// Helper function to request location permissions
Future<bool> requestLocationPermissions() async {
  // Request foreground location permission
  PermissionStatus foregroundStatus = await Permission.locationWhenInUse.request();
  if (!foregroundStatus.isGranted) {
    print("Foreground location permission denied");
    return false;
  }

  // Request background location permission
  PermissionStatus backgroundStatus = await Permission.locationAlways.request();
  if (!backgroundStatus.isGranted) {
    print("Background location permission denied");
    return false;
  }

  print("Both location permissions granted");
  return true;
}
```

## Handling Selected Locations

When a user selects locations on the map, the `selectedPlace` callback provides a `MdOnUserSelectedPlace` object with the following properties:

- `selectedStartLocationLatLng` - The LatLng coordinates of the starting point
- `selectedEndLocationLatLng` - A list of LatLng coordinates for all destination points
- `pointsName` - A list of string names for all the points (starting point and destinations)

You can use this data to implement navigation, calculate routes, or store the selected locations.

## Customization

The package allows for several customization options:

1. **Map Style**: You can provide a custom map style JSON file to change the appearance of the map.
2. **Primary Color**: Set the accent color used throughout the UI components.
3. **Font Family**: Specify a custom font to be used in the interface.
4. **Floating Action Button Icon**: Customize the icon of the location button.

## Note on Arabic Support

This package has built-in support for Arabic UI. The interface text and layout direction are optimized for Arabic language users.

## License

This package is available under the MIT License.
