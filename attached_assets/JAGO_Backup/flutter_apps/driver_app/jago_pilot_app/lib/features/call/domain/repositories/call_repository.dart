import 'package:get/get.dart';
import 'package:jago_pilot_app/data/api_client.dart';
import 'package:jago_pilot_app/util/app_constants.dart';

class CallRepository {
  final ApiClient apiClient;
  CallRepository({required this.apiClient});

  Future<Response> startCall({
    required String tripRequestId,
    required String callerType,
    required String callerId,
    required String calleeType,
    required String calleeId,
  }) async {
    return await apiClient.postData(AppConstants.callStart, {
      'trip_request_id': tripRequestId,
      'caller_type': callerType,
      'caller_id': callerId,
      'callee_type': calleeType,
      'callee_id': calleeId,
    });
  }

  Future<Response> sendSignal({
    required String callId,
    required String senderType,
    required String senderId,
    required String signalType,
    required dynamic payload,
  }) async {
    return await apiClient.postData('${AppConstants.callSignal}$callId/signal', {
      'sender_type': senderType,
      'sender_id': senderId,
      'signal_type': signalType,
      'payload': payload,
    });
  }

  Future<Response> pollSignals({
    required String callId,
    required String listenerId,
    String? after,
  }) async {
    String uri = '${AppConstants.callPoll}$callId/poll?user_id=$listenerId';
    if (after != null) uri += '&since=$after';
    return await apiClient.getData(uri);
  }

  Future<Response> getCallStatus({required String callId}) async {
    return await apiClient.getData('${AppConstants.callStatus}$callId/status');
  }

  Future<Response> pollIncoming({required String userId}) async {
    return await apiClient.getData('${AppConstants.callIncoming}?user_id=$userId');
  }
}
