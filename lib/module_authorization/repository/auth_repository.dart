
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_kom/module_authorization/requests/login_request.dart';
import 'package:my_kom/module_authorization/requests/profile_request.dart';
import 'package:my_kom/module_authorization/response/login_response.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    //var user = _firebaseAuth.currentUser;

    try {
      UserCredential resualt =await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return resualt;
    }catch(e){
      throw e;
    }

    // String? userId = null;
    // await _firebaseAuth
    //     .createUserWithEmailAndPassword(
    //   email: request.email,
    //   password: request.password,
    // );
    // //     .then((UserCredential credential) async {
    // //   User? user = credential.user;
    // //   userId = user!.uid;
    // //
    // //   if (userId != null)
    // //     await _firestore
    // //         .collection('users')
    // //         .doc(userId)
    // //         .set(request.toJson())
    // //         .catchError((error) {
    // //       throw Exception(error.toString());
    // //     });
    // //   return await user.getIdToken();
    // // }).catchError((error) {
    // //   throw error;
    // // });


  }

  Future<bool> createProfile({required ProfileRequest request}) async {
    String uid = _firebaseAuth.currentUser!.uid;
    try{
      var existingProfile =
      await _firestore.collection('users').doc(uid).set(request.toJson());
      return true;
    }catch(e){
      throw e;
    }


    // correct exit point
    return true;
  }

  Future<LoginResponse> signIn(LoginRequest request) async {
    var creds = await _firebaseAuth.signInWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );

    try {
      String token = await creds.user!.getIdToken();
      return LoginResponse(token);
    } catch (e) {
      throw e;
    }
  }

  Future<ProfileResponse> getProfile(String uid) async {
    try {
      var existProfile = await _firestore.collection('users').doc(uid).get();
      if(existProfile.data() == null)
        throw Exception();

      Map<String  ,dynamic > result = existProfile.data()!;

      return ProfileResponse.fromJson(result);
    } catch (e) {
      throw Exception();
    }
  }

  Future<bool>editProfile(String uid, EditProfileRequest request)  async {

    var existingProfile =
    await _firestore.collection('users').doc(uid).get();

    if (!existingProfile.exists) {
      throw Exception('Profile dosnt exsit !');
    }

    existingProfile.reference
        .update(request.toJson())
        .then((value) => null)
        .catchError((error) {
      throw Exception('Error in set data !');
    });

    // correct exit point
    return true;
  }

  Future<bool> getNewPassword(String email) async{
    try{
     await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    }on FirebaseAuthException catch(e){
      throw e;
    }
  }

  Future deleteFakeProfile(uid) async{
    try{
      return _firestore.runTransaction( (Transaction transaction) async {
       await _firestore.collection('users').doc(uid).delete();
       await FirebaseAuth.instance.currentUser!.delete();
      });

    }catch(e){

    }


  }

 Future<bool> checkExistAccount(uid) async{

   return await _firestore.collection('users').doc(uid).get().then((value) => value.exists);
 }

  updateUserProfile(Map<String, String> map)async {
    String _uid = _firebaseAuth.currentUser!.uid;
   await _firestore.collection('users').doc(_uid).update(map).catchError((e){});
  }

}
