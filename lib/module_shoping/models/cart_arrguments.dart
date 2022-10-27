import 'package:my_kom/module_map/models/address_model.dart';

class CartArguments{
  final AddressModel addressModel;
  final String buildingId;
  final String phone;
  final bool vip;
  final String note;
  CartArguments({required this.addressModel,required this.phone,required this.note,required this.buildingId,required this.vip});
}