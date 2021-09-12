import 'package:dinmojur/account.dart';
import 'package:dinmojur/leaderboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'auth/countries.dart';
import 'main.dart';

class Constants {
  static double postHeight = 100.0;
  static double dpHeight = 50.0;
  static Color primaryColor = Colors.greenAccent.shade700;
  static String logoPath = 'assets/images/app_logo.png';
  static double logoHeightPerecentage = 3 / 10;
  static String loadgingPlaceHolder = logoPath;
  static String background = 'assets/images/background.jpg';
  static String dpAvatar =
      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png';
  static String appName = 'dinmojur';
}

class LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CommonWidgets.getLogo(
              logoPath: Constants.logoPath,
              height: MediaQuery.of(context).size.height *
                  Constants.logoHeightPerecentage),
          Text(Constants.appName,
              style: TextStyle(
                fontSize: 60.0,
                color: Constants.primaryColor,
                fontWeight: FontWeight.w200,
              )),
          SizedBox(height: 10.0),
          Text('please wait...',
              style: TextStyle(fontSize: 18.0, color: Colors.grey)),
          SizedBox(height: 30.0),
          CircularProgressIndicator()
        ],
      ),
    ));
  }
}

class BottomNavBar extends StatelessWidget {
  final int _cIndex;
  BottomNavBar(this._cIndex);
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: _cIndex == 0 ? CircularNotchedRectangle() : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            color: _cIndex == 0 ? Constants.primaryColor : Colors.grey,
            onPressed: () {
              if (_cIndex != 0)
                Navigator.pushReplacement(context,
                    CupertinoPageRoute(builder: (context) {
                  return Feed();
                }));
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite),
            color: _cIndex == 1 ? Constants.primaryColor : Colors.grey,
            onPressed: () {
              if (_cIndex != 1)
                Navigator.pushReplacement(context,
                    CupertinoPageRoute(builder: (context) {
                  // return FeedFavorite();
                }));
            },
          ),
          IconButton(
            icon: Icon(Icons.insert_chart),
            color: _cIndex == 2 ? Constants.primaryColor : Colors.grey,
            onPressed: () {
              if (_cIndex != 2)
                Navigator.pushReplacement(context,
                    CupertinoPageRoute(builder: (context) {
                  return LeaderBoard();
                }));
            },
          ),
          IconButton(
            icon: Icon(Icons.person_pin),
            color: _cIndex == 3 ? Constants.primaryColor : Colors.grey,
            onPressed: () {
              if (_cIndex != 3)
                Navigator.pushReplacement(context,
                    CupertinoPageRoute(builder: (context) {
                  return Account();
                }));
            },
          ),
        ],
      ),
    );
  }
}

class CommonWidgets {
  static Widget goButton({Function onPressed}) => Builder(builder: (context) {
        return Container(
            height: 45,
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 26.0),
            margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
            child: RaisedButton(
              onPressed: onPressed,
              child: Text(
                'Go!',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              color: Constants.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0))),
            ));
      });

  static Widget getLogo({String logoPath, double height}) => Material(
        type: MaterialType.transparency,
        elevation: 10.0,
        child: Image.asset(logoPath, height: height),
      );

  static Widget searchCountry(TextEditingController controller) => Padding(
        padding:
            const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 2.0, right: 8.0),
        child: Card(
          child: TextFormField(
            autofocus: true,
            controller: controller,
            decoration: InputDecoration(
                hintText: 'Search your country',
                contentPadding: const EdgeInsets.only(
                    left: 5.0, right: 5.0, top: 10.0, bottom: 10.0),
                border: InputBorder.none),
          ),
        ),
      );

  static Widget phoneNumberField(
          TextEditingController controller, String prefix) =>
      Card(
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          key: Key('EnterPhone-TextFormField'),
          decoration: InputDecoration(
            border: InputBorder.none,
            errorMaxLines: 1,
            prefix: Text("  " + prefix + "  "),
          ),
        ),
      );

  static Widget selectableWidget(Country country, Function selectThisCountry) =>
      Material(
        color: Colors.white,
        type: MaterialType.canvas,
        child: InkWell(
          onTap: () => selectThisCountry(country), //selectThisCountry(country),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 10.0, top: 10.0, bottom: 10.0),
            child: Text(
              "  " +
                  country.flag +
                  "  " +
                  country.name +
                  " (" +
                  country.dialCode +
                  ")",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );

  static Widget selectCountryDropDown(Country country, Function onPressed) =>
      Card(
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.only(
                left: 4.0, right: 4.0, top: 8.0, bottom: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(' ${country.flag}  ${country.name} ')),
                Icon(Icons.arrow_drop_down, size: 24.0)
              ],
            ),
          ),
        ),
      );

  static Widget subTitle(String text) => Align(
      alignment: Alignment.centerLeft,
      child:
          Text(' $text', style: TextStyle(color: Colors.grey, fontSize: 14.0)));
}
