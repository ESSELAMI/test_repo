
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_kom/module_orders/model/order_model.dart';
import 'package:my_kom/module_orders/service/orders/orders.service.dart';
import 'package:my_kom/module_orders/state_manager/batch_bloc.dart';


/// Pending Orders Bloc
class PendingOrdersListBloc extends Bloc<CaptainOrdersListEvent,CaptainOrdersListStates>{
  final OrdersService _ordersService;
  final BatchBloc _batchBloc = BatchBloc();

  get batchBloc => _batchBloc;
  PendingOrdersListBloc(this._ordersService) : super(CaptainOrdersListLoadingState()) {

    on<CaptainOrdersListEvent>((CaptainOrdersListEvent event, Emitter<CaptainOrdersListStates> emit) {
      if (event is CaptainOrdersListLoadingEvent)
        {
          emit(CaptainOrdersListLoadingState());

        }
      else if (event is CaptainOrdersListErrorEvent){
        emit(CaptainOrdersListErrorState(message: event.message));
      }

      else if (event is CaptainOrdersListSuccessEvent){
        emit(CaptainOrdersListSuccessState(orders: event.orders,message: null));
      }
    });
  }



  void getMyOrders() {

     this.add(CaptainOrdersListLoadingEvent());
     _ordersService.pendingOrdersPublishSubject.listen((value) {

       if(value != null){
         this.add(CaptainOrdersListSuccessEvent(orders: value));

       }else
       {
         this.add(CaptainOrdersListErrorEvent(message: 'Error In Fetch Data !!'));
       }
     });
     _ordersService.getMyOrders();
  }

  /// Page Init
 void fetchNextOrders()  {
   _batchBloc.emitLoadingState();
    _ordersService.fetchNextOrders().then((value) {
      if(value){
        _batchBloc.emitInitState();
      }else{
        _batchBloc.emitErrorState();
      }
    });
  }


  @override
  Future<void> close() {
    print('close pending stream from bloc layer++++++++++++++++++++++');
    _batchBloc.close();
    _ordersService.closePendingStream();
    return super.close();
  }
}


/// Finished Orders Bloc
class FinishedOrdersListBloc extends Bloc<CaptainOrdersListEvent,CaptainOrdersListStates>{
  final OrdersService _ordersService ;

  final BatchBloc _batchBloc = BatchBloc();
  get batchBloc => _batchBloc;
  FinishedOrdersListBloc(this._ordersService) : super(CaptainOrdersListLoadingState()) {

    on<CaptainOrdersListEvent>((CaptainOrdersListEvent event, Emitter<CaptainOrdersListStates> emit) {
      if (event is CaptainOrdersListLoadingEvent)
      {
        emit(CaptainOrdersListLoadingState());

      }
      else if (event is CaptainOrdersListErrorEvent){
        emit(CaptainOrdersListErrorState(message: event.message));
      }

      else if (event is CaptainOrdersListSuccessEvent){
        emit(CaptainOrdersListSuccessState(orders:event.orders,message: null));
      }
    });
  }



  void getFinishedOrders() {

    this.add(CaptainOrdersListLoadingEvent());
    _ordersService.finishedOrdersPublishSubject.listen((value) {

      if(value != null){
        this.add(CaptainOrdersListSuccessEvent(orders: value));

      }else
      {
        this.add(CaptainOrdersListErrorEvent(message: 'Error In Fetch Data !!'));
      }
    });
    _ordersService.getFinishedMyOrders();
  }


  /// Page Init
  void fetchNextFinishedOrders()  {
    _batchBloc.emitLoadingState();
    _ordersService.fetchNextFinishedOrders().then((value) {
      if(value){
        _batchBloc.emitInitState();
      }else{
        _batchBloc.emitErrorState();
      }
    });

  }

  @override
  Future<void> close() {
    _batchBloc.close();
    _ordersService.closeFinishedStream();
    return super.close();
  }
}


abstract class CaptainOrdersListEvent { }
class CaptainOrdersListInitEvent  extends CaptainOrdersListEvent  {}

class CaptainOrdersListSuccessEvent  extends CaptainOrdersListEvent  {
  List<OrderModel>  orders;
  CaptainOrdersListSuccessEvent({required this.orders});
}
class CaptainOrdersListLoadingEvent  extends CaptainOrdersListEvent  {}

class CaptainOrdersListErrorEvent  extends CaptainOrdersListEvent  {
  String message;
  CaptainOrdersListErrorEvent({required this.message});
}

class CaptainOrderDeletedErrorEvent  extends CaptainOrdersListEvent  {
  String message;
  CaptainOrderDeletedErrorEvent({required this.message});
}


class CaptainOrderDeletedSuccessEvent  extends CaptainOrdersListEvent  {
  String orderID;
  CaptainOrderDeletedSuccessEvent({required this.orderID});
}



abstract class CaptainOrdersListStates {}

class CaptainOrdersListInitState extends CaptainOrdersListStates {}

class CaptainOrdersListSuccessState extends CaptainOrdersListStates {
  List<OrderModel>  orders;

  String? message;
  CaptainOrdersListSuccessState({required this.orders,required this.message});
}
class CaptainOrdersListLoadingState extends CaptainOrdersListStates {}

class CaptainOrdersListErrorState extends CaptainOrdersListStates {
  String message;
  CaptainOrdersListErrorState({required this.message});
}

class CaptainOrderDeletedErrorState extends CaptainOrdersListStates {
  String message;
  List<OrderModel>  data;
  CaptainOrderDeletedErrorState({ required this.data,required this.message});
}




