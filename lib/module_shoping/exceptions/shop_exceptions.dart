import 'dart:core';

class ShopException implements Exception {
  final String msg;

  const ShopException(this.msg);

  @override
  String toString() => 'ShopException ${msg}';
}

class PaymentFieldException implements Exception {
  final String msg;

  const PaymentFieldException(this.msg);

  @override
  String toString() => msg;
}


class CreateOrderException implements Exception {
  final String msg;

  const CreateOrderException(this.msg);

  @override
  String toString() => msg;
}

