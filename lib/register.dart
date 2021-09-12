import 'dart:io';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:dinmojur/common_widgets.dart';
import 'package:dinmojur/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

const String _kGoogleApiKey = 'API KEY GOES HERE';

class Register extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: RegisterPage(),
        theme: ThemeData(
          primaryColor: Constants.primaryColor,
        ));
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> data = new Map<String, dynamic>();

  File _image;
  String sex = null;
  DateTime _bDay = DateTime.now();
  TextEditingController _birthdayController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  bool isRegistering = false;
  @override
  void initState() {
    super.initState();

    // _loadLocalCurrency();
  }

  @override
  Widget build(BuildContext buildContext) {
    // Build a Form widget using the _formKey created above.

    return isRegistering
        ? LoadingWidget()
        : Scaffold(
            body: Builder(builder: (context) => _formLayout(context)),
          );
  }

  Widget _formLayout(BuildContext buildContext) {
    return Center(
        child: Container(
      //height: 500.0,
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(top: 0),
                    child: InkWell(
                        onTap: () {
                          showCupertinoDialog(
                              context: buildContext,
                              builder: (BuildContext context) =>
                                  CupertinoAlertDialog(
                                      title: Text("How do want the picture?"),
                                      actions: <Widget>[
                                        CupertinoDialogAction(
                                            child: Text("Camera"),
                                            onPressed: () {
                                              _getImage(true);
                                              Navigator.of(context).pop();
                                            }),
                                        CupertinoDialogAction(
                                          child: Text("Gallery"),
                                          onPressed: () {
                                            _getImage(false);
                                            Navigator.of(context).pop();
                                          },
                                        )
                                      ]));
                        },
                        child: ClipOval(
                            child: Container(
                          width: 100,
                          height: 100,
                          child: _image == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  color: Constants.primaryColor,
                                  size: 70,
                                )
                              : Image.file(
                                  _image,
                                  fit: BoxFit.cover,
                                ),
                        )))),
                SizedBox(height: 50.0),
                _buildForm(buildContext),
                CommonWidgets.goButton(onPressed: () {
                  // if (_image == null) {
                  //   Scaffold.of(context).showSnackBar(
                  //       SnackBar(content: Text('Please add a photo')));
                  //   return;
                  // }
                  if (_bDay == DateTime.now()) return;

                  if (_formKey.currentState.validate()) {
                    // If the form is valid, display a Snackbar.
                    data.forEach((key, value) {
                      if (key == 'username') data[key] = _formatInput(value);
                    });
                    data['birthday'] = _bDay.toIso8601String();
                    postData();
                    print(data);
                    setState(() {
                      isRegistering = true;
                    });
                  }
                })
              ],
            ),
          )),
    ));
  }

  String _formatInput(String input) {
    List<String> wordArray = input.split(' ');
    String output = '';
    for (int i = 0; i < wordArray.length; i++) {
      if (wordArray[i].isNotEmpty) {
        output += wordArray[i];
        if (i != wordArray.length - 1) output += ' ';
      }
    }
    return output.toLowerCase();
  }

  Widget _buildForm(BuildContext buildContext) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            autofocus: false,
            decoration: const InputDecoration(
                icon: Icon(Icons.account_circle),
                labelText: 'username *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)))),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              data['username'] = value;
              return null;
            },
          ),
          Divider(height: 30.0),
          TextFormField(
            controller: _addressController,
            readOnly: true,
            minLines: 1,
            onTap: () async {
              Prediction p = await PlacesAutocomplete.show(
                  context: context,
                  apiKey: _kGoogleApiKey,
                  mode: Mode.fullscreen,
                  onError: (value) => print("String >>" + value.errorMessage),
                  language: "en",
                  region: "bd",
                  components: [
                    new Component(Component.country, "bd"),
                  ]);
              if (p != null) {
                var addresses =
                    await Geocoder.local.findAddressesFromQuery(p.description);
                var first = addresses.first;
                setState(() {
                  _addressController.text = p.description;
                });
                print(
                    "Coordinates of selected location: ${first.addressLine} : ${first.coordinates}");
                GeoFirePoint location = Geoflutterfire().point(
                    latitude: first.coordinates.latitude,
                    longitude: first.coordinates.longitude);
                data['location'] = location.data;
                data['locationString'] = _addressController.text;
              }
            },
            decoration: const InputDecoration(
                icon: Icon(Icons.location_on),
                labelText: 'Home address *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)))),
          ),
          Divider(height: 30.0),
          TextFormField(
            controller: _birthdayController,
            focusNode: FocusNode(),
            enableInteractiveSelection: false,
            onTap: () {
              _getBirthDay();
            },
            decoration: const InputDecoration(
              icon: Icon(Icons.cake),
              labelText: 'When is your birthday? *',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0))),
            ),
          ),
          Divider(height: 30),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: DropdownButton<String>(
                hint: Text('Sex? *'),
                value: sex,
                onChanged: (String newValue) {
                  setState(() {
                    sex = newValue;
                    data['sex'] = newValue;
                  });
                },
                isExpanded: true,
                items: <String>['Female', 'Male', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }

  Future<void> _getImage(bool camera) async {
    File image = await ImagePicker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    image = await ImageCropper.cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        cropStyle: CropStyle.circle,
        androidUiSettings: AndroidUiSettings(lockAspectRatio: false));
    setState(() {
      _image = image;
    });
  }

  // Future<void> _loadLocalCurrency() async {
  //   Location location = new Location();

  //   bool _serviceEnabled;
  //   PermissionStatus _permissionGranted;
  //   LocationData _locationData;

  //   _serviceEnabled = await location.serviceEnabled();
  //   if (!_serviceEnabled) {
  //     _serviceEnabled = await location.requestService();
  //     if (!_serviceEnabled) {
  //       return;
  //     }
  //   }

  //   _permissionGranted = await location.hasPermission();
  //   if (_permissionGranted == PermissionStatus.denied) {
  //     _permissionGranted = await location.requestPermission();
  //     if (_permissionGranted != PermissionStatus.granted) {
  //       return;
  //     }
  //   }

  //   _locationData = await location.getLocation();

  //   List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(
  //       _locationData.latitude, _locationData.longitude);
  //   // var value = await rootBundle.loadString("data/country_phone_codes.json");
  //   // var countriesJson = json.decode(value);
  //   data['country'] = placemarks[0].country;

  //   var countryData = json.decode((await http
  //           .get('https://restcountries.eu/rest/v2/name/${data['country']}'))
  //       .body);

  //   setState(() {
  //     _currency = countryData[0]["currencies"][0]["code"];
  //   });
  // }

  Future<String> postImage() async {
    StorageReference reference = FirebaseStorage.instance
        .ref()
        .child((await FirebaseAuth.instance.currentUser()).uid);
    StorageUploadTask uploadTask = reference.putFile(_image);
    StorageTaskSnapshot storageTaskSnapshot;

    // Release the image data

    StorageTaskSnapshot snapshot = await uploadTask.onComplete;
    if (snapshot.error == null) {
      storageTaskSnapshot = snapshot;
      String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://dinmojur.page.link',
        link: Uri.parse(downloadUrl),
        androidParameters: AndroidParameters(
          packageName: 'com.app.dinmojur',
          minimumVersion: 125,
        ),
        // iosParameters: IosParameters(
        //   bundleId: 'com.example.ios',
        //   minimumVersion: '1.0.1',
        //   appStoreId: '123456789',
        // ),
        // googleAnalyticsParameters: GoogleAnalyticsParameters(
        //   campaign: 'example-promo',
        //   medium: 'social',
        //   source: 'orkut',
        // ),
        // itunesConnectAnalyticsParameters: ItunesConnectAnalyticsParameters(
        //   providerToken: '123456',
        //   campaignToken: 'example-promo',
        // ),
        // socialMetaTagParameters: SocialMetaTagParameters(
        //   title: 'Example of a Dynamic Link',
        //   description: 'This link works whether app is installed or not!',
        // ),
      );
      final ShortDynamicLink shortDynamicLink =
          await parameters.buildShortLink();
      final Uri shortUrl = shortDynamicLink.shortUrl;
      downloadUrl = shortUrl.toString();

      print('Upload success $downloadUrl');
      return downloadUrl;
    } else {
      print('Error from image repo ${snapshot.error.toString()}');
      throw ('This file is not an image');
    }
  }

  Future<void> postData() async {
    var user = (await FirebaseAuth.instance.currentUser());
    data['uid'] = user.phoneNumber;
    data['dp'] = _image == null ? Constants.dpAvatar : await postImage();
    data['likedBy'] = <String>[];
    data['points'] = 0;
    await Firestore.instance
        .collection('users')
        .document(data['uid'])
        .setData(data);

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Feed()));
  }

  _getBirthDay() async {
    DateTime dateTime = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    setState(() {
      _bDay = dateTime;
      _birthdayController.text = dateTime == null
          ? ''
          : dateTime.day.toString() +
              '-' +
              dateTime.month.toString() +
              '-' +
              dateTime.year.toString();
    });
  }
}
