import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jago_user_app/features/address/domain/models/address_model.dart';

abstract class LocationServiceInterface{
  Future<dynamic> getZone(String lat, String lng);
  Future<dynamic> getAddressFromGeocode(LatLng? latLng);
  Future<dynamic> searchLocation(String text);
  Future<dynamic> getPlaceDetails(String placeID);
  Future<bool> saveUserAddress(Address? address);
  String? getUserAddress();
}