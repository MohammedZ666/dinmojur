import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common_widgets.dart';

const String _kGoogleApiKey = 'API KEY GOES HERE';

class Account extends StatefulWidget {
  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  final int _cIndex = 3;
  Map<String, dynamic> _user;
  Map<String, dynamic> _userPost;
  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey<ScaffoldState>();
  File _image;
  List users = [];
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _uploadImage(bool camera) async {
    File image = await ImagePicker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    _image = await ImageCropper.cropImage(
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
      _user = null;
    });

    String dpUrl = await postImage();
    await Firestore.instance
        .collection('users')
        .document(_user['uid'])
        .updateData(({'dp': dpUrl}));
    if (_userPost != null)
      await Firestore.instance
          .collection('posts')
          .document(_userPost['uid'])
          .updateData(({'dp': dpUrl}));

    _initializeUser();
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

  @override
  Widget build(BuildContext context) {
    return _user == null
        ? LoadingWidget()
        : Scaffold(
            key: _scaffoldkey,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                    floating: true,
                    stretch: true,
                    backgroundColor: Colors.white,
                    stretchTriggerOffset: 100.0,
                    expandedHeight: 50.0,
                    centerTitle: true,
                    title: Icon(
                      Icons.person_pin,
                      color: Constants.primaryColor,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      stretchModes: [
                        StretchMode.zoomBackground,
                      ],
                    )),
                SliverFillRemaining(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    InkWell(
                      // onTap: () {
                      //   showCupertinoDialog(
                      //       context: context,
                      //       builder: (BuildContext context) =>
                      //           CupertinoAlertDialog(
                      //               title: Text("How do want the picture?"),
                      //               actions: <Widget>[
                      //                 CupertinoDialogAction(
                      //                     child: Text("Camera"),
                      //                     onPressed: () {
                      //                       _uploadImage(true);
                      //                       Navigator.of(context).pop();
                      //                     }),
                      //                 CupertinoDialogAction(
                      //                   child: Text("Gallery"),
                      //                   onPressed: () {
                      //                     _uploadImage(false);
                      //                     Navigator.of(context).pop();
                      //                   },
                      //                 )
                      //               ]));
                      // },
                      child: ClipOval(
                        child: Container(
                          width: 100,
                          height: 100,
                          child: _image == null
                              ? CachedNetworkImage(
                                  imageUrl: _user['dp'],
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
                              : Image.file(_image, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Text('অ্যাকাউন্ট',
                        style: TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 30.0)),
                    SizedBox(height: 20),
                    Text(('নাম: ' + _user['username']),
                        style: TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 20.0)),

                    ListTile(
                      title: Text('বাসার ঠিকানা বদলান:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18.0)),
                      subtitle: Text(_user['locationString'],
                          style: TextStyle(
                              fontWeight: FontWeight.w300, fontSize: 18.0)),
                      onTap: () async {
                        Prediction p = await PlacesAutocomplete.show(
                            context: context,
                            apiKey: _kGoogleApiKey,
                            mode: Mode.fullscreen,
                            onError: (value) =>
                                print("String >>" + value.errorMessage),
                            language: "en",
                            region: "bd",
                            components: [
                              new Component(Component.country, "bd"),
                            ]);
                        if (p != null) {
                          var addresses = await Geocoder.local
                              .findAddressesFromQuery(p.description);
                          var first = addresses.first;

                          print(
                              "Coordinates of selected location: ${first.addressLine} : ${first.coordinates}");
                          GeoFirePoint location = Geoflutterfire().point(
                              latitude: first.coordinates.latitude,
                              longitude: first.coordinates.longitude);

                          try {
                            await Firestore.instance
                                .collection('users')
                                .document(_user['uid'])
                                .updateData({
                              'location': location.data,
                              'locationString': p.description
                            });
                          } catch (error) {
                            return;
                          }
                          setState(() {
                            _user['location'] = location.data;
                            _user['locationString'] = p.description;
                          });
                        }
                      },
                    ),
                    // if (_userPost != null) ...[
                    //   ListTile(
                    //     title: Text('Change working area:',
                    //         style: TextStyle(
                    //             fontWeight: FontWeight.bold, fontSize: 18.0)),
                    //     subtitle: Text(_userPost['locationString'],
                    //         style: TextStyle(
                    //             fontWeight: FontWeight.w300, fontSize: 18.0)),
                    //     onTap: () async {
                    //       Prediction p = await PlacesAutocomplete.show(
                    //           context: context,
                    //           apiKey: _kGoogleApiKey,
                    //           mode: Mode.fullscreen,
                    //           onError: (value) =>
                    //               print("String >>" + value.errorMessage),
                    //           language: "en",
                    //           region: "bd",
                    //           components: [
                    //             new Component(Component.country, "bd"),
                    //           ]);
                    //       if (p != null) {
                    //         var addresses = await Geocoder.local
                    //             .findAddressesFromQuery(p.description);
                    //         var first = addresses.first;

                    //         print(
                    //             "Coordinates of selected location: ${first.addressLine} : ${first.coordinates}");
                    //         GeoFirePoint location = Geoflutterfire().point(
                    //             latitude: first.coordinates.latitude,
                    //             longitude: first.coordinates.longitude);

                    //         try {
                    //           await Firestore.instance
                    //               .collection('posts')
                    //               .document(_userPost['uid'])
                    //               .updateData({
                    //             'location': location.data,
                    //             'locationString': p.description
                    //           });
                    //         } catch (error) {
                    //           return;
                    //         }
                    //         setState(() {
                    //           _userPost['location'] = location.data;
                    //           _userPost['locationString'] = p.description;
                    //         });
                    //       }
                    //     },
                    //   ),
                    // ],
                    Divider(),
                    ListTile(
                      title: Text('অ্যাকাউন্ট ডিলিট করুন',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18.0)),
                      trailing: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onTap: () async {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  content: Text(
                                      'আপনি কি নিশ্চিত? আপনার অ্যাকাউন্ট এর এড(যদি থাকে) এবং অন্যান্য তথ্য মিটিয়ে দেয়া হবে'),
                                  actions: [
                                    FlatButton(
                                      child: Text('না'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    FlatButton(
                                      child: Text('হ্যাঁ'),
                                      onPressed: () async {
                                        // the phone has been launched from init
                                        _deletePost(
                                            _user['uid'], _user['dpOriginal']);

                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ));
                      },
                    ),
                  ],
                )),
              ],
            ),
          );
  }

  _logout() async {
    var firebaseAuth = FirebaseAuth.instance;
    await firebaseAuth.signOut();
    _initializeUser();

    print("Logged out");
  }

  _deletePost(String docId, String imagePath) async {
    setState(() {
      _user = null;
    });
    await Firestore.instance.document('posts' + '/' + docId).delete();
    await Firestore.instance.document('users' + '/' + docId).delete();
    await FirebaseStorage.instance
        .ref()
        .child((await FirebaseAuth.instance.currentUser()).uid)
        .delete()
        .then((_) => print('$imagePath'));
    _logout();
  }

  _initializeUser() async {
    FirebaseUser userF = await FirebaseAuth.instance.currentUser();
    if (userF == null) {
      Navigator.pushReplacementNamed(context, '/register');
      return;
    }
    DocumentSnapshot userDoc = await Firestore.instance
        .collection('users')
        .document(userF.phoneNumber)
        .get();
    DocumentSnapshot userPost = await Firestore.instance
        .collection('posts')
        .document(userF.phoneNumber)
        .get();
    setState(() {
      _user = userDoc.data;
      _userPost = userPost.data;
    });
  }
}
