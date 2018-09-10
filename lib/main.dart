import 'dart:async';
import 'mainScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(new mainscreen());

class mainscreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: 'Chat Demo',
      theme: new ThemeData(
        primaryColor: const Color(0xffCE93D8),
      ),
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    );
  }

}



class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GoogleSignIn googleSignIn = new GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;
  BuildContext mainContext;


  @override
  void initState() {
    isSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    mainContext = context;
    return new MaterialApp(
      title: 'Flutter Chat',
      home: Scaffold(
        appBar: null,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ const Color(0xFF6A1B9A), const Color(0xFF9C27B0)]
                  )
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[

                  Text('Flutter Chat', style: TextStyle( color: Colors.white, fontSize: 30.0, fontWeight: FontWeight.bold, letterSpacing: 2.0),),
                  SizedBox(
                    height: 30.0,
                  ),
                  FlatButton(
                      onPressed: handleSignIn,
                      child: Text('SIGN IN WITH GOOGLE', style: TextStyle(fontSize: 16.0),),
                      color: const Color(0xffBA68C8),
                      highlightColor: const Color(0xffCE93D8),
                      splashColor: Colors.transparent,
                      textColor: Colors.white,
                      padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)
                  )
                ],
              )
              ),

            Positioned(
              child: isLoading
                  ? Container(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                color: Colors.white.withOpacity(0.8),
              ) :
                  Container()
            )
            
          ],
        )
      ),
    );
  }

  Future<Null> handleSignIn() async {
      prefs = await SharedPreferences.getInstance();

      this.setState((){
          isLoading = true;
      });

      GoogleSignInAccount googleUser = await googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      FirebaseUser firebaseUser  = await firebaseAuth.signInWithGoogle(idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

      //if user has logged in
      if(firebaseUser != null) {
        //check if user has already signed up
        final QuerySnapshot result = await Firestore.instance.collection('users').where('id', isEqualTo: firebaseUser.uid).getDocuments();
        final List<DocumentSnapshot> documents = result.documents;

        if(documents.length == 0){

          //Update users data to server if new User
          Firestore.instance.collection('users').document(firebaseUser.uid).setData({
            'nickname' : firebaseUser.displayName,
            'photoUrl' : firebaseUser.photoUrl,
            'id' : firebaseUser.uid
          });

          //store data to local
          currentUser = firebaseUser;
          await prefs.setString('id', currentUser.uid);
          await prefs.setString('nickname', currentUser.displayName);
          await prefs.setString('photoUrl', currentUser.photoUrl);
        } else {

          await prefs.setString('id', documents[0]['id']);
          await prefs.setString('nickname', documents[0]['nickname']);
          await prefs.setString('photoUrl', documents[0]['photoUrl']);
          await prefs.setString('aboutMe', documents[0]['aboutMe']);

        }
        Fluttertoast.showToast(msg: "Sign in success");
        this.setState((){
          isLoading = false;
        });

        Navigator.push(
            mainContext,
            MaterialPageRoute(
              builder: (context) =>
                  MainScreen(
                    currentUserId: firebaseUser.uid,
                  )),
        );

      } else {
        Fluttertoast.showToast(msg: "Sign in failed, please try again");
        this.setState((){
          isLoading = false;
        });
      }


  }

  Future isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(currentUserId: prefs.getString('id'))),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }
}
