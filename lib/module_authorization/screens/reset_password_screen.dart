import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_kom/consts/colors.dart';
import 'package:my_kom/consts/utils_const.dart';
import 'package:my_kom/module_authorization/bloc/cubits.dart';
import 'package:my_kom/module_authorization/bloc/login_bloc.dart';
import 'package:my_kom/module_authorization/bloc/reset_password_bloc.dart';
import 'package:my_kom/module_authorization/screens/widgets/top_snack_bar_widgets.dart';
import 'package:my_kom/module_home/navigator_routes.dart';
import 'package:my_kom/utils/size_configration/size_config.dart';
import 'package:my_kom/generated/l10n.dart';

class RestPasswordScreen extends StatefulWidget {
  final RestPasswordBloc _restPasswordBloc = RestPasswordBloc();
  RestPasswordScreen({Key? key}) : super(key: key);

  @override
  State<RestPasswordScreen> createState() => _RestPasswordState();
}

class _RestPasswordState extends State<RestPasswordScreen> {
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();
  final TextEditingController _LoginEmailController = TextEditingController();

  late final PasswordHiddinCubit cubit;
  @override
  void initState() {
    super.initState();
    cubit = PasswordHiddinCubit();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
        body: Form(
          key: _resetFormKey,
          child: SingleChildScrollView(
            child: Column(
              children: [

                Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.heightMulti * 7,
                  color: ColorsConst.mainColor,

                ),
                Row(
                  children: [
                    IconButton(onPressed: (){ Navigator.pop(context);}, icon:Icon(Platform.isIOS?Icons.arrow_back_ios:Icons.arrow_back,size: 28,))
                  ],
                ),
                SizedBox(height: SizeConfig.screenHeight * 0.05,),
                Text( S.of(context)!.forgotPassword,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize:23)),
                SizedBox(height: 20,),

                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal:SizeConfig.screenWidth * 0.2),
                  child:Text(
                    S.of(context)!.newPassword,
                    textAlign: TextAlign.center,
                    style:  GoogleFonts.lato(
                      fontWeight: FontWeight.w800,
                      color: Colors.black45,
                      fontSize: 18,
                    ),
                  ),
                ),



                        SizedBox(height: 50),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            title: Padding(
                              padding: EdgeInsets.only(bottom: 8 ),
                              child: Text(S.of(context)!.email,style:GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                  fontSize: 15
                              ))),
                              subtitle: SizedBox(
                                child: TextFormField(
                                  style: TextStyle(fontSize: 15),
                                  keyboardType: TextInputType.emailAddress,
                                  controller: _LoginEmailController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                                      
                                      border:OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          width: 2,
                                          style:BorderStyle.solid ,
                                          color: Colors.black87
                                        )
                                      ),

                                      hintText: S.of(context)!.email,
                                      hintStyle: TextStyle(color: Colors.black26,fontWeight: FontWeight.w800,fontSize: 13)
                                    
                                    
                                    //S.of(context).name,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () => node.nextFocus(),

                                  validator: (result) {
                                    if (result!.isEmpty) {
                                      return S.of(context)!.emailAddressIsRequired; //S.of(context).nameIsRequired;
                                    }
                                    if (!_validateEmailStructure(result))
                                      return UtilsConst.lang == 'en' ?'Must write an email address':'الايميل مطلوب';
                                    return null;
                                  },
                                ),
                              )),
                        ),

                        SizedBox(
                          height:30
                        ),
                        BlocConsumer<RestPasswordBloc, RestPasswordStates>(
                            bloc: widget._restPasswordBloc,
                            listener: (context,  state) {
                              if (state is RestPasswordSuccessState) {
                                snackBarSuccessWidget(context, state.message);


                              } else if (state is RestPasswordErrorState) {
                                snackBarErrorWidget(context, state.message);
                              }
                            },
                            builder: (context, state) {
                              if (state is RestPasswordLoadingState)
                                return Container(
                                    height: 35,
                                    width: 35,
                                    child: Center(
                                      child:Platform.isIOS?CupertinoActivityIndicator(): CircularProgressIndicator(
                                        color: ColorsConst.mainColor,
                                      ),
                                    ));
                              else
                                return ListTile(
                                  title: Container(
                                    height: 35,
                                    margin: EdgeInsets.symmetric(horizontal: 20),
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10)),
                                    child: ClipRRect(
                                      clipBehavior: Clip.antiAlias,
                                      borderRadius: BorderRadius.circular(10),
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(

                                            primary:ColorsConst.mainColor,
                                          ),
                                          onPressed: () {
                                            if (_resetFormKey.currentState!
                                                .validate()) {
                                              String email =
                                              _LoginEmailController.text.trim();
                                              widget._restPasswordBloc
                                                  .resetPassword(email);
                                            }
                                          },
                                          child: Text( S.of(context)!.confirmCode,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:17,
                                                  fontWeight: FontWeight.w700))),
                                    ),
                                  ),
                                );

                            }),

                SizedBox(
                  height: 50,
                ),
              ],
            ),
          ),
        ),

    );
  }

  bool _validateEmailStructure(String value) {
    //     String  pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~_-]).{8,}$';
    String pattern = r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$';
    RegExp regExp = new RegExp(pattern);
    return regExp.hasMatch(value);
  }
}
