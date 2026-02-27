import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:collection';
import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jago_pilot_app/features/location/controllers/location_controller.dart';
import 'package:jago_pilot_app/features/splash/controllers/splash_controller.dart';
import 'package:jago_pilot_app/util/app_constants.dart';
import 'package:jago_pilot_app/util/images.dart';
import 'package:jago_pilot_app/features/profile/controllers/profile_controller.dart';
import 'package:jago_pilot_app/features/ride/controllers/ride_controller.dart';


enum RideState{initial, pending, accepted, outForPickup, ongoing, acceptingRider, completed, fareCalculating}
class RiderMapController extends GetxController implements GetxService {

  final bool _showCancelTripButton = false;
  bool get showCancelTripButton => _showCancelTripButton;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool isRefresh = false;

  bool _checkIsRideAccept = false;
  bool get checkIsRideAccept => _checkIsRideAccept;
  bool isTrafficEnable = false;

  Set<Marker> markers = HashSet<Marker>();
  final List<MarkerData> _customMarkers = [];
  List<MarkerData> get customMarkers => _customMarkers;
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinateList = [];

  GoogleMapController? mapController;

  LatLng? _lastDriverPosition;
  double _lastDriverBearing = 0;
  Timer? _animationTimer;
  static const int _animationSteps = 15;
  static const int _animationDurationMs = 1500;

  bool profileOnline = true;
  void toggleProfileStatus(){
    profileOnline = ! profileOnline;
    update();
  }

  bool clickedAssistant = false;
  void toggleAssistant(){
    clickedAssistant = !clickedAssistant;
    update();
  }

  double panelHeightOpen = 0;

  RideState currentRideState = RideState.initial;
  void setRideCurrentState(RideState newState, {bool notify = true}){
    currentRideState = newState;
    if(currentRideState == RideState.initial){
      initializeData();
    }

    if(notify){
      update();
    }

  }


  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }


  final double _distance = 0;
  double get distance => _distance;
  late Position _position;
  Position get position => _position;
  LatLng _initialPosition = const LatLng(23.83721, 90.363715);
  LatLng get initialPosition => _initialPosition;


  final LatLng _customerPosition = const LatLng(12,12);
  late LatLng _destinationPosition = const LatLng(23.83721, 90.363715);
  LatLng get customerInitialPosition => _customerPosition;
  LatLng get destinationPosition => _destinationPosition;


  @override
  void onInit() {
    initializeData();
    super.onInit();
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    super.onClose();
  }

  void initializeData() {
    Get.find<RideController>().polyline = '';
    markers = {};
    polylines = {};
    _isLoading = false;
    _lastDriverPosition = null;
    _lastDriverBearing = 0;
    _animationTimer?.cancel();
  }


  void acceptedRideRequest(){
    _checkIsRideAccept = !_checkIsRideAccept;
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }


  double sheetHeight = 0;
  void setSheetHeight(double height, bool notify){
    sheetHeight = height;
    if(notify){
      update();
    }

  }

  void getPickupToDestinationPolyline({bool updateLiveLocation = false}) async {
    List<LatLng> polylineCoordinates = [];
    if(Get.find<RideController>().polyline != ''){
      List<PointLatLng> result = PolylinePoints.decodePolyline(Get.find<RideController>().polyline);
      if (kDebugMode) {
      }
      if (result.isNotEmpty) {
        for (var point in result) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }


        _initialPosition = LatLng(result[0].latitude, result[0].longitude);
        _destinationPosition = LatLng(result[result.length-1].latitude, result[result.length-1].longitude);
      }
      _addPolyLine(polylineCoordinates);

      polylineCoordinateList = polylineCoordinates;
      updateMarkerAndCircle(Get.find<LocationController>().initialPosition);

      setFromToMarker(_initialPosition, _destinationPosition, updateLiveLocation: updateLiveLocation);
    }
    update();

  }

  bool isBound = true;
  void getDriverToPickupOrDestinationPolyline(String lines, {bool mapBound = false}) async {

    List<LatLng> polylineCoordinates = [];
    if(lines != ''){
      List<PointLatLng> result = PolylinePoints.decodePolyline(lines);
      if (kDebugMode) {
      }
      if (result.isNotEmpty) {
        for (var point in result) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _initialPosition = LatLng(result[0].latitude, result[0].longitude);
        _destinationPosition = LatLng(result[result.length-1].latitude, result[result.length-1].longitude);
      }
      _addPolyLine(polylineCoordinates);

      polylineCoordinateList = polylineCoordinates;
      _animateDriverMarker(polylineCoordinates.first);

      isInsideCircle(result[0].latitude, result[0].longitude, result[result.length-1].latitude, result[result.length-1].longitude, Get.find<SplashController>().config!.completionRadius!);
      if(mapBound){
        boundMapScreen(_initialPosition,_destinationPosition);
      }


    }
    update();

  }

  void _addPolyLine(List<LatLng> polylineCoordinates) {
    polylines.clear();
    Polyline polyline = Polyline(
      polylineId: const PolylineId('poly'),
      points: polylineCoordinates,
      width: 5,
      color: Theme.of(Get.context!).primaryColor,
    );
    polylines.add(polyline);
    update();
  }


  void setFromToMarker(LatLng from, LatLng to, {bool updateLiveLocation = false}) async{
    markers = HashSet();
    List<LatLng> intermediateCoordinates = [];
    int markerId = 0;
    Uint8List fromMarker = await convertAssetToUnit8List(Images.fromIcon, width: 50);
    Uint8List toMarker = await convertAssetToUnit8List(Images.targetLocationIcon, width: 30);
    Uint8List intermediateIcon = await convertAssetToUnit8List(Images.ongoingMarkerIcon, width: 30);

    markers.add(Marker(
      markerId: const MarkerId('from'),
      position: from,
      infoWindow:  InfoWindow(
        title:  Get.find<RideController>().tripDetail?.pickupAddress??'',
        snippet: 'pick_up_location'.tr,
      ),
      anchor: const Offset(0.5, 0.6),
      icon:  BitmapDescriptor.bytes(fromMarker),
    ));

    markers.add(Marker(
      markerId: const MarkerId('to'),
      position: to,
      anchor: const Offset(0.5, 0.6),
      infoWindow:  InfoWindow(
        title:  Get.find<RideController>().tripDetail?.destinationAddress ??'',
        snippet: 'destination'.tr,
      ),
      icon:  BitmapDescriptor.bytes(toMarker),
    ));

    if(Get.find<RideController>().tripDetail?.intermediateCoordinates != null){
      List<dynamic> parsedList = jsonDecode(Get.find<RideController>().tripDetail!.intermediateCoordinates!);

      parsedList.map((item){
        intermediateCoordinates.add(LatLng(item[0], item[1]));
      }).toList();

    }

    for (var coordinates in intermediateCoordinates) {
      markers.add(Marker(
        markerId: MarkerId((markerId++).toString()),
        position: coordinates,
        anchor: const Offset(0.4, 0.8),
        icon:  BitmapDescriptor.bytes(intermediateIcon),
      ));
    }


    try {
      LatLngBounds? bounds;
      if(mapController != null) {
        if (from.latitude < to.latitude) {
          bounds = LatLngBounds(southwest: from, northeast: to);
        }else {
          bounds = LatLngBounds(southwest: to, northeast: from);
        }
      }
      LatLng centerBounds = LatLng(
        (bounds!.northeast.latitude + bounds.southwest.latitude)/2,
        (bounds.northeast.longitude + bounds.southwest.longitude)/2,
      );
      double bearing = Geolocator.bearingBetween(from.latitude, from.longitude, to.latitude, to.longitude);
      mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        bearing: bearing, target: centerBounds, zoom: 16,
      )));
      setMapPosition(mapController, bounds, centerBounds, bearing, padding: 0.5);
    }catch(e) {
    }

    update();
  }

  LatLng _interpolate(LatLng from, LatLng to, double fraction) {
    double lat = from.latitude + (to.latitude - from.latitude) * fraction;
    double lng = from.longitude + (to.longitude - from.longitude) * fraction;
    return LatLng(lat, lng);
  }

  double _interpolateBearing(double from, double to, double fraction) {
    double diff = to - from;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (from + diff * fraction) % 360;
  }

  double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  void _animateDriverMarker(LatLng targetPosition) async {
    Uint8List car;
    if (currentRideState.name == "initial") {
      car = await convertAssetToUnit8List(Images.mapLocationIcon, width: 100);
    } else {
      car = await convertAssetToUnit8List(
        Get.find<ProfileController>().profileInfo?.vehicle?.category?.type == 'car' ? Images.carIconTop : Images.bike,
        width: 30,
      );
    }

    double targetBearing = polylineCoordinateList.isNotEmpty
        ? _calculateBearing(
            polylineCoordinateList.first,
            polylineCoordinateList.length > 1 ? polylineCoordinateList[1] : polylineCoordinateList.last,
          )
        : _lastDriverBearing;

    if (_lastDriverPosition != null) {
      _animationTimer?.cancel();
      final LatLng startPos = _lastDriverPosition!;
      final double startBearing = _lastDriverBearing;
      int step = 0;

      _animationTimer = Timer.periodic(
        Duration(milliseconds: _animationDurationMs ~/ _animationSteps),
        (timer) {
          step++;
          double fraction = step / _animationSteps;
          fraction = _easeInOut(fraction);

          if (step >= _animationSteps) {
            timer.cancel();
            _placeDriverMarker(targetPosition, targetBearing, car);
          } else {
            LatLng interpolated = _interpolate(startPos, targetPosition, fraction);
            double interpolatedBearing = _interpolateBearing(startBearing, targetBearing, fraction);
            _placeDriverMarker(interpolated, interpolatedBearing, car);
          }
        },
      );
    } else {
      _placeDriverMarker(targetPosition, targetBearing, car);
    }

    _lastDriverPosition = targetPosition;
    _lastDriverBearing = targetBearing;
  }

  void _placeDriverMarker(LatLng position, double bearing, Uint8List icon) {
    markers.removeWhere((marker) => marker.markerId.value == "home");
    markers.add(Marker(
      markerId: const MarkerId("home"),
      position: position,
      rotation: bearing,
      draggable: false,
      zIndexInt: 2,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: BitmapDescriptor.bytes(icon),
    ));
    update();
  }

  void updateMarkerAndCircle(LatLng? latLong) async {
    if (polylineCoordinateList.isNotEmpty) {
      _animateDriverMarker(latLong ?? polylineCoordinateList.first);
    }
  }

  double _calculateBearing(LatLng startPoint, LatLng endPoint) {
    final double startLat = _toRadians(startPoint.latitude);
    final double startLng = _toRadians(startPoint.longitude);
    final double endLat = _toRadians(endPoint.latitude);
    final double endLng = _toRadians(endPoint.longitude);

    final double deltaLng = endLng - startLng;

    final double y = math.sin(deltaLng) * math.cos(endLat);
    final double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(deltaLng);

    final double bearing = math.atan2(y, x);

    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  double _toDegrees(double radians) => radians * (180.0 / math.pi);


  Future<Uint8List> convertAssetToUnit8List(String imagePath, {int width = 50}) async {
    ByteData data = await rootBundle.load(imagePath);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> setMapPosition(GoogleMapController? controller, LatLngBounds? bounds, LatLng centerBounds, double bearing, {double padding = 0.5}) async {

    controller?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _initialPosition, zoom: AppConstants.mapZoom),
    ));
    update();
  }


  void boundMapScreen(LatLng startingPoint , LatLng endingPoint){
    try {
      LatLngBounds? bounds;
      if(mapController != null) {
        if (startingPoint.latitude < endingPoint.latitude) {
          bounds = LatLngBounds(southwest: startingPoint, northeast: endingPoint);
        }else {
          bounds = LatLngBounds(southwest: endingPoint, northeast: startingPoint);
        }
      }
      LatLng centerBounds = LatLng(
        (bounds!.northeast.latitude + bounds.southwest.latitude)/2,
        (bounds.northeast.longitude + bounds.southwest.longitude)/2,
      );
      double bearing = Geolocator.bearingBetween(startingPoint.latitude, startingPoint.longitude, endingPoint.latitude, endingPoint.longitude);
      mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        bearing: bearing, target: centerBounds, zoom: 16,
      )));
      setMapPosition(mapController, bounds, centerBounds, bearing, padding: 0.5);
    }catch(e) {
    }
  }

  bool _isInside = false;
  bool get isInside => _isInside;

  void isInsideCircle(double lat, double lng, double latCenter, double lngCenter, double radius) {
    double distance = distanceBetween(lat, lng, latCenter, lngCenter);
    _isInside = (distance <= radius) ? true : false;
    update();
  }

  double distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    double distance = Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
    return distance;
  }

  void setMarkersInitialPosition(){
    if(Get.find<RideController>().polyline != ''){
      List<PointLatLng> result = PolylinePoints.decodePolyline(Get.find<RideController>().polyline);

        _initialPosition = LatLng(result[0].latitude, result[0].longitude);
        _destinationPosition = LatLng(result[result.length-1].latitude, result[result.length-1].longitude);

      setFromToMarker(_initialPosition, _destinationPosition, updateLiveLocation: false);
    }
  }

  void toggleTrafficView(){
    isTrafficEnable = !isTrafficEnable;
    update();
  }


  void checkDriverReachedDestination(String lines) async {
    if(lines != ''){
      List<PointLatLng> result = PolylinePoints.decodePolyline(lines);
      if (result.isNotEmpty) {
        isInsideCircle(result[0].latitude, result[0].longitude, result[result.length-1].latitude, result[result.length-1].longitude, Get.find<SplashController>().config!.completionRadius!);
      }
    }
  }

}
