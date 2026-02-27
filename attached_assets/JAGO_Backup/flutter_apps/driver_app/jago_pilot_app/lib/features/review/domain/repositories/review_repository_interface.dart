

import 'package:get/get_connect/http/src/response/response.dart';
import 'package:jago_pilot_app/interface/repository_interface.dart';

abstract class ReviewRepositoryInterface implements RepositoryInterface{

  Future<Response> getSavedReviewList(int offset, int isSaved );
  Future<Response> savedReview(String id );
  Future<Response> submitReview(String id, int ratting, String comment );
}