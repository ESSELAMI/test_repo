import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:load/load.dart';
import 'package:my_kom/consts/colors.dart';
import 'package:my_kom/consts/utils_const.dart';
import 'package:my_kom/module_authorization/authorization_routes.dart';
import 'package:my_kom/module_authorization/bloc/cubits.dart';
import 'package:my_kom/module_authorization/bloc/login_bloc.dart';
import 'package:my_kom/module_authorization/bloc/register_bloc.dart';
import 'package:my_kom/module_authorization/enums/user_role.dart';
import 'package:my_kom/module_authorization/screens/reset_password_screen.dart';
import 'package:my_kom/module_authorization/service/auth_service.dart';
import 'package:my_kom/module_home/navigator_routes.dart';
import 'package:my_kom/utils/size_configration/size_config.dart';
import 'package:my_kom/generated/l10n.dart';

class LoginScreen extends StatefulWidget {

  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final RegisterBloc _registerBloc;
  late final LoginBloc _loginBloc;
  final GlobalKey<FormState> _LoginFormKey = GlobalKey<FormState>();
  final TextEditingController _LoginEmailController = TextEditingController();
  final TextEditingController _LoginPasswordController =
      TextEditingController();

  late final PasswordHiddinCubit cubit;

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc();
    _registerBloc = RegisterBloc();
    cubit = PasswordHiddinCubit();
  }

  @override
  void dispose() {
    cubit.close();
    _loginBloc.close();
    _registerBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);
    return Scaffold(
      backgroundColor: ColorsConst.mainColor,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: SizeConfig.screenHeight * 0.1,
              ),
              Container(
                width: SizeConfig.screenWidth * 0.6,
                child: Image.asset('assets/new_logo.png'),
              ),
              SizedBox(
                height: 10,
              ),
              Center(
                child: Text(
                  S.of(context)!.welcome,
                  style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Center(
                child: Text(
                  S.of(context)!.signInToContinue,
                  style: GoogleFonts.lato(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: SizeConfig.screenHeight * 0.5,
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.screenWidth * 0.08),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Form(
                  key: _LoginFormKey,
                  child: ListView(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                            title: Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(S.of(context)!.email,
                                    style: GoogleFonts.lato(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 15))),
                            subtitle: SizedBox(
                              child: TextFormField(
                                style: TextStyle(fontSize: 15, height: 1),
                                keyboardType: TextInputType.emailAddress,
                                controller: _LoginEmailController,
                                decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            width: 2,
                                            style: BorderStyle.solid,
                                            color: Colors.black87),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    hintText: S.of(context)!.email,
                                    hintStyle: TextStyle(
                                        color: Colors.black26,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)
                                    //S.of(context).name,
                                    ),
                                textInputAction: TextInputAction.next,
                                onEditingComplete: () => node.nextFocus(),
                                validator: (result) {
                                  if (result!.isEmpty) {
                                    return S
                                        .of(context)!
                                        .emailAddressIsRequired; //S.of(context).nameIsRequired;
                                  }
                                  if (!_validateEmailStructure(result))
                                    return 'Must write an email address';
                                  return null;
                                },
                              ),
                            )),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(S.of(context)!.password,
                                  style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 15)
                              )),
                          subtitle: BlocBuilder<PasswordHiddinCubit,
                              PasswordHiddinCubitState>(
                            bloc: cubit,
                            builder: (context, state) {
                              return SizedBox(
                                child: TextFormField(
                                  controller: _LoginPasswordController,
                                  style: TextStyle(fontSize: 15, height: 1),
                                  decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      // errorStyle: GoogleFonts.lato(
                                      //   color: Colors.red.shade700,
                                      //   fontWeight: FontWeight.w800,
                                      // ),
                                      suffixIconConstraints: BoxConstraints(
                                        minWidth: 2,
                                        minHeight: 30,
                                      ),
                                      suffixIcon: SizedBox(
                                        height: 4,
                                        child: IconButton(
                                            onPressed: () {
                                              cubit.changeState();
                                            },
                                            icon: state ==
                                                    PasswordHiddinCubitState
                                                        .VISIBILITY
                                                ? Icon(Icons.visibility)
                                                : Icon(Icons.visibility_off)),
                                      ),
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              width: 2,
                                              style: BorderStyle.solid,
                                              color: Colors.black87),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      hintText: S.of(context)!.password,
                                      hintStyle: TextStyle(
                                          color: Colors.black26,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13)),
                                  obscureText: state ==
                                          PasswordHiddinCubitState.VISIBILITY
                                      ? false
                                      : true,

                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (v) => node.unfocus(),
                                  // Move focus to next
                                  validator: (result) {
                                    if (result!.isEmpty) {
                                      return S
                                          .of(context)!
                                          .passwordIsRequired; //S.of(context).emailAddressIsRequired;
                                    }

                                    return null;
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Align(
                        alignment: UtilsConst.lang == 'en'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        RestPasswordScreen()));
                          },
                          child: Container(
                            padding: UtilsConst.lang == 'en'
                                ? EdgeInsets.only(
                                    right: SizeConfig.widhtMulti * 4)
                                : EdgeInsets.only(
                                    left: SizeConfig.widhtMulti * 4),
                            child: Text(S.of(context)!.forgotPassword,
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black54,
                                  fontSize: 12,
                                )),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      BlocConsumer<LoginBloc, LoginStates>(
                          bloc: _loginBloc,
                          listener: (context, LoginStates state) async {
                            if (state is LoginLoadingState)
                              EasyLoading.show();
                            else if (state is LoginSuccessState) {
                              EasyLoading.showSuccess(state.message);
                                UtilsConst.isInit = true;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  NavigatorRoutes.NAVIGATOR_SCREEN,
                                  (route) => false,
                                );
                            } else if (state is LoginErrorState) {
                              EasyLoading.showError(state.message);
                            }
                          },
                          builder: (context, LoginStates state) {
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
                                        primary: ColorsConst.mainColor,
                                      ),
                                      onPressed: () {
                                        if (_LoginFormKey.currentState!
                                            .validate()) {
                                          String email =
                                              _LoginEmailController.text.trim();
                                          String password =
                                              _LoginPasswordController.text
                                                  .trim();
                                          _loginBloc
                                              .login(email, password);
                                        }
                                      },
                                      child: Text(S.of(context)!.login,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700))),
                                ),
                              ),
                            );
                          }),
                      Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              S.of(context)!.dontHaveAnAccount,
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w800,
                                color: Colors.black45,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context,
                                    AuthorizationRoutes.REGISTER_SCREEN,
                                    arguments: UserRole.ROLE_USER);
                              },
                              child: Text(S.of(context)!.createAccount,
                                  style: GoogleFonts.lato(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 12.0,
                      ),
                      BlocListener<RegisterBloc, RegisterStates>(
                        bloc: _registerBloc,
                        listener: (context, state) {
                          print(state);
                          if (state is RegisterSuccessState) {
                            hideLoadingDialog();
                            EasyLoading.showSuccess(state.data);
                            Navigator.pushNamedAndRemoveUntil(
                                context,
                                NavigatorRoutes.NAVIGATOR_SCREEN,
                                (route) => false);
                          } else if (state is RegisterErrorState) {
                            hideLoadingDialog();
                            EasyLoading.showError(state.message);
                          } else if (state is RegisterLoadingState) {
                            showCustomLoadingWidget(
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(30),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.transparent,
                                    child: Platform.isIOS
                                        ? CupertinoActivityIndicator(
                                            radius: 12,
                                            color: Colors.white,
                                          )
                                        : CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: SizedBox.shrink(),
                      ),
                      SizedBox(height: 10.0,),
                      Container(
                          margin: EdgeInsets.symmetric(horizontal: 20.0),
                          child: SizedBox(
                            height: 30.0,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  // side: BorderSide(
                                  //     color: Colors.black54
                                  // ),
                                  // shape: RoundedRectangleBorder(
                                  //     borderRadius: BorderRadius.circular(10)
                                  // ),
                                    elevation: 2,
                                    primary: Colors.white),
                                onPressed: () {
                                  _registerBloc.registerByGoogle();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text('Continue By Google',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600)),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    CircleAvatar(
                                      radius: 10.0,
                                      backgroundImage: AssetImage(
                                          'assets/icons/google_icon.png'),
                                    )
                                  ],
                                )),
                          )),
                      SizedBox(height: 10.0,),
                      Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 0),
                          child: SizedBox(
                            height: 30.0,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(

                                    // side: BorderSide(
                                    //     color: Colors.black54
                                    // ),
                                    // shape: RoundedRectangleBorder(
                                    //     borderRadius: BorderRadius.circular(10)
                                    // ),
                                    elevation: 2,
                                    primary: Colors.white),
                                onPressed: () {
                                  _registerBloc.registerByApple();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Continue By Apple',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600)),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      width: 20.0,
                                      height: 20.0,
                                      child: Image.asset(
                                        'assets/icons/apple_icon.png',
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  ],
                                )),
                          )),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              ))
        ],
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
