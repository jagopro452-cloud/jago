import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/features/splash/screens/splash_screen.dart';
import 'package:jago_user_app/features/trip/screens/gst_invoice_screen.dart';
import 'package:jago_user_app/features/trip/screens/report_overcharge_screen.dart';

class RouteHelper {
  static const String splash = '/splash';
  static const String gstInvoice = '/gst-invoice';
  static const String reportOvercharge = '/report-overcharge';
  static String getSplashRoute({Map<String,dynamic>? notificationData}) {
    notificationData?.remove('body');
    String userName = (notificationData?['user_name'] ?? '').replaceAll('&','a');
    notificationData?.remove('user_name');

    return '$splash?notification=${jsonEncode(notificationData)}&userName=$userName';
  }
  static String getGstInvoiceRoute(String tripId) => '$gstInvoice?trip_id=$tripId';
  static String getReportOverchargeRoute(String tripId) => '$reportOvercharge?trip_id=$tripId';
  static List<GetPage> routes = [
    GetPage(name: splash, page: () => SplashScreen(
        notificationData: Get.parameters['notification'] == null ?
        null :
        jsonDecode(Get.parameters['notification']!),
        userName: Get.parameters['userName']?.replaceAll('a', '&')
    )),
    GetPage(name: gstInvoice, page: () => GstInvoiceScreen(
        tripId: Get.parameters['trip_id'] ?? ''
    )),
    GetPage(name: reportOvercharge, page: () => ReportOverchargeScreen(
        tripId: Get.parameters['trip_id'] ?? ''
    )),
  ];

  static void goPageAndHideTextField(BuildContext context, Widget page){
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    currentFocus.requestFocus(FocusNode());
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    Future.delayed(const Duration(milliseconds: 300)).then((_){
      Get.to(() => page);

    });

  }

}