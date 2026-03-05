

import 'package:jago_user_app/features/my_offer/domain/repositories/offer_repository_interface.dart';
import 'package:jago_user_app/features/my_offer/domain/services/offer_service_interface.dart';

class OfferService implements OfferServiceInterface {
  OfferRepositoryInterface offerRepositoryInterface;

  OfferService({required this.offerRepositoryInterface});

  @override
  Future getOfferList(int offset) async{
    return await offerRepositoryInterface.getList(offset: offset);
  }
}