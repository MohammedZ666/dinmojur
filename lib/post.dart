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
import 'package:uuid/uuid.dart';
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

class Post extends StatelessWidget {
  final Map<String, dynamic> user;
  Post(this.user);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: PostPage(this.user),
        theme: ThemeData(
          primaryColor: Constants.primaryColor,
        ));
  }
}

class PostPage extends StatefulWidget {
  final Map<String, dynamic> user;
  PostPage(this.user);

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
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

    // _loadLocalCurrency();
  }

  @override
  Widget build(BuildContext buildContext) {
    // Build a Form widget using the _formKey created above.

    return isPosting
        ? LoadingWidget()
        : SafeArea(
            child: Scaffold(
                backgroundColor: Colors.white,
                // appBar: AppBar(
                //   elevation: 0.0,
                //   backgroundColor: Colors.white,
                //   actions: <Widget>[
                //     IconButton(
                //         icon: Icon(
                //           Icons.help,
                //           size: 25,
                //         ),
                //         onPressed: () => Navigator.push(context,
                //             MaterialPageRoute(builder: (context) => Help())))
                //   ],
                // ),
                body: Builder(builder: (context) => _formLayout(context)),
                bottomNavigationBar: Builder(
                    builder: (context) => CommonWidgets.goButton(onPressed: () {
                          if (data['tag'] == null) {
                            Scaffold.of(context).showSnackBar(
                                SnackBar(content: Text('Please choose a tag')));
                            return;
                          }
                          if (_image == null &&
                              widget.user['dp'] == Constants.dpAvatar) {
                            Scaffold.of(context).showSnackBar(
                                SnackBar(content: Text('Please add a photo')));
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
                        }))));
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
                              ? widget.user['dp'] == Constants.dpAvatar
                                  ? Icon(
                                      Icons.add_a_photo,
                                      color: Constants.primaryColor,
                                      size: 70,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: widget.user['dp'],
                                      repeat: ImageRepeat.noRepeat,
                                      placeholder: (context, url) => Container(
                                        height: Constants.postHeight,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage(Constants
                                                    .loadgingPlaceHolder),
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
                Text('????????? ?????????/???????????????'),
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
                '??????????????????????????????????????????',
                '???????????????????????????',
                '???????????? ?????????????????????',
                '????????? ?????????????????????',
                '???????????? ????????????'
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
            decoration: const InputDecoration(
                icon: Icon(Icons.person),
                labelText: '????????? *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)))),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
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
                labelText: '?????????????????? ??????????????? ??????????????? *',
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

  Future<void> postData() async {
    var user = (await FirebaseAuth.instance.currentUser());
    data['uid'] = user.phoneNumber;
    data['phone'] = user.phoneNumber;
    data['dp'] = _image == null ? widget.user['dp'] : await postImage();
    data['likes'] = 0;
    await Firestore.instance
        .collection(firestoreDir)
        .document(user.phoneNumber)
        .setData(data);
    await Firestore.instance
        .collection('users')
        .document(user.phoneNumber)
        .updateData({'dp': data['dp']});
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
