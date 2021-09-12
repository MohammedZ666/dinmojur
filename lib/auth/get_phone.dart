import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'countries.dart';
import 'verify.dart';
import 'package:dinmojur/common_widgets.dart';

/*
 *  PhoneAuthUI - this file contains whole ui and controllers of ui
 *  Background code will be in other class
 *  This code can be easily re-usable with any other service type, as UI part and background handling are completely from different sources
 *  code.dart - Class to control background processes in phone auth verification using Firebase
 */

// ignore: must_be_immutable
class PhoneAuthGetPhone extends StatefulWidget {
  /*
   *  cardBackgroundColor & logo values will be passed to the constructor
   *  here we access these params in the _PhoneAuthState using "widget"
   */
  Color cardBackgroundColor = Color(0xFF6874C2);

  @override
  _PhoneAuthGetPhoneState createState() => _PhoneAuthGetPhoneState();
}

class _PhoneAuthGetPhoneState extends State<PhoneAuthGetPhone> {
  /*
   *  _height & _width:
   *    will be calculated from the MediaQuery of widget's context
   *  countries:
   *    will be a list of Country model, Country model contains name, dialCode, flag and code for various countries
   *    and below params are all related to StreamBuilder
   */
  double _height, _width, _fixedPadding;

  List<Country> countries = [];
  StreamController<List<Country>> _countriesStreamController;
  Stream<List<Country>> _countriesStream;
  Sink<List<Country>> _countriesSink;

  /*
   *  _searchCountryController - This will be used as a controller for listening to the changes what the user is entering
   *  and it's listener will take care of the rest
   */
  TextEditingController _searchCountryController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  /*
   *  This will be the index, we will modify each time the user selects a new country from the dropdown list(dialog),
   *  As a default case, we are using Bangladesh as default country, index = 18
   */
  int _selectedCountryIndex = 18;

  bool _isCountriesDataFormed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // While disposing the widget, we should close all the streams and controllers

    // Disposing Stream components
//    _countriesSink.close();
//    _countriesStreamController.close();

    // Disposing _countriesSearchController
    _searchCountryController.dispose();
    super.dispose();
  }

  Future<List<Country>> loadCountriesJson() async {
    //  Cleaning up the countries list before we put our data in it
    countries.clear();

    //  Fetching the json file, decoding it and storing each object as Country in countries(list)
    var value = await DefaultAssetBundle.of(context)
        .loadString("data/country_phone_codes.json");

    var countriesJson = json.decode(value);
    for (var country in countriesJson) {
      countries.add(Country.fromJson(country));
    }

    //Finally adding the initial data to the _countriesSink
    // _countriesSink.add(countries);
    return countries;
  }

  @override
  Widget build(BuildContext context) {
    //  Fetching height & width parameters from the MediaQuery
    //  _logoPadding will be a constant, scaling it according to device's size
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;
    _fixedPadding = _height * 0.025;

    WidgetsBinding.instance.addPostFrameCallback((Duration d) {
      if (countries.length < 240) {
        loadCountriesJson().whenComplete(() {
          setState(() => _isCountriesDataFormed = true);
        });
      }
    });

    /*  Scaffold: Using a Scaffold widget as parent
     *  SafeArea: As a precaution - wrapping all child descendants in SafeArea, so that even notched phones won't loose data
     *  Center: As we are just having Card widget - making it to stay in Center would really look good
     *  SingleChildScrollView: There can be chances arising where
     */
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
              height: _height,
              width: _width,

              /*
           * Fetching countries data from JSON file and storing them in a List of Country model:
           * ref:- List<Country> countries
           * Until the data is fetched, there will be CircularProgressIndicator showing, describing something is on it's way
           * (Previously there was a FutureBuilder rather that the below thing, which created unexpected exceptions and had to be removed)
           */

              child: _getColumnBody()),
        ),
      ),
    );
  }

  Widget _getColumnBody() => Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //  Logo: scaling to occupy 1.5 parts of 10 in the whole height of device
            Padding(
              padding: EdgeInsets.all(_fixedPadding),
              child: CommonWidgets.getLogo(
                  logoPath: Constants.logoPath,
                  height: _height * Constants.logoHeightPerecentage),
            ),

            // AppName:
            Text(Constants.appName,
                style: TextStyle(
                  fontSize: 60.0,
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.w200,
                )),
            SizedBox(height: 10.0),

            _isCountriesDataFormed
                ? _getControllers()
                : Center(child: CircularProgressIndicator())
          ]);

  Widget _getControllers() => Column(
        children: <Widget>[
          SizedBox(
            height: 10.0,
          ),

          Padding(
            padding: EdgeInsets.only(top: _fixedPadding, left: _fixedPadding),
            child: CommonWidgets.subTitle('Select your country'),
          ),

          /*
           *  Select your country, this will be a custom DropDown menu, rather than just as a dropDown
           *  onTap of this, will show a Dialog asking the user to select country they reside,
           *  according to their selection, prefix will change in the PhoneNumber TextFormField
           */
          Padding(
            padding: EdgeInsets.only(left: _fixedPadding, right: _fixedPadding),
            child: CommonWidgets.selectCountryDropDown(
                countries[_selectedCountryIndex], showCountries),
          ),

          //  Subtitle for Enter your phone
          Padding(
            padding: EdgeInsets.only(top: 10.0, left: _fixedPadding),
            child: CommonWidgets.subTitle('Enter your phone'),
          ),
          //  PhoneNumber TextFormFields
          Padding(
            padding: EdgeInsets.only(
                left: _fixedPadding,
                right: _fixedPadding,
                bottom: _fixedPadding),
            child: CommonWidgets.phoneNumberField(_phoneNumberController,
                countries[_selectedCountryIndex].dialCode),
          ),
          SizedBox(height: 10),
          CommonWidgets.goButton(onPressed: startPhoneAuth)
          /*
           *  Some informative text
           */
          // Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: <Widget>[
          //     SizedBox(width: _fixedPadding),
          //     Icon(Icons.info, color: Colors.white, size: 20.0),
          //     SizedBox(width: 10.0),
          //     // Expanded(
          //     //   child: RichText(
          //     //       text: TextSpan(children: [
          //     //     TextSpan(
          //     //         text: 'We will send ',
          //     //         style: TextStyle(
          //     //             color: Colors.black, fontWeight: FontWeight.w400)),
          //     //     TextSpan(
          //     //         text: 'One Time Password',
          //     //         style: TextStyle(
          //     //             color: Colors.black,
          //     //             fontSize: 16.0,
          //     //             fontWeight: FontWeight.w700)),
          //     //     TextSpan(
          //     //         text: ' to this mobile number',
          //     //         style: TextStyle(
          //     //             color: Colors.black, fontWeight: FontWeight.w400)),
          //     //   ])),
          //     // ),
          //     SizedBox(width: _fixedPadding),
          //   ],
          // ),

          /*
           *  Button: OnTap of this, it appends the dial code and the phone number entered by the user to send OTP,
           *  knowing once the OTP has been sent to the user - the user will be navigated to a new Screen,
           *  where is asked to enter the OTP he has received on his mobile (or) wait for the system to automatically detect the OTP
           */
        ],
      );
  /*
   *  This will trigger a dialog, that will let the user to select their country, so the dialcode
   *  of their country will be automatically added at the end
   */
  showCountries() {
    /*
     * Initialising components required for StreamBuilder
     * We will not be using _countriesStreamController anywhere, but just to initialize Stream & Sink from that
     * _countriesStream will give us the data what we need(output) - that will be used in StreamBuilder widget
     * _countriesSink is the place where we send the data(input)
     */
    _countriesStreamController = StreamController();
    _countriesStream = _countriesStreamController.stream;
    _countriesSink = _countriesStreamController.sink;
    _countriesSink.add(countries);

    showDialog(
        context: context,
        builder: (BuildContext context) => searchAndPickYourCountryHere(),
        barrierDismissible: false);
    _searchCountryController.addListener(searchCountries);
  }

  /*
   *  This will be the listener for searching the query entered by user for their country, (dialog pop-up),
   *  searches for the query and returns list of countries matching the query by adding the results to the sink of _countriesStream
   */
  searchCountries() {
    String query = _searchCountryController.text;

    if (query.length >= 2) {
      List<Country> searchResults = [];
      searchResults.clear();
      countries.forEach((Country c) {
        if (c.toString().toLowerCase().contains(query.toLowerCase()))
          searchResults.add(c);
      });
      _countriesSink.add(searchResults);
//      print('added few countries based on search ${searchResults.length}');
    }
  }

  /*
   * Child for Dialog
   * Contents:
   *    SearchCountryTextFormField
   *    StreamBuilder
   *      - Shows a list of countries
   */

  Widget searchAndPickYourCountryHere() => WillPopScope(
        onWillPop: () => Future.value(true),
        child: Dialog(
          key: Key('SearchCountryDialog'),
          elevation: 8.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: Container(
            margin: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                //  TextFormField for searching country
                CommonWidgets.searchCountry(_searchCountryController),

                //  Returns a list of Countries that will change according to the search query
                SizedBox(
                  height: 200.0,
                  child: StreamBuilder<List<Country>>(
                      //key: Key('Countries-StreamBuilder'),
                      stream: _countriesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          // print(snapshot.data.length);
                          return snapshot.data.length == 0
                              ? Center(
                                  child: Text('Your search found no results',
                                      style: TextStyle(fontSize: 16.0)),
                                )
                              : ListView.builder(
                                  itemCount: snapshot.data.length,
                                  itemBuilder: (BuildContext context, int i) =>
                                      CommonWidgets.selectableWidget(
                                          snapshot.data[i],
                                          (Country c) => selectThisCountry(c)),
                                );
                        } else if (snapshot.hasError)
                          return Center(
                            child: Text('Seems, there is an error',
                                style: TextStyle(fontSize: 16.0)),
                          );
                        return Center(child: CircularProgressIndicator());
                      }),
                )
              ],
            ),
          ),
        ),
      );

  /*
   *  This callback is triggered when the user taps(selects) on any country from the available list in dialog
   *    Resets the search value
   *    Close the stream & sink
   *    Updates the selected Country and adds dialCode as prefix according to the user's selection
   */
  void selectThisCountry(Country country) {
    //printig country info
    print(country.toString() +
        " Index: " +
        countries.indexOf(country).toString());

    _searchCountryController.clear();
    Navigator.of(context).pop();
    Future.delayed(Duration(milliseconds: 10)).whenComplete(() {
      _countriesStreamController.close();
      _countriesSink.close();

      setState(() {
        _selectedCountryIndex = countries.indexOf(country);
      });
    });
  }

  startPhoneAuth() {
    Navigator.of(context).pushReplacement(CupertinoPageRoute(
        builder: (BuildContext context) => PhoneAuthVerify(
            countries[_selectedCountryIndex].dialCode +
                _phoneNumberController.text)));
  }
}
