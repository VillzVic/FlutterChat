import 'dart:async';
import 'dart:io';
import 'settings.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat.dart';

class MainScreen extends StatefulWidget {
  String currentUserId;

  MainScreen({this.currentUserId});

  @override
  _MainScreenState createState() => new _MainScreenState(userId: currentUserId);
}

class _MainScreenState extends State<MainScreen> {
  String userId;
  bool isLoading = false;

  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app)
  ];

  _MainScreenState({this.userId});


  Future<bool> onBackPressed() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch(await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
          children: <Widget>[
            Container(
              color: Color(0xFF6A1B9A),
              margin: const EdgeInsets.all(0.0),
              padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
              height: 100.0,
              child: Column(
                children: <Widget>[
                  Container(
                    child: Icon(
                      Icons.exit_to_app,
                      size: 30.0,
                      color: Colors.white,
                    ),
                    margin: EdgeInsets.only(bottom: 10.0),
                  ),

                  Text(
                    'Exit app',
                    style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    'Are you sure to exit app?',
                    style: TextStyle(color: Colors.white70, fontSize: 14.0),
                  )
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 0); //returns false
              },
              child: Row(
                children: <Widget>[
                  Container(
                    child: Icon(
                      Icons.cancel,
                      color: Color(0xFF6A1B9A),
                    ),
                    margin: EdgeInsets.only(right: 10.0),
                  ),
                  Text(
                    'CANCEL',
                    style: TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 1); //returns true
              },
            )

          ],
        );
      }
    )){
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  buildItem(BuildContext context, DocumentSnapshot document) {
    if(document['id'] == userId) {  //if the user id is the same as the user logged in, return empty container
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: CachedNetworkImage(
                  placeholder: Container(
                    child: Image.asset('images/avater.png'),
                    width: 50.0,
                    height: 50.0,
                    padding: EdgeInsets.all(15.0),
                  ),
                  imageUrl: document['photoUrl'],
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
              
              new Flexible(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          child: Text(
                            document['nickname'],
                            style: TextStyle(color: Colors.black, fontSize: 16.0),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                        ),
                        
                        Container(
                          child: Text(
                            document['aboutMe'] ?? 'Flutter is cool',
                            style: TextStyle(color: Colors.grey),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                        )
                      ],
                    ),
                    margin: EdgeInsets.only(left: 20.0),
              ))
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => new Chat(peerId: document.documentID, peerAvatar: document['photoUrl'])));
          },

          color:Colors.grey.shade300,
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Text(''),
          title: Text('FLUTTER CHAT', style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFF6A1B9A),
          actions: <Widget>[
            PopupMenuButton<Choice>(
              icon: new Icon(Icons.more_vert, color: Colors.white,),
              onSelected: onItemMenuPress,
              itemBuilder: (BuildContext context) {
                return choices.map((Choice choice){
                  return PopupMenuItem<Choice> (
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: Color(0xFF9C27B0),
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: Color(0xFF9C27B0)),
                        )
                      ],
                    ),
                  );
                }).toList();
              },
            )
          ],
        ),

      body: WillPopScope(
        onWillPop: onBackPressed,
        child: Stack(
          children: <Widget>[

            Container(
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context, snapshot){
                  if(!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xffBA68C8)),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) => buildItem(context, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                    );
                  }
                }
              ),
            ),

            //Loading
            Positioned(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xffBA68C8))),
                      ),
              ) : Container(),
            )
          ],
        ),
      ),
    );
  }

final GoogleSignIn googleSignIn = new GoogleSignIn();

  void onItemMenuPress(Choice value) {
    if(value.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
    }
  }

  Future<Null> handleSignOut() async {
      this.setState((){
        isLoading = true;
      });
      await googleSignIn.signOut();
      this.setState((){
        isLoading = false;
      });
      Navigator.pop(context);
  }


}


class Choice {
  final String title;
  final IconData icon;

  const Choice({this.title, this.icon});

}
