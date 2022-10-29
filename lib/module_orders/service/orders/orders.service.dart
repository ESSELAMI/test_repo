
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:my_kom/consts/order_status.dart';
import 'package:my_kom/consts/payment_method.dart';
import 'package:my_kom/consts/utils_const.dart';
import 'package:my_kom/module_authorization/presistance/auth_prefs_helper.dart';
import 'package:my_kom/module_company/models/product_model.dart';
import 'package:my_kom/module_map/service/map_service.dart';
import 'package:my_kom/module_orders/exceptions/order_exceptions.dart';
import 'package:my_kom/module_orders/model/order_model.dart';
import 'package:my_kom/module_orders/repository/order_repository/order_repository.dart';
import 'package:my_kom/module_orders/request/accept_order_request/accept_order_request.dart';
import 'package:my_kom/module_orders/request/order/order_request.dart';
import 'package:my_kom/module_orders/response/create_order_response.dart';
import 'package:my_kom/module_orders/response/order_details/order_details_response.dart';
import 'package:my_kom/module_orders/response/order_status/order_status_response.dart';
import 'package:my_kom/module_orders/response/orders/orders_response.dart';
import 'package:my_kom/module_payment/service/payment_service.dart';
import 'package:my_kom/module_payment/bloc/payment_bloc.dart';
import 'package:my_kom/module_shoping/exceptions/shop_exceptions.dart';
import 'package:rxdart/rxdart.dart';
import "package:collection/collection.dart";
class OrdersService {
  //final ProfileService _profileService;
  final  OrderRepository _orderRepository = OrderRepository();
  final AuthPrefsHelper _authPrefsHelper = AuthPrefsHelper();
  final MapService _mapService = MapService();
  //final StripeServices _stripeServices = StripeServices();
 //final  PurchaseServices _purchaseServices = PurchaseServices();


  /// Streams
  late final PublishSubject<List<OrderModel>?> pendingOrdersPublishSubject ;

  late final PublishSubject<List<OrderModel>?> finishedOrdersPublishSubject ;

  /// Cashed Data
  late List<DocumentSnapshot> pendingDocumentList ;
  late List<DocumentSnapshot> finishedDocumentList ;

  OrdersService(){
    pendingOrdersPublishSubject= new PublishSubject();
    finishedOrdersPublishSubject= new PublishSubject();
    pendingDocumentList = [];
    finishedDocumentList = [];

  }

  final PublishSubject<List<NotificationModel>?> notificationsPublishSubject =
  new PublishSubject();





  /// Here is the conversion from document (ROW DATA) to Model (Representation Data)
  List<OrderModel> _orderDTO(List<DocumentSnapshot<Object?>> docs){
    try{
      List<OrderModel> orders =[];

      docs.forEach((element2) {
        Map <String, dynamic> order = element2.data() as Map<String,
            dynamic>;
        order['id'] = element2.id;
        OrderModel orderModel = OrderModel.mainDetailsFromJson(order);
          orders.add(orderModel);
      }
      );

      return orders;
    } catch(e){
      throw Exception();
    }

  }


  /// This method will automatically fetch first 20 elements from the document list
  Future<void> getMyOrders() async {
    String? uid = await _authPrefsHelper.getUserId();
      _orderRepository.getFirstBatchPendingMyOrders(uid:uid!).listen((event) async {
        pendingDocumentList = event.docs;
        List<OrderModel>orderList = await _orderDTO(pendingDocumentList);
        if(!pendingOrdersPublishSubject.isClosed)
        pendingOrdersPublishSubject.add(orderList);

      }).onError((e){
        print(e.toString());
        pendingOrdersPublishSubject.add(null);

        // on SocketException {
        //   movieController.sink.addError(SocketException("No Internet Connection"));
      });

  }


 /// This will automatically fetch the next 20 elements from the list
  Future<bool> fetchNextOrders()async {
    await Future.delayed(Duration(seconds: 5));
    String? uid = await _authPrefsHelper.getUserId();
     try {
      return _orderRepository.getNextBatchPendingMyOrders(uid:uid!,offset: pendingDocumentList[pendingDocumentList.length - 1]).then((event)async {
         print('next batch');
         print(event.docs.length);
         pendingDocumentList.addAll(event.docs);
         List<OrderModel> orderList = await _orderDTO(pendingDocumentList);
         pendingOrdersPublishSubject.add(orderList);
         return true;
       });
     } catch (e) {

return false;
     }
  }

  /// Finished Orders
  /// This method will automatically fetch first 20 elements from the document list
  Future<void> getFinishedMyOrders() async {
    String? uid = await _authPrefsHelper.getUserId();
    _orderRepository.getFirstBatchFinishedMyOrders(uid:uid!).listen((event) async {
      finishedDocumentList = event.docs;
      List<OrderModel> orderList = await _orderDTO(finishedDocumentList);
      finishedOrdersPublishSubject.add(orderList);

    }).onError((e){
      print(e.toString());
      finishedOrdersPublishSubject.add(null);

      // on SocketException {
      //   movieController.sink.addError(SocketException("No Internet Connection"));
    });

  }


  /// This will automatically fetch the next 20 elements from the list
  Future<bool> fetchNextFinishedOrders()async {
    String? uid = await _authPrefsHelper.getUserId();
    try {
      return _orderRepository.getNextBatchFinishedMyOrders(uid:uid!,offset: finishedDocumentList[finishedDocumentList.length - 1]).then((event)async {
        print('next batch');
        print(event.docs.length);
        finishedDocumentList.addAll(event.docs);
        List<OrderModel> orderList = await _orderDTO(finishedDocumentList);
        finishedOrdersPublishSubject.add(orderList);
        return true;
      });
    } catch (e) {
      return false;
    }
  }


  Future<OrderModel?> getOrderDetails(String orderId) async {
    try{
    OrderDetailResponse? response =   await _orderRepository.getOrderDetails(orderId);

    if(response ==null)
      return null;
    OrderModel orderModel = OrderModel() ;
     orderModel.id = response.id;
     orderModel.storeId = response.storeId;
    orderModel.vipOrder = response.vipOrder;
    orderModel.products = response.products;
    orderModel.payment = response.payment;
    orderModel.paymentState = response.paymentState;
    orderModel.orderValue = response.orderValue;
    orderModel.description = response.description;
    orderModel.ar_description = response.ar_description;
    orderModel.addressName = response.addressName;
    orderModel.destination = response.destination;
    orderModel.phone = response.phone;
    orderModel.buildingHomeId = response.buildingHomeId;
    orderModel.startDate =DateTime.parse(response.startDate);//DateTime.parse(response.startDate) ;
    orderModel.numberOfMonth = response.numberOfMonth;
    orderModel.deliveryTime = response.deliveryTime;
    orderModel.cardId = response.cardId;
    orderModel.status = response.status;
    orderModel.customerOrderID = response.customerOrderID;
    orderModel.productIds = response.products_ides;
    orderModel.note = response.note;
    orderModel.orderSource = response.orderSource;
    return orderModel;
    }catch(e){
      return null;
    }
  }


  Future<OrderModel?> getDetailsForReorder(String orderId) async {
    try{
      OrderDetailResponse? response =   await _orderRepository.getOrderDetails(orderId);

      if(response ==null)
        return null;
      print(response.products[0].toJson());
      OrderModel orderModel = OrderModel() ;
      orderModel.id = response.id;
      orderModel.storeId = response.storeId;
      orderModel.vipOrder = response.vipOrder;
      orderModel.payment = response.payment;
      orderModel.paymentState = response.paymentState;
      orderModel.orderValue = response.orderValue;
      orderModel.description = response.description;
      orderModel.ar_description = response.ar_description;
      orderModel.addressName = response.addressName;
      orderModel.destination = response.destination;
      orderModel.phone = response.phone;
      orderModel.buildingHomeId = response.buildingHomeId;
      orderModel.startDate =DateTime.parse(response.startDate);//DateTime.parse(response.startDate) ;
      orderModel.numberOfMonth = response.numberOfMonth;
      orderModel.deliveryTime = response.deliveryTime;
      orderModel.cardId = response.cardId;
      orderModel.customerOrderID = response.customerOrderID;
      orderModel.productIds = response.products_ides;
      orderModel.note = response.note;
      orderModel.orderSource = response.orderSource;
      /// The current state of the products
      List<ProductModel> _products = [];
      for(int i=0;i< response.products.length;i++){

        await _orderRepository.getCurrentStateOfProductById(response.products[i].id).then((rawProduct) {
         ProductModel _pro = ProductModel.fromJson(rawProduct);
         _pro.orderQuantity = response.products[i].orderQuantity;
         _pro.isExist = false;
         _products.add(_pro);
        }).catchError((e){
          print(e.toString());
           if(e is ProductOrderIsNotExist){
             ProductModel _pro = response.products[i];
             _pro.isExist = false;
             _products.add(_pro);
           }else{
             throw e;
           }
         });

      }
      orderModel.products = _products;

      return orderModel;

    }catch(e){
      return null;
    }
  }

  Future<OrderModel?> getTrackingDetails(String orderId) async {
    try{
      OrderStatusResponse? response =   await _orderRepository.getTrackingDetails(orderId);

      if(response ==null)
        return null;
      OrderModel orderModel = OrderModel() ;
      orderModel.id = response.id;
      orderModel.customerOrderID = response.customerOrderID;
      orderModel.status = response.status;
      orderModel.payment = response.payment;
      return orderModel;
    }catch(e){
      return null;
    }
  }

  Future<CreateOrderResponse> addNewOrder(
      {required List<ProductModel>  products ,required String storeId,required String addressName, required String deliveryTimes,
        required bool orderType , required GeoJson destination, required String phoneNumber,required String paymentMethod,
        required  double amount , required String? cardId,required int numberOfMonth,String? description,String? arDescription
        ,required int? customerOrderID,required List<String>? productsIds,
        required String note,
        required String? orderSource,
        required String buildingHomeId,
      }
      ) async {

    try {
      String? uId = await _authPrefsHelper.getUserId();
      DateTime date = DateTime.now();
      late CreateOrderRequest orderRequest;
      late DocumentSnapshot orderSnapShot ;
      /// generate sequence id;
      ///
      /// Optimistic Dependent Transaction (Client Side)
      int? customer_order_id = await _orderRepository.generateOrderID();



        ///For avoid the modification process from the ui (amount = 0.0)
        amount = 0.0;

        Map<ProductModel, int> productsMap = Map<ProductModel, int>();

        Map<String, List<ProductModel>> _gruoped_products_list = groupBy(
            products, (ProductModel p0) => p0.id);
        _gruoped_products_list.forEach((key, value) {
          productsMap[value.first] = value.length;
        });

        List<ProductModel> newproducts = [];
        String description = '';
        String ar_Desccription = '';
        List<String> products_ides = [];

        productsMap.forEach((key, value) {

          ///product is exits in data base (for reorder , old products)
          if(key.isExist){
            amount += key.price * value;
            key.orderQuantity = value;
            description =
                description + key.orderQuantity.toString() + ' ' + key.title +
                    ' + ';
            ar_Desccription =
                ar_Desccription + key.orderQuantity.toString() + ' ' +
                    key.title2.toString() + ' + ';
            newproducts.add(key);
            products_ides.add(key.id);
          }
        });

        if (customer_order_id == null)
          throw Exception();


        /// Get Order Source
        orderSource = await _mapService.getOrderSource(
            LatLng(destination.lat, destination.lon));

        orderRequest = CreateOrderRequest(
            userId: uId!,
            storeId: storeId,
            vipOrder: orderType,
            destination: destination,
            phone: phoneNumber,
            payment: paymentMethod,
            paymentState: false,
            products: newproducts,
            numberOfMonth: numberOfMonth,
            deliveryTime: deliveryTimes,
            orderValue: amount,
            startDate: date.toIso8601String(),
            // DateFormat('yyyy-MM-dd HH-mm').format(date)  ,
            description: description.substring(0, description.length - 2),
            addressName: addressName,
            cardId: cardId,
            customerOrderID: customer_order_id,
            productsIdes: products_ides,
            note: note,
            orderSource: orderSource,
            ar_description: ar_Desccription.substring(
                0, ar_Desccription.length - 2),
            buildingHomeNumber: buildingHomeId

        );

        /// Set Init State To New Order
        orderRequest.status = OrderStatus.INIT.name;


        orderSnapShot = await _orderRepository.addNewOrder(
            orderRequest);

        /// Here is the payment process (After adding the order to the data base)
        if(paymentMethod == PaymentMethodConst.CREDIT_CARD){
         bool paymentResult =  await _paymentProcess(paymentMethodID:cardId!, products: newproducts);
         if(paymentResult)
           {
             print('msg: success payment , tag: order service');
             Map<String, dynamic> map = orderSnapShot.data() as Map<String, dynamic>;
             map['id'] = orderSnapShot.id;
             await _updateOrderPaymentState(orderSnapShot.id);
             return CreateOrderResponse(order: OrderModel.mainDetailsFromJson(map), message:UtilsConst.lang == 'en'? 'Your order has been Successfully sent':'تم ارسال طلبك بنجاح',);
           }

         else{
           return CreateOrderResponse(order:null, message:UtilsConst.lang == 'en'? 'An Error occurred in the payment process ,check the balance or internet connection':'حدث خطأ في عملية الدفع ، تأكد من الرصيد او من الاتصال بالانترنت');

         }
        }


      // /// Old Order
      // else {
      //   if (customer_order_id == null)
      //     throw Exception();
      //
      //   orderRequest = CreateOrderRequest(
      //       userId: uId!,
      //       storeId: storeId,
      //       vipOrder: orderType,
      //       destination: destination,
      //       phone: phoneNumber,
      //       payment: paymentMethod,
      //       paymentState: false,
      //       products: products,
      //       numberOfMonth: numberOfMonth,
      //       deliveryTime: deliveryTimes,
      //       orderValue: amount,
      //       startDate: date.toIso8601String(),
      //       description: description!,
      //       addressName: addressName,
      //       cardId: cardId,
      //       customerOrderID: customer_order_id,
      //       productsIdes: productsIds!,
      //       note: note,
      //       orderSource: orderSource,
      //       ar_description: arDescription!,
      //       buildingHomeNumber: buildingHomeId
      //
      //   );
      //   orderRequest.status = OrderStatus.INIT.name;
      //
      //
      //   orderSnapShot = await _orderRepository.addNewOrder(
      //       orderRequest);
      //
      //   /// Here is the payment process (After adding the order to the data base)
      //   if(paymentMethod == PaymentMethodConst.CREDIT_CARD){
      //     bool paymentResult =  await _paymentProcess(paymentMethodID:cardId!, products: products);
      //     if(paymentResult)
      //     {
      //       print('msg: success payment , tag: order service');
      //       Map<String, dynamic> map = orderSnapShot.data() as Map<String, dynamic>;
      //       map['id'] = orderSnapShot.id;
      //
      //       /// Update Payment Order State (You must be in the cloud function for the complete scenario)
      //       await _updateOrderPaymentState(orderSnapShot.id);
      //
      //
      //       return CreateOrderResponse(order: OrderModel.mainDetailsFromJson(map), message: 'Success');
      //
      //     }
      //
      //     else{
      //       return CreateOrderResponse(order:null, message: 'Payment Field');
      //     }
      //   }
      // }
      // DocumentSnapshot orderSnapShot = await _orderRepository.addNewOrder(
      //     orderRequest);



      // bool purchaseResponse =  await _purchaseServices.createPurchase(amount: amount, cardId: cardId, userId: uId, orderID: orderSnapShot.id, date: DateTime.now().toIso8601String());
      // if(!purchaseResponse){
      //   throw Exception();
      // }

      // await createpurchase(amount: amount, cardId: cardId!, userId: uId, orderID: orderSnapShot.id, date: DateTime.now());
      Map<String, dynamic> map = orderSnapShot.data() as Map<String, dynamic>;
      map['id'] = orderSnapShot.id;
      return CreateOrderResponse(order: OrderModel.mainDetailsFromJson(map), message:UtilsConst.lang == 'en'? 'Your order has been Successfully sent':'تم ارسال طلبك بنجاح');

    }catch(e){
      if(e is PaymentFieldException)
        {
          return CreateOrderResponse(order:null, message:UtilsConst.lang == 'en'? 'An Error occurred in the payment process ,check the balance or internet connection':'حدث خطأ في عملية الدفع ، تأكد من الرصيد او من الاتصال بالانترنت');
        }
      return CreateOrderResponse(order:null, message:UtilsConst.lang == 'en'?'An error occurred , try again !':'حدث خطأ, حاول مجددا');
    }
  }


  /// Payment Process
  /// Input (method id , items)
  /// output (bool , true if result is success)
  Future<bool> _paymentProcess(
      {required String paymentMethodID,required List<ProductModel> products})async {
    List<Map<String, dynamic>> items = [];
    products.forEach((element) {
      items.add({
        'id':element.id,
        'price':element.price,
        'quantity': element.orderQuantity

      });
    });
    try{
      PaymentState paymentState = await PaymentService().pay(paymentMethodID: paymentMethodID, items: items);
      if(paymentState.status == PaymentStates.success)
        return true;

      else ///(paymentState.status == PaymentStates.failure)
        return false;

    }catch(e){
      print('Exception Payment');
      print(e.toString());
      /// An error occurred in the payment process
      /// Customize Exception
      throw PaymentFieldException(e.toString());
    }
  }

  /// Update Payment State From false to true
  Future<bool> _updateOrderPaymentState(String orderId)async{
    try{
      UpdateOrderRequest _request = UpdateOrderRequest(orderID: orderId);
      _request.paymentState = true;
      await _orderRepository.updateOrder(_request);
      return true;
    }catch(e){
      return false;
    }
  }

 // Future<bool> createpurchase(
 //     {required double amount,required String cardId,required String userId,required String orderID,required DateTime date})async{
 //   bool purchaseResponse =  await _purchaseServices.createPurchase(amount: amount, cardId: cardId, userId: userId, orderID: orderID, date: DateTime.now().toIso8601String());
 //   if(!purchaseResponse){
 //     throw Exception();
 //   }
 //   return true;
 //  }

  closePendingStream(){
    pendingOrdersPublishSubject.close();
    pendingDocumentList.clear();

  }
  closeFinishedStream(){
    finishedOrdersPublishSubject.close();
    finishedDocumentList.clear();
  }
  Future<bool> deleteOrder(String orderId)async{
      bool response = await  _orderRepository.deleteOrder(orderId);
      if(response){
        return true;
      }else{
        return false;
      }
  }

 // Future<CreateOrderResponse> reorder(String orderID)async {
 //    try{
 //      OrderModel? order =  await getOrderDetails(orderID);
 //
 //      if(order == null){
 //        return CreateOrderResponse(order: null ,message: 'Error in Get Detail For Re order');
 //      }
 //      else{
 //
 //        CreateOrderResponse response = await addNewOrder(orderSource: order.orderSource, note: order.note, storeId:order.storeId,productsIds: order.productIds,customerOrderID:order.customerOrderID,products: order.products, addressName: order.addressName, deliveryTimes: order.deliveryTime, orderType: order.vipOrder, destination: order.destination, phoneNumber: order.phone, paymentMethod: order.payment, amount: order.orderValue, cardId: order.cardId, numberOfMonth: order.numberOfMonth,
 //            reorder: true,
 //            description: order.description,
 //            arDescription: order.ar_description,
 //            buildingHomeId: order.buildingHomeId,
 //
 //        );
 //        return response;
 //      }
 //    }catch(e){
 //      if(e is ShopException)
 //      {
 //        return CreateOrderResponse(order:null, message: 'Payment Field');
 //      }
 //      return CreateOrderResponse(order:null, message: 'Create Order Field');
 //    }
 //    }






  Future<void> getNotifications()async {
    String? uid = await _authPrefsHelper.getUserId();
    _orderRepository.getNotifications(uid!).listen((event) {
     List<NotificationModel> notifications = [];
      event.docs.forEach((element2) {
        Map <String, dynamic> not = element2.data() as Map<String,
            dynamic>;
        // if(order['userId'] == uid) {
        //
        // }



        not['id'] = element2.id;

        NotificationModel  notificationModel = NotificationModel.fromJson(not);
        notifications.add(notificationModel);
      }
      );


     notificationsPublishSubject.add(notifications);

    }).onError((e){
      notificationsPublishSubject.add(null);
    });
  }

  Future<OrderModel?>  addNewOffer()async {}


}

