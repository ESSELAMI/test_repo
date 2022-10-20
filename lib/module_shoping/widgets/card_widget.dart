import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:my_kom/consts/colors.dart';
import 'package:my_kom/module_authorization/presistance/auth_prefs_helper.dart';
import 'package:my_kom/module_shoping/bloc/payment_bloc.dart';
import 'package:my_kom/module_shoping/bloc/payment_methodes_bloc.dart';
import 'package:my_kom/module_shoping/models/card_model.dart';
import 'package:my_kom/utils/size_configration/size_config.dart';

showCardWidget(BuildContext context, PaymentMethodsBloc paymentMethodsBloc) {
  String email = 'mykom_user@gmail.com';
  String phone = '';
  final PaymentBloc _paymentBloc = PaymentBloc();
  final AuthPrefsHelper _authPrefsHelper = AuthPrefsHelper();

  late CardFormEditController iosCardController;
  late CardEditController androidCardController;
  late CardModel _cardModel;

  /// Get User Information (Email , Phone)
  _authPrefsHelper.getEmail().then((value) {
    email = value!;
  });
  _authPrefsHelper.getPhone().then((value) {
    phone = value!;
  });

  showMaterialModalBottomSheet(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30), topRight: Radius.circular(30)),
    ),
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      height: SizeConfig.screenHeight * 0.57,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
          controller: ModalScrollController.of(context),
          child: BlocConsumer<PaymentBloc, PaymentState>(
              bloc: _paymentBloc,
              listener: (context, state) {
                if (state.status == PaymentStates.failure) {
                  Fluttertoast.showToast(
                      msg: 'An error occurred, please try again',
                      gravity: ToastGravity.TOP,
                      fontSize: 14.0,
                      textColor:Colors.white,
                      backgroundColor:Colors.red,
                      toastLength: Toast.LENGTH_LONG
                  );
                  Navigator.pop(context);
                  //  ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content:Text('An error occurred, please try again')));
                } else if (state.status == PaymentStates.success) {
                  _cardModel.cardId = state.paymentMethod!.id;
                  paymentMethodsBloc.addOne(_cardModel);
                  Fluttertoast.showToast(
                      msg: 'Card Added Successfully',
                      gravity: ToastGravity.TOP,
                      textColor:Colors.white,
                      backgroundColor:ColorsConst.mainColor,
                      fontSize: 14.0,
                    toastLength: Toast.LENGTH_LONG
                  );
                  //ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content:Text('Card Added Successfully')));
                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                if (Platform.isIOS) {
                  iosCardController = CardFormEditController(
                      initialDetails: state.cardFieldInputDetails);
                } else {
                  androidCardController = CardEditController(
                      initialDetails: state.cardFieldInputDetails);
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        child: Platform.isIOS
                            ?

                            /// Ios Style (card)
                            CardFormField(
                                controller: iosCardController,
                                style: CardFormStyle(
                                  backgroundColor:
                                      ColorsConst.mainColor.withOpacity(0.2),
                                  borderColor: ColorsConst.mainColor,
                                ),

                              )

                            /// Android style (line)
                            : CardField(
                                controller: androidCardController,
                              ),
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.screenHeight * 0.15,
                    ),
                    state.status == PaymentStates.loading
                        ? Center(
                            child: Container(
                                height: 25.0,
                                width: 25.0,
                                child: Platform.isIOS
                                    ? CupertinoActivityIndicator()
                                    : CircularProgressIndicator()),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: ColorsConst.mainColor),
                            onPressed: () async {
                              if (Platform.isIOS) {
                                if (iosCardController.details.complete) {
                                  _cardModel = CardModel(
                                      cardId: '',
                                      cardNumber: iosCardController
                                          .details.last4
                                          .toString(),
                                      type: iosCardController.details.brand
                                          .toString());

                                  _paymentBloc
                                      .createPaymentMethod(BillingDetails(
                                    email: email,
                                    phone: phone,
                                  ));
                                }else{
                                  _paymentBloc.emitFormIsNotCompleted();
                                }
                              } else {
                                if (androidCardController.details.complete) {
                                  _cardModel = CardModel(
                                      cardId: '',
                                      cardNumber: androidCardController
                                          .details.last4
                                          .toString(),
                                      type: androidCardController.details.brand
                                          .toString());

                                  _paymentBloc
                                      .createPaymentMethod(BillingDetails(
                                    email: email,
                                    phone: phone,
                                  ));
                                }else{
                                  _paymentBloc.emitFormIsNotCompleted();
                                }
                              }
                            },
                            child: Container(
                                width: 100,
                                child: Center(child: const Text('Add')))),
                    SizedBox(
                      height: 12,
                    ),
                    if(state.status == PaymentStates.form_not_completed)
                    Center(
                      child: Text('Form not completed !',style: TextStyle(fontSize: 13.0 , color: Colors.red.shade600,fontWeight: FontWeight.bold),),
                    )
                  ],
                );
              })),
    ),
  );
}
