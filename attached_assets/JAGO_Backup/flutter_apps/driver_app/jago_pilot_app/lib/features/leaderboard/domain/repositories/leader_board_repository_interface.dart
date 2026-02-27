

import 'package:get/get_connect/http/src/response/response.dart';
import 'package:jago_pilot_app/interface/repository_interface.dart';

abstract class LeaderBoardRepositoryInterface implements RepositoryInterface {
  Future<Response?> getDailyActivity();
  Future<Response?> getLeaderBoardList({int? offset = 1,required String selectedFilterName});
  Future<Response?> getPerformanceScore(String driverId);
}