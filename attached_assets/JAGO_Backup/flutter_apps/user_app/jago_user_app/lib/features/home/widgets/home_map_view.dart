import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jago_user_app/features/map/controllers/map_controller.dart';
import 'package:jago_user_app/features/ride/controllers/ride_controller.dart';
import 'package:jago_user_app/features/wallet/widget/custom_title.dart';
import 'package:jago_user_app/theme/theme_controller.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/features/home/widgets/banner_shimmer.dart';
import 'package:jago_user_app/features/location/controllers/location_controller.dart';


class HomeMapView extends StatefulWidget {
  final String title;
  const HomeMapView({super.key, required this.title});

  @override
  HomeMapViewState createState() => HomeMapViewState();
}

class HomeMapViewState extends State<HomeMapView> {
  GoogleMapController? _mapController;
  int isFirstCount = 0;
  Timer? _nearbyRefreshTimer;


  @override
  void initState() {
    super.initState();
    _startNearbyPilotRefresh();
  }

  void _startNearbyPilotRefresh() {
    _nearbyRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshNearbyPilots();
    });
  }

  void _refreshNearbyPilots() {
    try {
      final locationController = Get.find<LocationController>();
      final userAddress = locationController.getUserAddress();
      if (userAddress?.latitude != null && userAddress?.longitude != null) {
        Get.find<RideController>().getNearestDriverList(
          userAddress!.latitude!.toString(),
          userAddress!.longitude!.toString(),
        );
      }
    } catch (_) {
      // Silently ignore errors from nearby pilots refresh
    }
  }

  @override
  void dispose() {
    _nearbyRefreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MapController>(builder: (mapController) {
      return GetBuilder<LocationController>(builder: (locationController) {
        Completer<GoogleMapController> mapCompleter = Completer<GoogleMapController>();
        if(mapController.mapController != null) {
          mapCompleter.complete(mapController.mapController);
        }
        return mapController.nearestDeliveryManMarkers != null ?
        Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          child: Column(children: [
            CustomTitle(
              title: widget.title.tr,
              color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha:0.9) : Theme.of(context).textTheme.bodyLarge!.color,
              fontSize: Dimensions.fontSizeDefault,
            ),
            const SizedBox(height:Dimensions.paddingSizeSmall),

            Container(height: Get.height * 0.25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                child: GoogleMap(
                  style: Get.isDarkMode ?
                  Get.find<ThemeController>().darkMap :
                  Get.find<ThemeController>().lightMap,
                  markers: mapController.nearestDeliveryManMarkers!.toSet(),
                  initialCameraPosition: CameraPosition(target: LatLng(
                    Get.find<LocationController>().getUserAddress()?.latitude ?? 0,
                    Get.find<LocationController>().getUserAddress()?.longitude ?? 0,
                  ), zoom: 13),
                   minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                  onMapCreated: (gController) {
                    _mapController = gController;
                    mapController.setMapController(gController);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
              ),
            ),
          ]),
        ) :
        const BannerShimmer();
      });
    });
  }
}
