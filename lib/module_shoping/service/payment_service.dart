import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:my_kom/module_authorization/presistance/auth_prefs_helper.dart';
import 'package:my_kom/module_shoping/bloc/payment_bloc.dart';
import 'package:http/http.dart' as http;

class PaymentService {

/// Urls Cloud Functions
final String _paymentEndPointMethodIdUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointMethodId';
final String _paymentEndPointIntentIdUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointIntentId';
final String _paymentEndPointCustomerIdUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointCustomerId';

AuthPrefsHelper _authPrefsHelper = AuthPrefsHelper();
 PaymentState state = PaymentState();

 paymentStart() {
  return state.copyWith(status: PaymentStates.initial);
}

Future<PaymentMethod> paymentSetupIntent(BillingDetails billingDetails) async {
  state = state.copyWith(status: PaymentStates.loading);

  final paymentMethod = await Stripe.instance.createPaymentMethod(

    PaymentMethodParams.card(paymentMethodData: PaymentMethodData(
        billingDetails: billingDetails,),

    ),
  );
  return paymentMethod;
}


  /// Crete Intent  (we most pass customer Id and payment method Id)
 Future<PaymentState> pay({required String paymentMethodID , required List<Map<String, dynamic>> items})async{
   try{
     String? _customerId = await _authPrefsHelper.getStripeCustomerId();
     if(_customerId == null){
       throw Exception();
     }
     final paymentIntentResults = await _callPaymentEndPointMethodId(
         useStripeSdk: true,
         paymentMethodId: paymentMethodID,
         currency: 'usd',
         items: items,
         customerId:_customerId
     );
     if (paymentIntentResults['error'] != null) {
       print(paymentIntentResults['error']);
       state = state.copyWith(status: PaymentStates.failure);
     }
     if (paymentIntentResults['clientSecret'] != null &&
         paymentIntentResults['requestAction'] == null
     ) {
       state = state.copyWith(status: PaymentStates.success);
     }
     if (paymentIntentResults['clientSecret'] != null &&
         paymentIntentResults['requestAction'] == true
     ) {
       final String clientSecret = paymentIntentResults['clientSecret'];
       state = await _onPaymentConfirmIntent(PaymentConfirmIntent(clientSecret: clientSecret));
     }
     return state;
   }catch(e){
     print(e.toString());
     state = state.copyWith(status: PaymentStates.failure);
     return state;
   }

 }

Future<PaymentState> _onPaymentConfirmIntent(PaymentConfirmIntent event) async {
  try {
    final paymentIntent = await Stripe.instance.handleNextAction(event.clientSecret);
    if(paymentIntent.status == PaymentIntentsStatus.RequiresConfirmation){
      Map<String , dynamic> results =  await _callPaymentEndPointIntentId(paymentIntentId:paymentIntent.id);
      if(results['error'] != null){
        state = state.copyWith(status: PaymentStates.failure);
      }else{
        state = state.copyWith(status: PaymentStates.success);
      }
    }
    return state;
  } catch (e) {
    state = state.copyWith(status: PaymentStates.failure);
    return state;
  }
}

Future<Map<String, dynamic>> _callPaymentEndPointIntentId(
    { required String paymentIntentId}) async {
  final url =  Uri.parse(_paymentEndPointIntentIdUrl);
  final response = await http.post(
      url, headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'paymentIntentId': paymentIntentId
      }));
  return json.decode(response.body);
}

Future<Map<String, dynamic>> _callPaymentEndPointMethodId(
    { required bool useStripeSdk,
      required String paymentMethodId,
      required String currency,
      required String customerId,
      required List<Map<String, dynamic>>? items}) async {
  final url = Uri.parse(_paymentEndPointMethodIdUrl);
  final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'useStripeSdk': useStripeSdk,
        'customerId':customerId,
        'paymentMethodId': paymentMethodId,
        'currency': currency,
        'items': items
      }));
  return json.decode(response.body);
}

/// Create Customer For Future Payments
Future<String> setupIntent() async {
  final url = Uri.parse(_paymentEndPointCustomerIdUrl);
  final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      );
  final paymentCustomerIdResult = await json.decode(response.body)['customer'];
  return paymentCustomerIdResult;
}
}




class PaymentCreateIntent  {
  final BillingDetails billingDetails;
  final List<Map<String, dynamic>> items;
  const PaymentCreateIntent({required this.billingDetails,
    required this.items});
}

class PaymentConfirmIntent  {
  final String clientSecret;
  const PaymentConfirmIntent({required this.clientSecret});

}