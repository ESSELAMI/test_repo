import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_kom/consts/colors.dart';
import 'package:my_kom/module_authorization/bloc/is_loggedin_cubit.dart';
import 'package:my_kom/module_authorization/requests/profile_request.dart';
import 'package:my_kom/module_authorization/screens/widgets/login_sheak_alert.dart';
import 'package:my_kom/module_authorization/screens/widgets/top_snack_bar_widgets.dart';
import 'package:my_kom/module_map/map_routes.dart';
import 'package:my_kom/module_map/models/address_model.dart';
import 'package:my_kom/module_orders/ui/widgets/no_data_for_display_widget.dart';
import 'package:my_kom/module_profile/bloc/profile_bloc.dart';
import 'package:my_kom/module_profile/screen/widgets/delete_account_aleart.dart';
import 'package:my_kom/utils/size_configration/size_config.dart';
import 'package:my_kom/generated/l10n.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileBloc profileBloc ;
  const ProfileScreen({required this.profileBloc,Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  late final IsLogginCubit isLogginCubit;
  final TextEditingController _profileUserNameController = TextEditingController();
  final TextEditingController _profileAddressController = TextEditingController();
  final TextEditingController _profilePhoneController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    isLogginCubit = IsLogginCubit();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      userId =  ModalRoute.of(context)!.settings.arguments as String? ;

    });
    super.initState();
  }

  @override
  void dispose() {
    isLogginCubit.close();
    _profileUserNameController.dispose();
    _profileAddressController.dispose();
    _profilePhoneController.dispose();
    super.dispose();
  }
 late String? userId;
  bool isEditingProfile = false;
 late EditProfileRequest? request ;
  late AddressModel addressModel ;
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IsLogginCubit,IsLogginCubitState>(
        bloc: isLogginCubit,
        listener: (ccontext,state){
      if(state ==IsLogginCubitState.LoggedIn)
        {
          if(userId == null){
            widget.profileBloc.getMyProfile();
          }
        }
      if(state == IsLogginCubitState.NotLoggedIn)
        loginCheakAlertWidget(ccontext);
    },
    builder: (context,state){
    if(state == IsLogginCubitState.LoggedIn){

      return  Stack(
        children: [
          Container(
            color: Colors.grey.shade50,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: BlocConsumer<ProfileBloc, ProfileStates>(
                bloc: widget.profileBloc,
                listener: (context,state){
                  if(state is ProfileSuccessState){

                    _profileUserNameController.text = state.data.userName;
                    _profileAddressController.text = state.data.address.description;
                    _profilePhoneController.text = state.data.phone;
                    addressModel = state.data.address;
                    if(state.isEditState){
                      isEditingProfile = ! isEditingProfile;
                    }

                  }
                  else if(state is ProfileErrorState){
                    snackBarErrorWidget(context, S.of(context)!.profileEditErrorMessage);
                  }
                },
                builder: (context,state) {

                  if(state is ProfileErrorState){
                    return Center(child: NoDataForDisplayWidget());
                  }
                  else if(state is ProfileSuccessState) {

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 4),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Spacer(),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: (){
                                          if(!isEditingProfile){
                                            isEditingProfile = !isEditingProfile;
                                            setState((){});
                                          }else{
                                            if(_formKey.currentState!.validate()){
                                              request = EditProfileRequest();
                                              request?.userName = _profileUserNameController.text.trim();
                                              request?.address = addressModel;
                                              request?.phone = _profilePhoneController.text.trim();
                                              widget.profileBloc.editProfile(request!);
                                            }

                                          }


                                        },
                                        icon: Icon(!isEditingProfile? Icons.edit: Icons.save , color: Colors.black54,),
                                      ),
                                      SizedBox(width: 8.0,),
                                      if(isEditingProfile)
                                      IconButton(
                                        onPressed: (){
                                          isEditingProfile = !isEditingProfile;
                                            setState((){});
                                        },
                                        icon: Icon(Icons.cancel,color: Colors.black54,),
                                      ),

                                    ],
                                  ),

                                ],
                              ),
                              SizedBox(height: 5,),
                              Text(S.of(context)!.myProfile,textAlign: TextAlign.center,style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold


                              ),),
                              SizedBox(height: 20,),
                              Container(
                                height: 180.0,
                                child: LayoutBuilder(
                                  builder: (context,constraints){
                                    double innerWidth  = constraints.maxWidth;
                                    return Stack(
                                      fit:StackFit.expand,
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            alignment: Alignment.center,
                                            height:100.0,
                                            width:innerWidth ,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black12,
                                                      blurRadius: 2
                                                  )
                                                ],
                                                borderRadius: BorderRadius.circular(30)
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [

                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Center(
                                                  child: Container(
                                                    margin: EdgeInsets.symmetric(horizontal: 16.0),
                                                    child: TextFormField(
                                                      textAlign: TextAlign.center,
                                                      enabled: (!isEditingProfile)?false:true,
                                                      controller: _profileUserNameController,

                                                      style: TextStyle(
                                                          fontSize: 18.0,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.grey[700]
                                                      ),

                                                      decoration: InputDecoration(
                                                        suffixIcon: (!isEditingProfile)?null:Icon(Icons.edit,color: Colors.black,size: 18.0,),
                                                        enabledBorder:UnderlineInputBorder(
                                                            borderSide: BorderSide(color: Colors.black12)
                                                        ),

                                                        disabledBorder:UnderlineInputBorder(   borderSide: BorderSide(color: Colors.transparent)),
                                                        errorBorder: UnderlineInputBorder(
                                                            borderSide: BorderSide(color: Colors.red)
                                                        ),
                                                        //S.of(context).name,
                                                      ),
                                                      textInputAction: TextInputAction.next,
                                                      // Move focus to next
                                                    ),
                                                  ),
                                                ),


                                              ],),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: Container(
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black12,
                                                      blurRadius: 2
                                                  )
                                                ],
                                              ),
                                              child: Image.asset('assets/profile.png',
                                                fit: BoxFit.fitWidth,
                                                width: innerWidth * 0.35,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                ),
                              ),

                            SizedBox(height: 8,),
                            FutureBuilder<bool>(
                              future: widget.profileBloc.checkInfoCompete(),
                              builder: (context,state) {
                                bool?  b =state.data ;
                                if(b == false)
                                return Container(
                                    width: double.maxFinite,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: SizeConfig.widhtMulti * 5),
                                    padding: EdgeInsets.symmetric(vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.red.shade50,
                                    ),
                                    child: Center(
                                        child: Container(
                                            width: double.maxFinite,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: SizeConfig.widhtMulti * 5),
                                            padding: EdgeInsets.symmetric(vertical: 2),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              color: Colors.red.shade50,
                                            ),
                                            child: Center(
                                                child: Text('Click the edit button and complete your personal account information with real data to ensure a safe experience',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.lato(
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.red))))));
                                else
                                  return SizedBox.shrink();
                              }
                            ),
                              SizedBox(height: 20,),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                height: 300.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12,
                                        blurRadius: 2
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 20,),

                                    Text(S.of(context)!.myInformation,style:  TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600]
                                    ),),
                                    Divider(
                                      thickness: 2.5,
                                    ),
                                    SizedBox(height: 10,),

                                    Container(
                                      height: 100.0,
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      decoration: BoxDecoration(

                                          borderRadius: BorderRadius.circular(30),
                                          color: Colors.grey.shade200
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 8,),
                                          Text(S.of(context)!.myAddress,style:  TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600]
                                          ),),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.location_on , color: ColorsConst.mainColor,size: 17,),
                                              SizedBox(width: 10,),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.only(top: 12),
                                                  child: TextFormField(
                                                    readOnly: true,
                                                    controller: _profileAddressController,
                                                    maxLines: 2,
                                                    style:  TextStyle(
                                                        fontSize:11.0,

                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey[600]
                                                    ),
                                                    decoration: InputDecoration(
                                                      border: InputBorder.none,
                                                      //S.of(context).name,
                                                    ),
                                                    textInputAction: TextInputAction.next,
                                                    // Move focus to next
                                                  ),
                                                ),

                                              ),
                                              if(isEditingProfile)
                                                GestureDetector(
                                                  onTap: (){
                                                    Navigator.pushNamed(
                                                        context, MapRoutes.MAP_SCREEN,arguments: true)
                                                        .then((value) {
                                                      if (value != null) {
                                                        addressModel = (value as AddressModel);
                                                        _profileAddressController.text =
                                                            addressModel.description;
                                                        addressModel = value;

                                                      }

                                                    });
                                                  },
                                                  child: Container(
                                                    width: 30.0,
                                                    height: 30.0,
                                                    decoration: BoxDecoration(
                                                        color: ColorsConst.mainColor,
                                                        borderRadius:
                                                        BorderRadius.circular(10)),
                                                    child: Icon(
                                                        Icons.my_location_outlined,
                                                        size: 20.0,
                                                        color: Colors.white),
                                                  ),
                                                )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10,),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20),

                                      height: 120.0,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                          color: Colors.grey.shade200
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,                            children: [
                                        Text(S.of(context)!.emailAndPhone,style:  TextStyle(
                                            fontSize:14.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600]
                                        ),),
                                        SizedBox(height: 8,),

                                        Row(
                                          children: [
                                            Icon(Icons.email , color: ColorsConst.mainColor,size: 17,),
                                            SizedBox(width: 10,),
                                            Text(state.data.email,style:  TextStyle(
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600]
                                            ),),

                                          ],
                                        ),
                                        SizedBox(height: 8,),

                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.phone , color: ColorsConst.mainColor,size: 17,),
                                            SizedBox(width: 10,),
                                            Expanded(child: SizedBox(height:20.0,child: TextFormField(

                                              cursorHeight: 12.0,
                                              keyboardType: TextInputType.number,
                                              enabled: (!isEditingProfile)?false:true,
                                              controller: _profilePhoneController,
                                              validator: (v){
                                               return _validatePhoneNumberStructure(v.toString()) == true?null:'';
                                              },

                                              style: TextStyle(

                                                  fontSize: 11.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[600]
                                              ),
                                              decoration: InputDecoration(
                                                suffixIcon: (!isEditingProfile)?null:Icon(Icons.edit,color: Colors.black,size: 18.0,),
                                                  enabledBorder:UnderlineInputBorder(
                                                    borderSide: BorderSide(color: Colors.black12)
                                                  ),

                                                  disabledBorder:UnderlineInputBorder(   borderSide: BorderSide(color: Colors.transparent)),
                                                  errorBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.red)
                                                  ),


                                                //S.of(context).name,
                                              ),
                                              textInputAction: TextInputAction.done,

                                            ),

                                            )),
                                            // Text(state.data.phone,style:  TextStyle(
                                            //     fontSize: 11.0,
                                            //     fontWeight: FontWeight.bold,
                                            //     color: Colors.grey[600]
                                            // ),),


                                          ],
                                        )
                                      ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25.0,),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 15),
                                height: 35,
                                width: SizeConfig.screenWidth,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12,
                                        blurRadius: 2
                                    )
                                  ],
                                ),
                                child: MaterialButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                  ),
                                    onPressed: (){
                                      deleteAccountAlertWidget(context,widget.profileBloc);
                                    },
                                    child: Center(child: Text(S.of(context)!.deleteMyAccount,style: GoogleFonts.lato(fontSize: 14.0,fontWeight: FontWeight.bold,color: Colors.red),))),
                              ),
                              SizedBox(height: 50,)

                            ],
                          ),
                        ),
                      ),
                    );
                  } else
                    return Center(
                      child: Container(
                        height: 30,
                        width: 30,
                        child: Center(
                          child:Platform.isIOS?CupertinoActivityIndicator(): CircularProgressIndicator(color: ColorsConst.mainColor,),
                        ),
                      ),
                    );
                }
            ),
          )
        ],
      );

    }
    else{
      return Scaffold(
        backgroundColor: Colors.white,
      );
    }
        }
    );


  }

  bool _validatePhoneNumberStructure(String value) {
    String pattern = r'([0-9]{9}$)';
    RegExp regExp = new RegExp(pattern);
    return regExp.hasMatch(value);
  }

}

