import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_kom/generated/l10n.dart';
import 'package:my_kom/module_orders/state_manager/order_detail_bloc.dart';


cancelOrderAlertWidget(context,OrderDetailBloc bloc , String orderId){
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0)
    ),
    content: Container(
      height: 180,
      width: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(height: 25.0,),

          Center(child: Text(S.of(context)!.titleMessageCancelOrder,textAlign: TextAlign.center,style: GoogleFonts.lato(
              fontSize: 16.0,fontWeight: FontWeight.bold,color: Colors.black87
          ),)),
          SizedBox(height: 8.0,),
          Center(child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(S.of(context)!.subTitleMessageCancelOrder,textAlign: TextAlign.center,style: GoogleFonts.lato(
                fontSize: 13.5,fontWeight: FontWeight.bold,color: Colors.black54
            ),),
          )),
          SizedBox(height: 30.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: 80.0,
                height: 30,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.black87,
                        width: 2
                    )
                ),
                child: MaterialButton(

                  onPressed: (){
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child:Center(child: Text(S.of(context)!.cancelAccountDeleteAlertButton,style: TextStyle(color: Colors.black87,fontSize:15,fontWeight: FontWeight.bold),)),

                ),
              ),
              Container(
                height: 30.0,
                width: 80.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.red,
                      width: 2
                  ),
                  color: Colors.white,

                ),
                child: MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  onPressed: () async{
                    EasyLoading.show();

                    bloc.deleteOrder(orderId).then((value) {
                      if(value){
                        EasyLoading.showSuccess(S.of(context)!.cancelOrderSuccessfullyMessage);
                        Navigator.of(context)..pop()..pop(context);
                      }else{
                        EasyLoading.showError(S.of(context)!.cancelOrderErrorMessage);

                      }
                    });


                  },

                  child:Center(child: Text(S.of(context)!.deleteAccountAlertButton,style: TextStyle(color: Colors.red,fontSize:15,fontWeight: FontWeight.bold),)),

                ),
              ),
            ],
          ),
        ],
      ),
    ),

  );

// show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

