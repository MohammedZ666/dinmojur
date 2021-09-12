import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dinmojur/common_widgets.dart';
import 'package:dinmojur/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:image_cropper/image_cropper.dart';

// import 'package:geolocator/geolocator.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:location/location.dart';

const String _kGoogleApiKey = 'API KEY GOES HERE';

class EditPost extends StatefulWidget {
  final Map<String, dynamic> _data;
  EditPost(this._data);

  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> data = new Map<String, dynamic>();
  final String firestoreDir = 'posts';
  File _image;
  List<String> tags;
  DateTime _bDay = DateTime.now();
  bool isPosting = false;
  TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    data = widget._data;
    _addressController.text = data['locationString'];
    List temp = data['tag'];

    setState(() {
      tags = temp.map((e) => e.toString()).toList();
    });

    // _loadLocalCurrency();
  }

  @override
  Widget build(BuildContext buildContext) {
    // Build a Form widget using the _formKey created above.

    return isPosting
        ? LoadingWidget()
        : SafeArea(
            child: Scaffold(
                appBar: AppBar(
                  elevation: 0.0,
                  backgroundColor: Colors.transparent,
                  leading: new IconButton(
                    icon: new Icon(Icons.arrow_back, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // actions: <Widget>[
                  //   IconButton(
                  //       icon: Icon(
                  //         Icons.help,
                  //         size: 25,
                  //         color: Colors.grey,
                  //       ),
                  //       onPressed: () => Navigator.push(context,
                  //           MaterialPageRoute(builder: (context) => Help())))
                  // ],
                ),
                body: Builder(builder: (context) => _formLayout(context)),
                bottomNavigationBar: Builder(
                    builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                height: 45,
                                width: MediaQuery.of(context).size.width,
                                padding: EdgeInsets.symmetric(horizontal: 26.0),
                                margin: EdgeInsets.only(bottom: 2.0),
                                child: RaisedButton.icon(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              content: Text(
                                                  'আপনি কি নিশ্চিত? আপনার এড এবং সব লাইক মিটিয়ে দেয়া হবে'),
                                              actions: [
                                                FlatButton(
                                                  child: Text('না'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    Navigator.pop(
                                                        context, false);
                                                  },
                                                ),
                                                FlatButton(
                                                  child: Text('হ্যাঁ'),
                                                  onPressed: () {
                                                    // the phone has been launched from init
                                                    _deletePost(data['uid'],
                                                        data['dpOriginal']);
                                                    Navigator.pop(context);
                                                    Navigator.pop(
                                                        context, true);
                                                  },
                                                ),
                                              ],
                                            ));
                                  },
                                  label: Text(
                                    'ডিলিট',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16.0),
                                  ),
                                  color: Colors.red,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30.0))),
                                )),
                            CommonWidgets.goButton(onPressed: () {
                              if (data['tag'] == null) {
                                Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'দয়া করে, একটি আপনার পেশা সংক্রান্ত একটি ট্যাগ নির্বাচন করুন')));
                                return;
                              }

                              if (_formKey.currentState.validate()) {
                                // If the form is valid, display a Snackbar.
                                postData();
                                print(data);
                                setState(() {
                                  isPosting = true;
                                });
                              }
                            })
                          ],
                        ))));
  }

  Widget _formLayout(BuildContext buildContext) {
    return Container(
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: InkWell(
                      onTap: () {
                        showCupertinoDialog(
                            context: buildContext,
                            builder: (BuildContext context) =>
                                CupertinoAlertDialog(
                                    title: Text("কিভাবে ছবি দিতে চান?"),
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
                              ? CachedNetworkImage(
                                  imageUrl: data['dp'],
                                  repeat: ImageRepeat.noRepeat,
                                  placeholder: (context, url) => Container(
                                    height: Constants.postHeight,
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(
                                                Constants.loadgingPlaceHolder),
                                            fit: BoxFit.cover,
                                            repeat: ImageRepeat.noRepeat)),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  fadeInCurve: Curves.bounceInOut,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  _image,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    )),
                Text('ছবি বদলান'),
                SizedBox(height: 30.0),
                _buildForm(buildContext)
              ],
            ),
          )),
    );
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ChipsChoice<String>.multiple(
            itemConfig: ChipsChoiceItemConfig(
              labelStyle: TextStyle(color: Colors.white),
              selectedBrightness: Brightness.dark,
              selectedColor: Constants.primaryColor,
            ),
            value: tags,
            isWrapped: true,
            options: ChipsChoiceOption.listFrom<String, String>(
              source: <String>[
                'ইলেক্ট্রিসিয়ান',
                'প্লাম্বার',
                'টিভি রিপেয়ার',
                'এসি রিপেয়ার',
                'ছুটা বুয়া'
              ],
              value: (i, v) => v,
              label: (i, v) => v,
            ),
            onChanged: (val) => setState(() {
              tags = val;
              data['tag'] = val;
            }),
          ),
          SizedBox(height: 10.0),
          SizedBox(height: 10.0),
          TextFormField(
            minLines: 1,
            maxLines: 5,
            initialValue: data['name'],
            decoration: const InputDecoration(
                icon: Icon(Icons.person),
                labelText: 'নাম *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)))),
            validator: (value) {
              if (value.isEmpty) {
                return 'দয়া করে এই ফর্মটি ফিল আপ করুন';
              }
              data['name'] = value;
              return null;
            },
          ),

          SizedBox(height: 10.0),
          TextFormField(
            controller: _addressController,
            readOnly: true,
            minLines: 1,
            maxLines: 5,
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
                labelText: 'আপনার কাজের এলাকা *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)))),
          ),

          //  BottomNavigationButton(_post)
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

  _deletePost(String docId, String imagePath) async {
    await Firestore.instance.document('posts' + '/' + docId).delete();
    // await FirebaseStorage.instance
    //     .ref()
    //     .child(imagePath)
    //     .delete()
    //     .then((_) => print('$imagePath'));
  }

  Future<void> postData() async {
    var user = (await FirebaseAuth.instance.currentUser());
    data['uid'] = user.phoneNumber;
    data['phone'] = user.phoneNumber;
    data['dp'] = _image == null ? data['dp'] : await postImage();
    data['likes'] = 0;
    await Firestore.instance
        .collection(firestoreDir)
        .document(user.phoneNumber)
        .setData(data);
    print('success or failure');
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Feed()));
  }
}

class Help extends StatefulWidget {
  @override
  _HelpState createState() => _HelpState();
}

class _HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    child: Column(children: <Widget>[
                      Text(
                        'Hello!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36.0,
                        ),
                      ),
                      Divider(),
                      Text(
                        'TODO',
                        style: TextStyle(
                          fontSize: 26.0,
                        ),
                        textAlign: TextAlign.center,
                      )
                    ]),
                  )))),
    );
  }
}
