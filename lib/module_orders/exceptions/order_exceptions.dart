import 'dart:core';

class OrderException implements Exception {
  final String msg;

  const OrderException(this.msg);

  @override
  String toString() => 'OrderException ${msg}';
}

class ProductOrderIsNotExist implements Exception {
  final String msg;
  const ProductOrderIsNotExist(this.msg);
  @override
  String toString() => msg;
}

