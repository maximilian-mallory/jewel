import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

Future<bool> checkLocationPermission() async {
  try {
    Location location = Location();
    var status = await location.hasPermission();
    if(status == PermissionStatus.deniedForever && !kIsWeb) {
      handler.openAppSettings();
    }
    return status == PermissionStatus.granted || status == PermissionStatus.grantedLimited;
  } catch (e) {
    print("Error checking location permission: $e");
    return false;
  }
}

Future<LocationData?> getLocationData(BuildContext context) async {
  Location location = Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData? _locationData;

  try {
    if (!kIsWeb) {
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return null;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted && 
            _permissionGranted != PermissionStatus.grantedLimited) {
          return null;
        }
      } else if (_permissionGranted == PermissionStatus.deniedForever) {
        // Special case for permanently denied permissions
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Permission Denied'),
              content: Text('Location permission is permanently denied. Please enable it from the app settings.'),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return null;
      }
    }
    
    _locationData = await location.getLocation();
    return _locationData;
    
  } catch (e) {
    print("Error getting location: $e");
    
    String errorMessage = kIsWeb 
        ? 'Location permission is permanently denied. Please manually change the location permission in your browser settings.'
        : 'Unable to access location. Please check your device settings.';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return null;
  }
}