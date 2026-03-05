

import 'package:jago_pilot_app/interface/repository_interface.dart';

abstract class NotificationRepositoryInterface implements RepositoryInterface {
  Future<dynamic> sendReadStatus(int notificationId);
}