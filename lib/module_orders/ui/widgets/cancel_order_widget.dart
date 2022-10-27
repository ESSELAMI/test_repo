import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_kom/module_orders/state_manager/order_detail_bloc.dart';


cancelOrderAlertWidget(context,OrderDetailBloc bloc , String orderId){
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)
    ),
    content: Container(
      height: 190,
      width: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(height: 25,),

          Center(child: Text('Do you want to delete this order ?',textAlign: TextAlign.center,style: GoogleFonts.lato(
              fontSize: 16,fontWeight: FontWeight.bold,color: Colors.black87
          ),)),
          SizedBox(height: 8,),
          Center(child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Note: When you delete the order, you cannot get it again, which means it will not be archived .',textAlign: TextAlign.center,style: GoogleFonts.lato(
                fontSize: 15,fontWeight: FontWeight.bold,color: Colors.black54
            ),),
          )),
          SizedBox(height: 16,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MaterialButton(

                onPressed: (){
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)
                ),
                child:Container(
                    height: 30,
                    width: 80,
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.black87,
                            width: 2
                        )
                    ),
                    child: Center(child: Text('Cancel',style: TextStyle(color: Colors.black87,fontSize:15,fontWeight: FontWeight.bold),))),

              ),
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)
                ),
                onPressed: () async{
                  EasyLoading.show();

                  bloc.deleteOrder(orderId).then((value) {
                    if(value){
                      EasyLoading.showSuccess('The order has been deleted successfully');
                      Navigator.of(context)..pop()..pop(context);
                    }else{
                      EasyLoading.showError('An error occurred !');

                    }
                  });


                },

                child:Container(
                    height: 30,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.red,
                          width: 2
                      ),
                      color: Colors.white,

                    ),
                    child: Center(child: Text('Delete',style: TextStyle(color: Colors.red,fontSize:15,fontWeight: FontWeight.bold),))),

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

