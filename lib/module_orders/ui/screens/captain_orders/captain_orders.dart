import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_kom/consts/colors.dart';
import 'package:my_kom/consts/utils_const.dart';
import 'package:my_kom/module_authorization/bloc/is_loggedin_cubit.dart';
import 'package:my_kom/module_authorization/screens/widgets/login_sheak_alert.dart';
import 'package:my_kom/module_authorization/screens/widgets/top_snack_bar_widgets.dart';
import 'package:my_kom/module_map/models/address_model.dart';
import 'package:my_kom/module_orders/model/order_model.dart';
import 'package:my_kom/module_orders/orders_routes.dart';
import 'package:my_kom/module_orders/service/orders/orders.service.dart';
import 'package:my_kom/module_orders/state_manager/batch_bloc.dart';
import 'package:my_kom/module_orders/state_manager/captain_orders/orders_bloc.dart';
import 'package:my_kom/module_orders/state_manager/order_detail_bloc.dart';
import 'package:my_kom/module_orders/ui/widgets/no_data_for_display_widget.dart';
import 'package:my_kom/module_shoping/bloc/shopping_cart_bloc.dart';
import 'package:my_kom/module_shoping/models/cart_arrguments.dart';
import 'package:my_kom/module_shoping/shoping_routes.dart';
import 'package:my_kom/utils/size_configration/size_config.dart';
import 'package:my_kom/generated/l10n.dart';
import 'package:load/load.dart';

class UserOrdersScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  late final PendingOrdersListBloc _pendingOrdersListBloc ;
  late final FinishedOrdersListBloc _finishedOrdersListBloc ;
  late final OrderDetailBloc _orderDetailBloc ;
  late final ScrollController _pendingOrdersScrollController ;
  late final ScrollController _finishedOrdersScrollController ;

  late final OrdersService _ordersService;
  late final IsLogginCubit isLogginCubit;
  final String CURRENT_ORDER = 'current';
  final String PREVIOUS_ORDER = 'previous';
  late String current_tap ;
  @override
  void initState() {
    current_tap = CURRENT_ORDER;
    _ordersService = OrdersService();
    _orderDetailBloc  = OrderDetailBloc();
    _pendingOrdersListBloc = PendingOrdersListBloc(_ordersService);
    _finishedOrdersListBloc = FinishedOrdersListBloc(_ordersService);
    isLogginCubit = IsLogginCubit();
    _pendingOrdersScrollController = ScrollController();
    _pendingOrdersScrollController.addListener(_pendingScrollListener);
    _finishedOrdersScrollController = ScrollController();
    _finishedOrdersScrollController.addListener(_finishedScrollListener);

    super.initState();
  }
  @override
  void dispose() {
    isLogginCubit.close();
    _pendingOrdersListBloc.close();
    _finishedOrdersListBloc.close();
    _orderDetailBloc.close();
    isLogginCubit.close();
    _pendingOrdersScrollController.dispose();
    _finishedOrdersScrollController.dispose();

    super.dispose();
  }

  void _pendingScrollListener() {
    if (_pendingOrdersScrollController.offset == _pendingOrdersScrollController.position.maxScrollExtent &&
        !_pendingOrdersScrollController.position.outOfRange) {
      _pendingOrdersListBloc.fetchNextOrders();
    }
  }

  void _finishedScrollListener() {
    if (_finishedOrdersScrollController.offset >= _finishedOrdersScrollController.position.maxScrollExtent &&
        !_finishedOrdersScrollController.position.outOfRange) {
      _finishedOrdersListBloc.fetchNextFinishedOrders();
    }
  }
  @override
  Widget build(BuildContext context) {
  return BlocConsumer<IsLogginCubit,IsLogginCubitState>(
    bloc: isLogginCubit,
      listener: (context,state){
      if(state ==IsLogginCubitState.LoggedIn)
        {
          _pendingOrdersListBloc.getMyOrders();
          _finishedOrdersListBloc.getFinishedOrders();
        }
      if(state == IsLogginCubitState.NotLoggedIn)
        loginCheakAlertWidget(context);
      },
      builder: (context,state){
        if(state == IsLogginCubitState.LoggedIn){
          return  Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
                    child: Text(S.of(context)!.orders,style: GoogleFonts.lato(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54
                    ),),
                  ),
                  SizedBox(height: 8,),
                  getOrderSwitcher(),
                  SizedBox(height: 8,),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      child: current_tap == CURRENT_ORDER
                          ? getCurrentOrders()
                          : getPreviousOrders(),
                    ),
                  ),
                ],
              ),
            ),

          );
        }else{
          return Scaffold(
            backgroundColor: Colors.white,
          );
        }
      });


  }
  Widget getOrderSwitcher() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.widhtMulti * 3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                current_tap = CURRENT_ORDER;
                if (mounted) {
                  setState(() {});
                }
              },
              child: BlocBuilder<PendingOrdersListBloc ,CaptainOrdersListStates >(
                  bloc: _pendingOrdersListBloc,
                  builder: (context,state) {
                    int curNumber =0;

                    if(state is CaptainOrdersListSuccessState){
                      curNumber = state.orders.length;

                    }
                    return AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        padding: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: current_tap == CURRENT_ORDER
                              ? ColorsConst.mainColor
                              : Colors.transparent,
                        ),
                        child: Center(child: Text('${S.of(context)!.currentOrders} (${curNumber})',style: TextStyle(
                            color: current_tap == CURRENT_ORDER ?Colors.white: ColorsConst.mainColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5
                        ),)));
                  }
              ),
            ),
          ),
          Expanded(
            child:GestureDetector(
              onTap: () {
                current_tap = PREVIOUS_ORDER;

                if (mounted) {
                  setState(() {});
                }
              },
              child: BlocBuilder<FinishedOrdersListBloc ,CaptainOrdersListStates >(
                  bloc: _finishedOrdersListBloc,
                  builder: (context,state) {
                    int preNumber =0;

                    if(state is CaptainOrdersListSuccessState){
                      preNumber = state.orders.length;

                    }
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      padding: EdgeInsets.symmetric(vertical:6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),

                        color:    current_tap == PREVIOUS_ORDER
                            ? ColorsConst.mainColor
                            : Colors.transparent,
                      ),
                      child:Center(child: Text('${S.of(context)!.previousOrders} (${preNumber})',style: TextStyle(
                          color: current_tap == PREVIOUS_ORDER ?Colors.white: ColorsConst.mainColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5
                      ))),
                    );
                  }
              ),
            ),
          )

        ],
      ),
    );
  }
  Future<void> onRefreshMyOrder()async {
    _pendingOrdersListBloc.getMyOrders();
    _finishedOrdersListBloc.getFinishedOrders();
  }
 Widget getCurrentOrders(){
    return BlocConsumer<PendingOrdersListBloc ,CaptainOrdersListStates >(
      bloc: _pendingOrdersListBloc,
      listener: (context ,state){
      },
      builder: (maincontext,state) {

         if(state is CaptainOrdersListErrorState)
          return Center(
            child: GestureDetector(
              onTap: (){

              },
              child: Container(
                color: ColorsConst.mainColor,
                padding: EdgeInsets.symmetric(),
                child: Text(state.message,style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),),
              ),
            ),
          );

        else if(state is CaptainOrdersListSuccessState) {
           List<OrderModel> orders = state.orders;

           if(orders.isEmpty)
             return Center(
               child:   NoDataForDisplayWidget()
             );
           else
          return RefreshIndicator(
          onRefresh: ()=>onRefreshMyOrder(),
          child: Scrollbar(
            child: ListView.separated(
              itemCount:orders.length +1,
              controller: _pendingOrdersScrollController,
              separatorBuilder: (context,index){
                return SizedBox(height: 8,);
              },
              itemBuilder: (context,index){
                if(index == orders.length){
                  return BlocBuilder<BatchBloc,BatchStates>(
                    bloc: _pendingOrdersListBloc.batchBloc,
                    builder: (BuildContext context, state) {

                      if(state is BatchLoadingState){
                        return Container(
                          margin: EdgeInsets.only(bottom: 20),
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          alignment: Alignment.center,
                          width: double.infinity,
                          child: SizedBox(
                            height: 20,width: 20,
                            child: Platform.isIOS? CupertinoActivityIndicator():CircularProgressIndicator(),
                          ),
                        );
                      }else if (state is BatchErrorState)
                      {
                        return Center(child: Text(S.of(context)!.fetchOrdersErrorMessage,textAlign: TextAlign.center,style: TextStyle(fontSize: 13,color: Colors.black54),),);
                      }else if (state is BatchSuccessState)
                      {
                        if(state.length == 0)
                          return Center(child: Text(S.of(context)!.fetchOrdersDoneMessage,textAlign: TextAlign.center,style: TextStyle(fontSize: 13,color: Colors.black54),),);
                        else  return SizedBox.shrink();
                      }
                      else  return SizedBox.shrink();

                    },);
                }
                return Container(
                  height: 180,
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(horizontal: 16,vertical: 5),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius:1,
                        spreadRadius: 1
                      )
                    ],
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 50,height: 50,
                          child: Image.asset('assets/order_icon.png'),),
                          SizedBox(width: 15,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [

                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8,vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: ColorsConst.mainColor.withOpacity(0.1)
                                      ),
                                      child: Text('${S.of(context)!.orderNumber} : '+orders[index].customerOrderID.toString() ,style: GoogleFonts.lato(
                                          color: ColorsConst.mainColor,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.bold
                                      ),),
                                    )
                                  ],
                                ),
                                SizedBox(height: 8,),
                                 Text((UtilsConst.lang == 'en')?orders[index].description:orders[index].ar_description,overflow: TextOverflow.ellipsis,maxLines: 2,style: GoogleFonts.lato(

                                      fontSize: 12,

                                      color: Colors.black87,
                                      fontWeight: FontWeight.w800
                                  ),
                                ),
                                SizedBox(height:6,),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined , color: Colors.black45,size: 12,),
                                    Expanded(
                                      child: Text(orders[index].addressName,overflow: TextOverflow.ellipsis,style: GoogleFonts.lato(
                                        fontSize: 12,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w800,

                                      )),
                                    )

                                  ],),
                                SizedBox(height: 6,),
                                Text('${orders[index].orderValue.toString()}  ${UtilsConst.lang == 'en'? 'AED':'د.إ'}',style: GoogleFonts.lato(
                                    fontSize: 14.0,
                                    color: ColorsConst.mainColor,
                                    fontWeight: FontWeight.bold
                                )),
                                SizedBox(height: 4,),

                              ],
                            ),
                          ),

                        ],
                      ),
                      Spacer(),
                      SizedBox(height: 4,),
                      Container(
                        height: 30,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                    color: Colors.white
                                    ,
                                    border: Border.all(
                                        color: ColorsConst.mainColor,
                                        width: 2
                                    ),
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                child: MaterialButton(
                                  onPressed: () {
                                    Navigator.pushNamed(maincontext, OrdersRoutes.ORDER_DETAIL_SCREEN,arguments: orders[index].id);
                                  },
                                  child: Text(S.of(context)!.orderDetail, style: TextStyle(
                                      color: ColorsConst.mainColor,
                                      fontSize: 14.0),),

                                ),
                              ),
                            ),
                            SizedBox(width: SizeConfig.widhtMulti * 3,),
                            Expanded(child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                  color: ColorsConst.mainColor,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: MaterialButton(
                                onPressed: () {

                                Navigator.pushNamed(maincontext, OrdersRoutes.ORDER_STATUS_SCREEN,arguments:  orders[index].id);
                                },
                                child: Text(S.of(context)!.trackShipment, style: TextStyle(color: Colors.white,
                                    fontSize: 14.0),),

                              ),
                            ))
                            ,
                          ],
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),
          ),
        );}
        else  return Center(
             child: Container(
               width: 30,
               height: 30,
               child: Platform.isIOS?CupertinoActivityIndicator(): CircularProgressIndicator(color: ColorsConst.mainColor,),
             ),
           );

      }
    );
  }

  Widget getPreviousOrders(){
    return BlocConsumer<FinishedOrdersListBloc ,CaptainOrdersListStates >(
        bloc: _finishedOrdersListBloc,
        listener: (context ,state){
        },
        builder: (maincontext,state) {

          if(state is CaptainOrdersListErrorState)
            return Center(
              child: GestureDetector(
                onTap: (){

                },
                child: Container(
                  color: ColorsConst.mainColor,
                  padding: EdgeInsets.symmetric(),
                  child: Text(state.message,style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),),
                ),
              ),
            );

          else if(state is CaptainOrdersListSuccessState) {
            List<OrderModel> orders = state.orders;

            if(orders.isEmpty)
              return Center(
                child:  NoDataForDisplayWidget(),
              );
            else
              return RefreshIndicator(
                onRefresh: ()=>onRefreshMyOrder(),
                child: Stack(
                  children: [
                    Scrollbar(child:  ListView.separated(
                      itemCount:orders.length +1,
                      controller: _finishedOrdersScrollController,
                      separatorBuilder: (context,index){
                        return SizedBox(height: 8,);
                      },
                      itemBuilder: (context,index){
                        if(index == orders.length){
                          return BlocBuilder<BatchBloc,BatchStates>(
                            bloc: _finishedOrdersListBloc.batchBloc,
                            builder: (BuildContext context, state) {

                              if(state is BatchLoadingState){
                                return Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  padding: EdgeInsets.symmetric(vertical: 32.0),
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                  child: SizedBox(
                                    height: 20,width: 20,
                                    child: Platform.isIOS? CupertinoActivityIndicator():CircularProgressIndicator(),
                                  ),
                                );
                              }else if (state is BatchErrorState)
                              {
                                return Center(child: Text(S.of(context)!.fetchOrdersErrorMessage,textAlign: TextAlign.center,style: TextStyle(fontSize: 13,color: Colors.black54),),);
                              }else if (state is BatchSuccessState)
                              {
                                if(state.length == 0)
                                  return Center(child: Text(S.of(context)!.fetchOrdersDoneMessage,textAlign: TextAlign.center,style: TextStyle(fontSize: 13,color: Colors.black54),),);
                                else  return SizedBox.shrink();
                              }
                              else  return SizedBox.shrink();

                            },);
                        }else
                          return Container(
                            height: 180,
                            width: double.infinity,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.symmetric(horizontal: 16,vertical: 5),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius:1,
                                    spreadRadius: 1
                                )
                              ],
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [

                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8,vertical: 2),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          color: ColorsConst.mainColor.withOpacity(0.1)
                                      ),
                                      child: Text('${S.of(context)!.orderNumber} : '+orders[index].customerOrderID.toString() ,style: GoogleFonts.lato(
                                          color: ColorsConst.mainColor,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.bold
                                      ),),
                                    )
                                  ],
                                ),
                                SizedBox(height: 8,),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text((UtilsConst.lang == 'en')?orders[index].description:orders[index].ar_description,overflow: TextOverflow.ellipsis,maxLines: 2,style: GoogleFonts.lato(

                                      fontSize: 12.0,

                                      color: Colors.black87,
                                      fontWeight: FontWeight.w800
                                  ),
                                  ),
                                ),
                                SizedBox(height: 4.0,),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined , color: Colors.black45,size: 12,),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(orders[index].addressName,overflow: TextOverflow.ellipsis,style: GoogleFonts.lato(
                                          fontSize: 12.0,
                                          color: Colors.black45,
                                          fontWeight: FontWeight.w800,

                                        )),
                                      ),
                                    )

                                  ],),
                                SizedBox(height: 6.0,),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${orders[index].orderValue.toString()}  ${UtilsConst.lang == 'en'? 'AED':'د.إ'}' ,style: GoogleFonts.lato(
                                      fontSize: 14.0,
                                      color: ColorsConst.mainColor,
                                      fontWeight: FontWeight.bold
                                  )),
                                ),
                                SizedBox(height: 6.0,),
                                Spacer(),
                                Container(
                                  height: 30.0,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                              color: Colors.white
                                              ,
                                              border: Border.all(
                                                  color: ColorsConst.mainColor,
                                                  width: 2.0
                                              ),
                                              borderRadius: BorderRadius.circular(10)
                                          ),
                                          child: MaterialButton(
                                            onPressed: () {
                                              Navigator.pushNamed(context, OrdersRoutes.ORDER_DETAIL_SCREEN,arguments: orders[index].id);
                                            },
                                            child: Text(S.of(context)!.orderDetail, style: TextStyle(
                                                color: ColorsConst.mainColor,
                                                fontSize: 14.0),),

                                          ),
                                        ),
                                      ),
                                      SizedBox(width: SizeConfig.widhtMulti * 3.0,),
                                      Expanded(child:
                                      Container(
                                        height: 30.0,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                            color: ColorsConst.mainColor,
                                            borderRadius: BorderRadius.circular(10.0)
                                        ),
                                        child: MaterialButton(
                                          onPressed: () {
                                            _orderDetailBloc.getDetailForReorder(orderId: orders[index].id);
                                          },
                                          child: Text(S.of(context)!.reOrder, style: TextStyle(color: Colors.white,
                                              fontSize: 14.0),),

                                        ),
                                      )
                                      )
                                      ,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                      },
                    ),),

                    BlocListener<OrderDetailBloc,OrderDetailStates>(
                      bloc: _orderDetailBloc,
                      listener: (context,state)async{
                      if(state is OrderDetailSuccessState)
                      {
                        hideLoadingDialog();
                        await shopCartBloc.startedShop();

                        state.data.products.forEach((element) {
                          shopCartBloc.addProductsToCart(element, element.orderQuantity == null ?0:element.orderQuantity!);
                        });
                        AddressModel _address = AddressModel(description: state.data.addressName, latitude: state.data.destination.lat, longitude: state.data.destination.lon, geoData: {});
                        CartArguments _cart_arg = CartArguments(addressModel: _address, phone: state.data.phone, note: state.data.note, buildingId: state.data.buildingHomeId, vip: state.data.vipOrder);
                        Navigator.pushNamedAndRemoveUntil(context, ShopingRoutes.SHOPE_SCREEN, (route) => false,arguments:_cart_arg );
                      }
                      else if(state is OrderDetailErrorState)
                      {
                        hideLoadingDialog();
                        snackBarErrorWidget(context,UtilsConst.lang == 'en'?  'An error occurred':'حدث خطأ, يرجى المحاولة مجددا');
                      }
                      else if(state is OrderDetailLoadingState){
                        showCustomLoadingWidget(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(30.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 40.0,
                                    height: 40.0,
                                    color: Colors.transparent,
                                    child: Platform.isIOS?CupertinoActivityIndicator(
                                      radius: 12.0,
                                      color:  Colors.white,
                                    ):CircularProgressIndicator(color: Colors.white,),
                                  ),
                                  Container(
                                    height: 10.0,
                                  ),

                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: SizedBox.shrink(),
                    ),
                    // BlocConsumer<NewOrderBloc,CreateOrderStates>(
                    //     bloc: _orderBloc,
                    //     listener: (context,state)async{
                    //       if(state is CreateOrderSuccessState)
                    //       {
                    //         snackBarSuccessWidget(context,UtilsConst.lang == 'en'? 'Order Created Successfully!!':'تم إرسال الطلب بنجاح');
                    //       }
                    //       else if(state is CreateOrderErrorState)
                    //       {
                    //         snackBarSuccessWidget(context,UtilsConst.lang == 'en'?  'The Order Was Not Created!!':'حدث خطأ, يرجى المحاولة مجددا');
                    //       }
                    //     },
                    //     builder: (context,state) {
                    //       bool isLoading = state is CreateOrderLoadingState?true:false;
                    //
                    //       return isLoading? Center(child: Container(
                    //         width: 30,
                    //         height: 30,
                    //         child:Platform.isIOS?CupertinoActivityIndicator(): CircularProgressIndicator(color: ColorsConst.mainColor,),
                    //       ),):SizedBox.shrink();
                    //
                    //     }
                    // ),

                  ],
                ),
              );}
          else  return Center(
              child: Container(
                width: 40.0,
                height: 40.0,
                child:Platform.isIOS ?CupertinoActivityIndicator(): CircularProgressIndicator(color: ColorsConst.mainColor,),
              ),
            );

        }
    );
  }

}
