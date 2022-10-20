import 'package:my_kom/module_orders/model/order_model.dart';
enum CreateOrderStatus{create_order_error,payment_field,success}
class CreateOrderResponse {
  late OrderModel? order;
  late String message;

  CreateOrderResponse(
      {required this.order,
      required this.message,
      });
}

