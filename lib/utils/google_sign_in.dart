import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();

  void _showToast(String text){
    Fluttertoast.showToast(
      msg:  text,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 250,
    );
  }

  bool _isSigningIn = true;
  var test = 0;

  GoogleSignInProvider() {
    _isSigningIn = false;
  }

  bool get isSigningIn => _isSigningIn;

  set isSigningIn(bool isSigningIn) {
    _isSigningIn = isSigningIn;
    notifyListeners();
  }

  Future login() async {
    var connectionStatus = await Connectivity().checkConnectivity();
    if(connectionStatus == ConnectivityResult.none){
      _showToast('No Internet! Check your connection');
      return;
    }
    isSigningIn = true;

    final user = await googleSignIn.signIn();

    if (user == null) {
      isSigningIn = false;
      return;
    } else {
      final googleAuth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final userdata = FirebaseAuth.instance.currentUser;

      //DocumentReference user123 = FirebaseFirestore.instance.collection('yokesh').doc('shiddesh');

      FirebaseFirestore.instance.doc('/users/${userdata!.uid}').set({
        "UID" : userdata.uid,
        "Name" : userdata.displayName as String,
        "Email" : userdata.email as String,
        "Photo" : userdata.photoURL as String,
        "lastseen" : DateTime.now() as DateTime,
      });

      isSigningIn = false;
    }
  }

  void logout() async {
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
  }
}
