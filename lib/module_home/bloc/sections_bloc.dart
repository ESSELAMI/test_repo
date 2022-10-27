// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:my_kom/module_company/service/company_service.dart';
//
// class AllSectionsBloc extends Bloc<AllSectionsEvent, AllSectionsStates> {
//   final CompanyService _service ;
//
//   AllSectionsBloc(this._service) : super(AllSectionsInitState()) {
//
//     on<AllSectionsEvent>((AllSectionsEvent event, Emitter<AllSectionsStates> emit) {
//       if (event is AllSectionsLoadingEvent)
//         emit(AllSectionsLoadingState());
//       else if (event is AllSectionsErrorEvent){
//         emit(AllSectionsErrorState(message: event.message));
//       }
//       else if (event is AllSectionsSuccessEvent)
//         emit(AllSectionsSuccessState(data: event.data));
//
//       else if (event is AllSectionsZoneErrorEvent)
//         emit(AllSectionsZoneErrorState(message: event.message));
//
//       else if(event is AllSectionsInitEvent) {
//         print('----------- emit init state -------------');
//         AllSectionsInitState();
//       }
//     });
//   }
//
//   getAllSections(String storeId)  {
//     this.add(AllSectionsLoadingEvent());
//
//     _service.SectionsStoresPublishSubject.listen((value) {
//       if (value != null){
//         this.add(AllSectionsSuccessEvent(data: value));
//       } else{
//         this.add(AllSectionsErrorEvent(message: 'Error '));
//       }
//     });
//     try{
//       _service.getAllCompanies(storeId);
//     }catch(e){
//       print( 'This area is currently available!! ');
//       this.add(AllSectionsZoneErrorEvent(message: 'This area is currently available!! '));
//     }
//
//   }
//
//   void setInit() {
//
//     add(AllSectionsSuccessEvent(data: []));
//   }
//
// }
//
// abstract class AllSectionsEvent { }
// class AllSectionsInitEvent  extends AllSectionsEvent  {}
//
// class AllSectionsSuccessEvent  extends AllSectionsEvent  {
//   List<SectionsModel>  data;
//   AllSectionsSuccessEvent({required this.data});
// }
//
// class AllSectionsLoadingEvent  extends AllSectionsEvent  {}
//
// class AllSectionsErrorEvent  extends AllSectionsEvent  {
//   String message;
//   AllSectionsErrorEvent({required this.message});
// }
//
// class AllSectionsZoneErrorEvent  extends AllSectionsEvent  {
//   String message;
//   AllSectionsZoneErrorEvent({required this.message});
// }
//
// abstract class AllSectionsStates {}
//
// class AllSectionsInitState extends AllSectionsStates {}
//
// class AllSectionsSuccessState extends AllSectionsStates {
//   List<SectionsModel>  data;
//   AllSectionsSuccessState({required this.data});
// }
//
// class AllSectionsLoadingState extends AllSectionsStates {}
//
// class AllSectionsErrorState extends AllSectionsStates {
//   String message;
//   AllSectionsErrorState({required this.message});
// }
//
// class AllSectionsZoneErrorState extends AllSectionsStates {
//   String message;
//   AllSectionsZoneErrorState({required this.message});
// }
