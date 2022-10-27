import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_kom/module_authorization/presistance/auth_prefs_helper.dart';
import 'package:my_kom/module_authorization/service/auth_service.dart';
import 'package:my_kom/module_payment/service/payment_service.dart';
import 'package:my_kom/module_shoping/models/card_model.dart';
import 'package:http/http.dart' as http;
class PaymentMethodsBloc extends Cubit<PaymentMethodsState> {
  final String _paymentEndPointPaymentMethodsUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointGetPaymentMethods';
  final String _paymentEndPointDeleteCardUrl = 'https://us-central1-mykom-tech-dist.cloudfunctions.net/StripePayEndpointDetach';

  final AuthService _authService = AuthService();
  final AuthPrefsHelper _authPrefsHelper = AuthPrefsHelper();

  PaymentMethodsBloc()
      : super(PaymentMethodsState(
            cards: [],
            paymentMethodeCreditGroupValue:'',
            state: PaymentMethodsStates.loading)) {
    getCards();
  }

  Future<void> getCards() async {
    emit(state.copyWith(status: PaymentMethodsStates.loading));

    try{
      String? _customer = await _authPrefsHelper.getStripeCustomerId();

      /// For Old Account registered in the application
      if(_customer == ''){
        _customer = await PaymentService().setupIntent();
        _authService.updateStripeCustomer(_customer);
      }

      final url = Uri.parse(_paymentEndPointPaymentMethodsUrl);
      final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'customerId': _customer!,
          }));

      final List<dynamic> data =await json.decode(response.body)['result']['data'];
      List<CardModel> _cards = [];
      data.forEach((element) {
        _cards.add(CardModel(cardId: element['id'], cardNumber: element['card']['last4'], type: element['card']['brand']));
      });
        emit(state.copyWith(status: PaymentMethodsStates.success, cards: _cards));
    }catch(e){
      print(e);
      emit(state.copyWith(status: PaymentMethodsStates.error, cards: []));
    }

  }

  addOne(CardModel card) async {
    getCards();
  }

  removeOne(CardModel card) async {
    emit(state.copyWith(status: PaymentMethodsStates.loading));
    try {
      final url = Uri.parse(_paymentEndPointDeleteCardUrl);
      final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'paymentMethodId': card.cardId,
          }));
      emit(state.copyWith(status: PaymentMethodsStates.success_deleted));
      getCards();
    } catch (e) {
      emit(state.copyWith(status: PaymentMethodsStates.error_deleted));
    }
  }

  clear() => emit(PaymentMethodsState(
      cards: [],
      paymentMethodeCreditGroupValue: '',
      state: PaymentMethodsStates.init));

  changeSelect(String value) {
    return emit(PaymentMethodsState(
        cards: state.cards,
        paymentMethodeCreditGroupValue: value,
        state: PaymentMethodsStates.success));
  }
}

enum PaymentMethodsStates { loading, success, error, init ,success_deleted,error_deleted}

class PaymentMethodsState {
  final PaymentMethodsStates state;
  String paymentMethodeCreditGroupValue;
  List<CardModel> cards;

  PaymentMethodsState(
      {required this.cards,
      required this.paymentMethodeCreditGroupValue,
      this.state = PaymentMethodsStates.loading});

  PaymentMethodsState copyWith(
      {PaymentMethodsStates? status,
      String? paymentMethodeCreditGroupValue,
      List<CardModel>? cards}) {
    return PaymentMethodsState(
        state: status ?? this.state,
        paymentMethodeCreditGroupValue: paymentMethodeCreditGroupValue ??
            this.paymentMethodeCreditGroupValue,
        cards: cards ?? this.cards);
  }
}
