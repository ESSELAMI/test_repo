// import 'dart:convert';
//
// import 'package:equatable/equatable.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http;
//
// class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
//
//   /// Urls Cloud Functions
//   /// Urls Cloud Functions
//   final String _paymentEndPointMethodIdUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointMethodId';
//   final String _paymentEndPointIntentIdUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointIntentId';
//
//
//   PaymentBloc() : super(const PaymentState()) {
//     on<PaymentStart>(_onPaymentStart);
//     on<PaymentCreateIntent>(_onPaymentCreateIntent);
//     on<PaymentConfirmIntent>(_onPaymentConfirmIntent);
//   }
//
//   _onPaymentStart(PaymentStart event, Emitter<PaymentState> emit) {
//     emit(state.copyWith(status: PaymentStates.initial));
//   }
//
//   _onPaymentCreateIntent(PaymentCreateIntent event,
//       Emitter<PaymentState> emit) async {
//     emit(state.copyWith(status: PaymentStates.loading));
//     final paymentMethod = await Stripe.instance.createPaymentMethod(
//
//       PaymentMethodParams.card(paymentMethodData: PaymentMethodData(
//           billingDetails: event.billingDetails)),
//     );
//     final paymentIntentResults = await _callPaymentEndPointMethodId(
//         useStripeSdk: true,
//         paymentMethodId: paymentMethod.id,
//         currency: 'aed',
//         items: event.items
//     );
//     print(paymentIntentResults);
//     if (paymentIntentResults['error'] != null) {
//       emit(state.copyWith(status: PaymentStates.failure));
//     }
//     if (paymentIntentResults['clientSecret'] != null &&
//         paymentIntentResults['requiresAction'] == null
//     ) {
//       emit(state.copyWith(status: PaymentStates.success));
//     }
//     if (paymentIntentResults['clientSecret'] != null &&
//         paymentIntentResults['requiresAction'] == true
//     ){
//       final String clientSecret = paymentIntentResults['clientSecret'];
//       add(PaymentConfirmIntent(clientSecret: clientSecret));
//     }
//   }
//
//   _onPaymentConfirmIntent(PaymentConfirmIntent event,
//       Emitter<PaymentState> emit) async {
//     try {
//       final paymentIntent = await Stripe.instance.handleNextAction(event.clientSecret);
//       if(paymentIntent.status == PaymentIntentsStatus.RequiresPaymentMethod){
//         Map<String , dynamic> results =  await _callPaymentEndPointIntentId(paymentIntentId:paymentIntent.id);
//         if(results['error'] != null){
//           emit(state.copyWith(status: PaymentStates.failure));
//         }else{
//           emit(state.copyWith(status: PaymentStates.success));
//         }
//       }
//     } catch (e) {
//       print(e.toString());
//       emit(state.copyWith(status: PaymentStates.failure));
//     }
//   }
//
//   Future<Map<String, dynamic>> _callPaymentEndPointIntentId(
//       { required String paymentIntentId}) async {
//     final url =  Uri.parse(_paymentEndPointIntentIdUrl);
//     final response = await http.post(
//         url, headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'paymentIntentId': paymentIntentId
//         }));
//     return json.decode(response.body);
//   }
//
//   Future<Map<String, dynamic>> _callPaymentEndPointMethodId(
//       { required bool useStripeSdk,
//         required String paymentMethodId,
//         required String currency,
//         required List<Map<String, dynamic>>? items}) async {
//     final url = Uri.parse(_paymentEndPointMethodIdUrl);
//     final response = await http.post(
//         url, headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'useStripeSdk': useStripeSdk,
//           'paymentMethodId': paymentMethodId,
//           'currency': currency,
//           'items': items,
//           'customerId':'123456789'
//         }));
//     return json.decode(response.body);
//   }
// }
//
// /// Payment Events
// class PaymentEvent extends Equatable {
//   const PaymentEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class PaymentStart extends PaymentEvent {}
//
// class PaymentCreateIntent extends PaymentEvent {
//   final BillingDetails billingDetails;
//   final List<Map<String, dynamic>> items;
//
//   const PaymentCreateIntent({required this.billingDetails,
//     required this.items});
//
//   @override
//   List<Object?> get props => [billingDetails, items];
// }
//
// class PaymentConfirmIntent extends PaymentEvent {
//   final String clientSecret;
//
//   const PaymentConfirmIntent({required this.clientSecret});
//
//   @override
//   List<Object?> get props => [clientSecret];
// }
//
// /// Payment States
// enum PaymentStates { initial, loading, success, failure }
//
// class PaymentState extends Equatable {
//   final PaymentStates status;
//   final CardFieldInputDetails cardFieldInputDetails;
//
//   const PaymentState({this.status = PaymentStates.initial,
//     this.cardFieldInputDetails = const CardFieldInputDetails(complete: false)
//   });
//
//   PaymentState copyWith({ PaymentStates? status,
//     CardFieldInputDetails? cardFieldInputDetails}) {
//     return PaymentState(status: status ?? this.status,
//         cardFieldInputDetails: cardFieldInputDetails ??
//             this.cardFieldInputDetails
//     );
//   }
//
//   @override
//   List<Object?> get props => [status, cardFieldInputDetails];
// }


import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:my_kom/module_authorization/presistance/auth_prefs_helper.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {

  /// Urls Cloud Functions
  final String _paymentEndPointSetupIntentUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointSetupIntent';
  final AuthPrefsHelper _authPrefsHelper = AuthPrefsHelper();
  PaymentBloc() : super(const PaymentState()) {
    on<PaymentEvent>((PaymentEvent event, Emitter<PaymentState> emit){
      if(event is PaymentLoading)
        emit(state.copyWith(status: PaymentStates.loading));
      else if(event is PaymentSuccess)
        emit(state.copyWith(status: PaymentStates.success,paymentMethod:event.paymentMethod ));
      else if (event is PaymentError)
        emit(state.copyWith(status: PaymentStates.failure,paymentMethod: null));
      else if( event is PaymentFormNotCompletedError){
        emit(state.copyWith(status: PaymentStates.form_not_completed,paymentMethod: null));
      }
      else
        emit(state.copyWith(status: PaymentStates.initial));
    });
  }


   createPaymentMethod(BillingDetails billingDetails) async {
    try{
      this.add(PaymentLoading());
      /// get stripe customer
      String? _customer = await _authPrefsHelper.getStripeCustomerId();
      print('create payment');
      print(_customer);
      /// create payment method
      final PaymentMethod paymentMethod =await Stripe.instance.createPaymentMethod(
        PaymentMethodParams.card(paymentMethodData: PaymentMethodData(
          billingDetails: billingDetails,
        )),

      );

      /// Setup Intent (Attach payment method with customer)
      final url =  Uri.parse(_paymentEndPointSetupIntentUrl);
      final response = await http.post(
          url, headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'paymentMethodId':paymentMethod.id,
            'customerId':_customer
          }));
      print('att');
      print(response.body);
      print('cards from stripe');
      this.add(PaymentSuccess(paymentMethod));

    }catch(e){
      print('error in setup intent');
      print(e.toString());
      this.add(PaymentError(message: e.toString()));
    }

  }

  emitFormIsNotCompleted(){
    this.add(PaymentFormNotCompletedError());
  }
}

/// Payment Events
class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class PaymentLoading extends PaymentEvent {
  const PaymentLoading();

}

class PaymentError extends PaymentEvent {
  final String message;

  const PaymentError({required this.message});

}

class PaymentSuccess extends PaymentEvent {
  final PaymentMethod paymentMethod;
  const PaymentSuccess(this.paymentMethod);

}

class PaymentFormNotCompletedError extends PaymentEvent {

  const PaymentFormNotCompletedError();

}
/// Payment States
enum PaymentStates { initial, loading, success, failure ,form_not_completed }

class PaymentState extends Equatable {
  final PaymentStates status;
  final CardFieldInputDetails cardFieldInputDetails;
  final PaymentMethod? paymentMethod ;

  const PaymentState({this.status = PaymentStates.initial,
    this.cardFieldInputDetails = const CardFieldInputDetails(complete: false),
    this.paymentMethod =null
  });

  PaymentState copyWith({ PaymentStates? status,
    CardFieldInputDetails? cardFieldInputDetails,  PaymentMethod? paymentMethod}) {
    return PaymentState(status: status ?? this.status,
        cardFieldInputDetails: cardFieldInputDetails ??
            this.cardFieldInputDetails,
       paymentMethod:paymentMethod ?? this.paymentMethod
    );
  }

  @override
  List<Object?> get props => [status, cardFieldInputDetails];
}

