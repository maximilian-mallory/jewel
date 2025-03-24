import 'package:location/location.dart';

/*
  This function is used to get the location data of the user.
  It returns the location data of the user.
  If the location service is not enabled, it will request the user to enable it.
  If the location permission is not granted, it will request the user to grant it.
  It should work but hasnt been tested yet.
*/

Future<LocationData?> getLocationData() async {
Location location = Location();

bool _serviceEnabled;
PermissionStatus _permissionGranted;
LocationData _locationData;

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
  if (_permissionGranted != PermissionStatus.granted) {
    return null;
  }
}

_locationData = await location.getLocation();

return _locationData;

}