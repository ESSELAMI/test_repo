class UpdateOrderRequest {
  late String orderID;
  late bool paymentState;
 // late String duration;

  UpdateOrderRequest({required this.orderID});


  Map<String, dynamic> paymentStateToJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['payment_state'] = this.paymentState;
    return data;
  }
}
