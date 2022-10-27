import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_kom/consts/utils_const.dart';
import 'package:my_kom/module_authorization/enums/auth_source.dart';
import 'package:my_kom/module_authorization/enums/auth_status.dart';
import 'package:my_kom/module_authorization/enums/consts.dart';
import 'package:my_kom/module_authorization/enums/user_role.dart';
import 'package:my_kom/module_authorization/exceptions/auth_exception.dart';
import 'package:my_kom/module_authorization/model/app_user.dart';
import 'package:my_kom/module_authorization/presistance/auth_prefs_helper.dart';
import 'package:my_kom/module_authorization/repository/auth_repository.dart';
import 'package:my_kom/module_authorization/requests/login_request.dart';
import 'package:my_kom/module_authorization/requests/profile_request.dart';
import 'package:my_kom/module_authorization/requests/register_request.dart';
import 'package:my_kom/module_authorization/response/login_response.dart';
import 'package:my_kom/module_authorization/response/register_response.dart';
import 'package:my_kom/module_map/models/address_model.dart';
import 'package:my_kom/module_payment/service/payment_service.dart';
import 'package:my_kom/utils/logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final AuthRepository _repository = new AuthRepository();
  final AuthPrefsHelper _prefsHelper = AuthPrefsHelper();
  final PaymentService _paymentService = PaymentService();
  FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationCode = '';

  // Delegates
  Future<bool> get isLoggedIn => _prefsHelper.isSignedIn();

  Future<String?> get userID => _prefsHelper.getUserId();

  Future<UserRole?> get userRole => _prefsHelper.getRole();

  final PublishSubject<AuthResponse> phoneVerifyPublishSubject =
      new PublishSubject();

  Future<AppUser> getCurrentUser() async {
    String? id = await _prefsHelper.getUserId();
    String? email = await _prefsHelper.getEmail();
    String? phone_number = await _prefsHelper.getPhone();
    UserRole? userRole = await _prefsHelper.getRole();
    AuthSource? authSource = await _prefsHelper.getAuthSource();
    String? user_name = await _prefsHelper.getUsername();
    AddressModel? address = await _prefsHelper.getAddress();
    String? strip_id = await _prefsHelper.getStripId();
    return AppUser(
        id: id!,
        email: email!,
        authSource: authSource,
        userRole: userRole!,
        address: address!,
        phone_number: phone_number!,
        user_name: user_name!,
        stripeId: strip_id,
        activeCard: null);
  }

  /// This helps create new accounts with email and password
  /// 1. Create a Firebase User
  /// 2. Create an Api User (Fire store)
  Future<RegisterResponse> registerWithEmailAndPassword(
      RegisterRequest request) async {
    final bool currentLangIsArabic = UtilsConst.lang == 'ar' ? true : false;

    try {
      UserCredential? credential = await _repository
          .createUserWithEmailAndPassword(request.email, request.password);

      /// The result may be an error if a private server is connected

      if (credential == null)
        return RegisterResponse(
            data: currentLangIsArabic
                ? 'حدث خطأ في عملية التسجيل'
                : 'Error in Register',
            state: false);

      await _registerApiNewUser(request, AuthSource.EMAIL, credential);

      return RegisterResponse(data: 'Success !', state: true);
    } catch (e) {
      String message = '';
      if (e is FirebaseAuthException) {
        {
          switch (e.code) {
            case 'email-already-in-use':
              {
                message = currentLangIsArabic
                    ? 'البريد الاليكتروني قيد الاستخدام'
                    : 'Email Already In Use';
                Logger().info('AuthService',
                    'Email address ${request.email} already in use.');
                break;
              }

            case 'invalid-email':
              {
                message =
                    currentLangIsArabic ? 'الايميل غير صحيح' : 'Invalid Email';

                Logger().info('AuthService',
                    'Email address ${request.email} is invalid.');
                break;
              }

            case 'operation-not-allowed':
              {
                message = currentLangIsArabic
                    ? 'العملية غير مسموح بها'
                    : 'Operation Not Allowed';
                Logger().info('AuthService', 'Error during sign up.');
                break;
              }

            case 'weak-password':
              {
                message =
                    currentLangIsArabic ? 'كلمة السر ضعيفة' : 'Weak Password';
                Logger().info('AuthService',
                    'Password is not strong enough. Add additional characters including special characters and numbers.');
                break;
              }

            default:
              Logger().info('AuthService', '${e.message}');
              break;
          }
        }
        Logger().info('AuthService', 'Got Authorization Error: ${e.message}');
        return RegisterResponse(data: message, state: false);
      } else {
        await FirebaseAuth.instance.currentUser?.delete();
        return RegisterResponse(
            data: currentLangIsArabic
                ? 'خطأ في عملية التسجيل'
                : 'Error in Register',
            state: false);
      }
    }
  }


  /// Create Profile
  Future<void> _registerApiNewUser(RegisterRequest? request,
      AuthSource authSource, UserCredential credential) async {
    ProfileRequest profileRequest = ProfileRequest();

    /// this for register customer in stripe (save and reuse payment method)
    final customerId = await _paymentService.setupIntent();
    if (request != null) {
      /// DTO
      profileRequest.email = request.email;
      profileRequest.userRole = request.userRole;
      profileRequest.address = request.address;
      profileRequest.userName = request.userName;
      profileRequest.phone = request.phone;
      profileRequest.authSource = authSource;
      profileRequest.stripeCustomerId = customerId;
    }

    /// Register Information is not from the user interface
    else {
      profileRequest.email = credential.user!.email.toString();
      profileRequest.userRole = UserRole.ROLE_USER;
      profileRequest.address = AddressModel(
          description: Unknowns.UNKNOWN_INFO.name,
          latitude: 0.0,
          longitude: 0.0,
          geoData: {});
      profileRequest.phone = credential.user!.phoneNumber == null
          ? Unknowns.UNKNOWN_INFO.name
          : credential.user!.phoneNumber!;
      profileRequest.userName = credential.user!.displayName == null ? Unknowns.UNKNOWN_INFO.name:credential.user!.displayName!;
      profileRequest.authSource = authSource;
      profileRequest.stripeCustomerId = customerId;
    }

    await _repository.createProfile(request: profileRequest);
  }

  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final bool currentLangIsArabic = UtilsConst.lang == 'ar' ? true : false;

    try {
      LoginRequest request = LoginRequest(email, password);
      LoginResponse response = await _repository.signIn(request);

      await _loginApiUser(AuthSource.EMAIL);

      await Future.wait([
        _prefsHelper.setToken(response.token),
      ]);

      return AuthResponse(
          message:
              currentLangIsArabic ? 'تم تسجيل الدخول بنجاح' : 'Login Success',
          status: AuthStatus.AUTHORIZED);
    } catch (e) {
      if (e is FirebaseAuthException) {
        Logger().info('AuthService', e.code.toString());
        String message = '';
        switch (e.code) {
          case 'user-not-found':
            {
              message =
                  currentLangIsArabic ? 'الحساب غير موجود' : 'User not found !';
              Logger().info('AuthService', 'User Not Found');
              break;
            }

          case 'wrong-password':
            {
              message = currentLangIsArabic
                  ? 'كلمة السر غير صحيحة'
                  : 'The password is incorrect';

              Logger().info('AuthService', 'The password is incorrect');
              break;
            }

          default:
            {
              message = 'Error in Login!';
              Logger().info('AuthService', '${e.message}');
              break;
            }
        }
        return AuthResponse(message: message, status: AuthStatus.UNAUTHORIZED);
      } else if (e is GetProfileException) {
        Logger().info('AuthService', 'Error getting Profile Fire Base API');
      } else
        Logger().info(
            'AuthService', 'Error getting the token from the Fire Base API');

      return AuthResponse(
          message: currentLangIsArabic
              ? 'خطأ في عملية تسجيل الدخول'
              : 'Error in Login!',
          status: AuthStatus.UNAUTHORIZED);
    }
  }

  //This function is private to generalize to different authentication methods
  //  phone , email , google ...etc
  // get info from firebase

  /// Get Profile
  Future<void> _loginApiUser(AuthSource authSource) async {
    var user = _auth.currentUser;

    // Change This
    try {
      ProfileResponse profileResponse = await _repository.getProfile(user!.uid);

      await Future.wait([
        _prefsHelper.setUserId(user.uid),
        _prefsHelper.setEmail(user.email!),
        _prefsHelper.setStripeCustomerId(profileResponse.stripeCustomerId),
        _prefsHelper.setAdderss(profileResponse.address),
        _prefsHelper.setUsername(profileResponse.userName),
        _prefsHelper.setPhone(profileResponse.phone),
        _prefsHelper.setAuthSource(authSource),
        _prefsHelper.setRole(profileResponse.userRole),
      ]);
    } catch (e) {
      throw GetProfileException(
          'Error getting Profile Fire Base API,User Not Found');
    }
  }

  Future<RegisterResponse> verifyWithGoogle({required bool isRegister}) async {
    // Trigger the authentication flow
    bool currentLangIsArabic = UtilsConst.lang == 'ar';
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      var userCredential = await _auth.signInWithCredential(credential);

      // Verify that the account exists
      bool isExist = await _accountIsExist(userCredential.user!.uid);
      if (!isExist) {
        await _registerApiNewUser(null, AuthSource.GOOGLE, userCredential);
        await _loginApiUser(AuthSource.GOOGLE);
      } else {
        await _loginApiUser(AuthSource.GOOGLE);
      }

      String _token = await userCredential.user!.getIdToken();
      await _prefsHelper.setToken(_token);

      if (isExist)
        return RegisterResponse(
            data:
                currentLangIsArabic ? 'تم تسجيل الدخول بنجاح' : 'Login Success',
            state: true);
      else
        return RegisterResponse(
            data: currentLangIsArabic
                ? 'تم التسجيل بنجاح'
                : 'Successfully Registered',
            state: true);
    } catch (e) {
      Logger().error('AuthStateManager', e.toString(), StackTrace.current);
      fakeAccount();
      return RegisterResponse(
          data: currentLangIsArabic
              ? 'حدث خطأ في عملية التسجيل'
              : 'Error in Register',
          state: false);
    }
  }

  /// apple specific function
  String _createNonce(int length) {
    final random = Random();
    final charCodes = List<int>.generate(length, (_) {
      late int codeUnit;

      switch (random.nextInt(3)) {
        case 0:
          codeUnit = random.nextInt(10) + 48;
          break;
        case 1:
          codeUnit = random.nextInt(26) + 65;
          break;
        case 2:
          codeUnit = random.nextInt(26) + 97;
          break;
      }

      return codeUnit;
    });

    return String.fromCharCodes(charCodes);
  }

  /// apple specific function
  Future<OAuthCredential> _createAppleOAuthCred() async {
    final nonce = _createNonce(32);
    final nativeAppleCred = Platform.isIOS
        ? await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: sha256.convert(utf8.encode(nonce)).toString(),
          )
        : await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            webAuthenticationOptions: WebAuthenticationOptions(
              // 'https://your-project-name.firebaseapp.com/__/auth/handler'
              redirectUri: Uri.parse(
                  'https://mykom-tech-dist.firebaseapp.com/__/auth/handler'),
              //your.app.bundle.name
              clientId: 'com.districtapp.mykomapp',
            ),
            nonce: sha256.convert(utf8.encode(nonce)).toString(),
          );

    return new OAuthCredential(
      providerId: 'apple.com',
      // MUST be "apple.com"
      signInMethod: 'oauth',
      // MUST be "oauth"
      accessToken: nativeAppleCred.identityToken,
      // propagate Apple ID token to BOTH accessToken and idToken parameters
      idToken: nativeAppleCred.identityToken,
      rawNonce: nonce,
    );
  }

  Future<RegisterResponse> verifyWithApple({required bool isRegister}) async {
    // Trigger the authentication flow
    bool currentLangIsArabic = UtilsConst.lang == 'ar';
    try {
      var oauthCred = await _createAppleOAuthCred();
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCred);
      bool isExist = await _accountIsExist(userCredential.user!.uid);
      if (!isExist) {
        await _registerApiNewUser(null, AuthSource.APPLE, userCredential);
        await _loginApiUser(AuthSource.APPLE);
      } else {
        await _loginApiUser(AuthSource.APPLE);
      }

      String _token = await userCredential.user!.getIdToken();
      await _prefsHelper.setToken(_token);

      if (isExist)
        return RegisterResponse(
            data:
                currentLangIsArabic ? 'تم تسجيل الدخول بنجاح' : 'Login Success',
            state: true);
      else
        return RegisterResponse(
            data: currentLangIsArabic
                ? 'تم التسجيل بنجاح'
                : 'Successfully Registered',
            state: true);
    } catch (e) {
      fakeAccount();
      return RegisterResponse(
          data: currentLangIsArabic
              ? 'حدث خطأ في عملية التسجيل'
              : 'Error in Register',
          state: false);
    }
  }


  Future<bool> _accountIsExist(String uid) async {
    return await _repository.checkExistAccount(uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _prefsHelper.deleteToken();
    await _prefsHelper.cleanAll();
  }

  void fakeAccount() async {
    String uid =  FirebaseAuth.instance.currentUser!.uid;
    await _repository.deleteFakeProfile(uid);
    logout();
  }

  Future<AuthResponse> resetPassword(String email) async {
    try {
      final bool currentLangIsArabic = UtilsConst.lang == 'ar' ? true : false;
      bool response = await _repository.getNewPassword(email);
      return AuthResponse(
          message: currentLangIsArabic
              ? 'تم ارسال الرمز '
              : 'The new code has been sent',
          status: AuthStatus.AUTHORIZED);
    } catch (e) {
      if (e is FirebaseAuthException) {
        Logger().info('AuthService', e.code.toString());
        String message = '';
        switch (e.code) {
          case 'user-not-found':
            {
              message = UtilsConst.lang == 'ar'
                  ? 'الايميل غير موجود'
                  : 'Email not found !';
              Logger().info('AuthService', 'User Not Found');
              break;
            }

          default:
            {
              message = UtilsConst.lang == 'ar'
                  ? 'حدث خطا!!!'
                  : 'Error in reset password!';
              Logger().info('AuthService', '${e.message}');
              break;
            }
        }
        return AuthResponse(message: message, status: AuthStatus.UNAUTHORIZED);
      } else
        return AuthResponse(
            message: UtilsConst.lang == 'en' ? 'Error !!!' : ' حدث خطا!!!',
            status: AuthStatus.UNAUTHORIZED);
    }
  }

  Future<AuthResponse> confirmWithCode(String code) async {
    final bool currentLangIsArabic = UtilsConst.lang == 'ar' ? true : false;

    try {
      AuthCredential authCredential = PhoneAuthProvider.credential(
        verificationId: _verificationCode,
        smsCode: code,
      );
      await _auth.signInWithCredential(authCredential);
      return AuthResponse(
          message:
              currentLangIsArabic ? 'تم التحقق بنجاح' : 'Success Verification',
          status: AuthStatus.AUTHORIZED);
    } catch (e) {
      print(e);
      return AuthResponse(
          message: currentLangIsArabic
              ? 'خطأ في عملية التحقق'
              : 'Error Verification',
          status: AuthStatus.UNAUTHORIZED);
    }
  }

  Future verifyWithPhone(String phone) async {
    try {
      await _auth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (authCredentials) {
            _auth.signInWithCredential(authCredentials).then((credential) {
              //  phoneVerifyPublishSubject.add(AuthResponse(message:'AUTHORIZED', status: AuthStatus.AUTHORIZED));
            });
          },
          verificationFailed: (err) {
            phoneVerifyPublishSubject.add(AuthResponse(
                message: err.message!, status: AuthStatus.UNAUTHORIZED));
          },
          codeSent: (String verificationId, int? forceResendingToken) {
            _verificationCode = verificationId;

            phoneVerifyPublishSubject.add(AuthResponse(
                message: 'CODE SENT', status: AuthStatus.CODE_SENT));
          },
          codeAutoRetrievalTimeout: (verificationId) {
            phoneVerifyPublishSubject.add(AuthResponse(
                message: 'CODE TIMEOUT', status: AuthStatus.CODE_TIMEOUT));
          });
    } catch (e) {
      phoneVerifyPublishSubject
          .add(AuthResponse(message: 'Error', status: AuthStatus.UNAUTHORIZED));
    }
  }

  void updateStripeCustomer(String customerID)async {
    await _repository.updateUserProfile({'stripeCustomerId':customerID});
  }
}
