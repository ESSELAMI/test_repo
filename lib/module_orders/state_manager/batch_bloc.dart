import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_kom/consts/utils_const.dart';

class BatchBloc extends Cubit<BatchStates>{

  BatchBloc() : super(BatchInitState());
  void emitLoadingState()=> emit(BatchLoadingState());
  void emitErrorState()=> emit(BatchErrorState(message:  UtilsConst.lang == 'en'?'Unable to load data':'تعذر تحميل البيانات'));
  void emitInitState()=> emit(BatchInitState());

}


abstract class BatchStates {}

class BatchInitState extends BatchStates {}

class BatchSuccessState extends BatchStates {
int length;
BatchSuccessState({required this.length});
}
class BatchLoadingState extends BatchStates {}

class BatchErrorState extends BatchStates {
  String message;
  BatchErrorState({required this.message});
}




