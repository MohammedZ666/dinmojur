import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../common_widgets.dart';

// ignore: must_be_immutable
class PhoneAuthVerify extends StatefulWidget {
  String phoneNo;
  PhoneAuthVerify(this.phoneNo);
  /*
   *  cardBackgroundColor & logo values will be passed to the constructor
   *  here we access these params in the _PhoneAuthState using "widget"
   */
  Color cardBackgroundColor = Color(0xFFFCA967);
  String appName = Constants.appName;

  @override
  _PhoneAuthVerifyState createState() => _PhoneAuthVerifyState();
}

class _PhoneAuthVerifyState extends State<PhoneAuthVerify> {
  double _height, _width;
  //here sms and auth code are not the same
  String smsCode = "";
  String authCode = "";
  bool authSuccess = true;
  var firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    firebaseAuth.verifyPhoneNumber(
        phoneNumber: widget.phoneNo,
        timeout: Duration(seconds: 60),
        verificationCompleted: (AuthCredential auth) {
          firebaseAuth.signInWithCredential(auth).then((AuthResult value) {
            print('$value');
            if (value != null) {
              Navigator.pushReplacementNamed(context, '/');
            }
          });
        },
        verificationFailed: (AuthException authEx) {
          print('$authEx');
        },
        codeSent: (String verificationId, [int forceResendingToken]) async {
          setState(() {
            authCode = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            authCode = verificationId;
          });
        });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //  Fetching height & width parameters from the MediaQuery
    //  _logoPadding will be a constant, scaling it according to device's size
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;

    /*
     *  Scaffold: Using a Scaffold widget as parent
     *  SafeArea: As a precaution - wrapping all child descendants in SafeArea, so that even notched phones won't loose data
     *  Center: As we are just having Card widget - making it to stay in Center would really look good
     *  SingleChildScrollView: There can be chances arising where
     */

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          height: _height * .8,
          width: _width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              //  Logo: scaling to occupy 1.5 parts of 10 in the whole height of device
              // Padding(
              //   padding: EdgeInsets.all(_fixedPadding),
              //   child: PhoneAuthWidgets.getLogo(
              //       logoPath: widget.logo, height: _height * 0.15),
              // ),

              // AppName:
              Text(widget.appName,
                  style: TextStyle(
                    fontSize: 60.0,
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.w200,
                  )),
              SizedBox(height: 30.0),

              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RichText(
                      text: TextSpan(children: [
                    TextSpan(
                        text: 'Please enter the code sent to your phone',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w400)),
                  ])),
                ],
              ),

              SizedBox(height: 20.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: _width * 0.5,
                    height: 40.0,
                    child: TextField(
                      expands: false,
                      onChanged: (String value) {
                        smsCode = value;

                        if (smsCode.length == 6) {
                          signInWithPhoneNumber(smsCode);
                        }
                      },
                      maxLengthEnforced: false,
                      textAlign: TextAlign.center,
                      cursorColor: Colors.black,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w400,
                          color: Colors.black),
                      decoration: InputDecoration(
                        errorText: authSuccess ? null : "Wrong code",
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void signInWithPhoneNumber(String smsCode) async {
    var authCredential = PhoneAuthProvider.getCredential(
        verificationId: authCode, smsCode: smsCode);

    firebaseAuth
        .signInWithCredential(authCredential)
        .then((AuthResult authResult) async {
      print('Authentication successful');
      Navigator.pushNamed(context, '/');
    }).catchError((error) {
      setState(() {
        authSuccess = false;
      });
      Scaffold.of(context).showSnackBar(SnackBar(
          content: Text(
              'Verification failed, please check your internet connection and the code and try again.')));

      print(
          'Something has gone wrong, please try later(signInWithPhoneNumber) $error');
    });
  }
}
