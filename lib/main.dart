import 'dart:async';
import 'package:dinmojur/account.dart';
import 'package:dinmojur/leaderboard.dart';
import 'package:location/location.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:dinmojur/auth/get_phone.dart';
import 'package:dinmojur/common_widgets.dart';
import 'package:dinmojur/post.dart';
import 'package:dinmojur/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'editPost.dart';

void main() {
  runApp(MyApp());
  //Admob.initialize(getAppId());
}

const String testDevice = 'A481DB8BD0638D4BA0C4812D6468A543';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          // When navigating to the "/" route, build the FirstScreen widget.

          // When navigating to the "/second" route, build the SecondScreen widget.

          '/register': (context) => PhoneAuthGetPhone(),
          '/registerSecondPart': (context) => Register(),
        },
        // dear team, change here to get your page
        theme: ThemeData(
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: Colors.grey,
                  displayColor: Colors.grey,
                )),
        home: Feed());
  }
}

class Feed extends StatefulWidget {
  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  bool isRewardAdLoaded = true;
  Map<String, dynamic> _user;
  String searchString = '';
  static int postsPerAd = 2;
  final int _cIndex = 0;
  GeoFirePoint _location;
  ScrollController _scrollController;
  bool searchBoxVisible = false;
  Map<String, dynamic> _servicePost;
  int _callLimit = 5;
  double _radius = 500.0;
  RewardedVideoAd _videoAd = RewardedVideoAd.instance;
  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey<ScaffoldState>();

  //This is to check whether to use current location or home address
  bool _isLocationCurrent = false;
  String phoneCurrent = '';
  List<String> _searchTags = [];
  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    testDevices: testDevice != null ? <String>[testDevice] : null,
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    childDirected: true,
    nonPersonalizedAds: true,
  );

  TextEditingController _searchController = TextEditingController();
  final String firestoreDir = 'posts';
  List<Widget> posts = [];

  @override
  void initState() {
    super.initState();
    _initializeUser();

    //FirebaseAdMob.instance.initialize(appId: FirebaseAdMob.testAppId);
    //---------------------------------------//
    //Initialise the listener with the values.
    _videoAd.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      if (event == RewardedVideoAdEvent.rewarded ||
          event == RewardedVideoAdEvent.closed) {
        //When the video ad gets completed load a new video ad
        _videoAd
            .load(
                adUnitId: RewardedVideoAd.testAdUnitId,
                targetingInfo: targetingInfo)
            .catchError((e) => print('Error in loading. =>$e'));
      }

      if (event == RewardedVideoAdEvent.loaded) {
        print('ad loaded');
        setState(() {
          isRewardAdLoaded = true;
          _callLimit += 5;
        });
      }
    };
    //------------------------------------------------------------------//

    //This will load the video when the widget is built for the first time.
    _videoAd
        .load(
            adUnitId: RewardedVideoAd.testAdUnitId,
            targetingInfo: targetingInfo)
        .catchError((e) => print('Error in loading. =>$e'));

    //-----------------------------------------------------//
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _user == null
        ? LoadingWidget()
        : SafeArea(
            child: Scaffold(
            key: _scaffoldkey,
            body: Container(
                color: Colors.transparent,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                    SliverAppBar(
                        automaticallyImplyLeading: true,
                        elevation: 100.0,
                        floating: true,
                        stretch: true,
                        iconTheme: new IconThemeData(color: Colors.grey),
                        actions: [
                          IconButton(
                              icon: searchBoxVisible
                                  ? Icon(Icons.close)
                                  : Icon(Icons.search),
                              onPressed: () {
                                setState(() {
                                  searchBoxVisible = !searchBoxVisible;
                                });
                              })
                        ],
                        backgroundColor: Colors.transparent,
                        stretchTriggerOffset: 100.0,
                        expandedHeight: searchBoxVisible ? 200.0 : 100,
                        centerTitle: true,
                        title: Icon(
                          Icons.home,
                          color: Constants.primaryColor,
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          title: Wrap(
                            alignment: WrapAlignment.center,
                            children: <Widget>[
                              if (searchBoxVisible) ...[
                                Theme(
                                    data: new ThemeData(
                                        primaryColor: Colors.blue),
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 20,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: TextFormField(
                                          controller: _searchController,
                                          style: TextStyle(
                                              height: 1, fontSize: 12.0),
                                          decoration: InputDecoration(
                                              isDense: true,
                                              hintText: 'সার্চ...',
                                              hintStyle: TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w300),
                                              suffixIcon: Icon(
                                                Icons.search,
                                                size: 20.0,
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                color: Colors.grey,
                                              ))),
                                          onChanged: (value) {
                                            setState(() {
                                              searchString = value;
                                            });
                                          },
                                        ))),
                                ChipsChoice<String>.multiple(
                                    itemConfig: ChipsChoiceItemConfig(
                                      labelStyle: TextStyle(
                                          color: Colors.white, fontSize: 10.0),
                                      selectedBrightness: Brightness.dark,
                                      selectedColor: Constants.primaryColor,
                                      unselectedColor: Colors.grey,
                                    ),
                                    value: _searchTags,
                                    isWrapped: false,
                                    options: ChipsChoiceOption.listFrom<String,
                                        String>(
                                      source: <String>[
                                        'Liked',
                                        'ইলেক্ট্রিসিয়ান',
                                        'প্লাম্বার',
                                        'টিভি রিপেয়ার',
                                        'এসি রিপেয়ার',
                                        'ছুটা বুয়া'
                                      ],
                                      value: (i, v) => v,
                                      label: (i, v) => v,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchTags =
                                            val.map((e) => e).toList();
                                        if (val.contains('Liked'))
                                          val.remove('Liked');
                                        searchString = val.join('');
                                      });
                                    }),
                              ] else ...[
                                _searchController.text.isEmpty
                                    ? Container()
                                    : Text(
                                        "Showing search results for '${_searchController.text}'",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12.0),
                                      ),
                              ]
                            ],
                          ),

                          // background: Image.asset(
                          //   Constants.background,
                          //   fit: BoxFit.cover,
                          // ),
                          stretchModes: [
                            StretchMode.zoomBackground,
                          ],
                          centerTitle: true,
                        )),
                    SliverList(
                      delegate: SliverChildListDelegate([_buildBody(context)],
                          addRepaintBoundaries: true),
                    ),
                  ],
                )),
            floatingActionButton: FloatingActionButton(
                backgroundColor: Constants.primaryColor,
                child:
                    Icon(_isLocationCurrent ? Icons.my_location : Icons.home),
                onPressed: _initLocation),
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  DrawerHeader(
                    child: Column(
                      children: <Widget>[
                        ClipOval(
                          child: Container(
                            width: 100,
                            height: 100,
                            child: CachedNetworkImage(
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
                            ),
                          ),
                        ),
                        Text(
                          _user['username'],
                          textAlign: TextAlign.justify,
                          textScaleFactor: 1.5,
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(color: Colors.white),
                  ),
                  ListTile(
                    title: Text(_servicePost != null
                        ? "আপনার সার্ভিস এড এডিট করুণ"
                        : "সার্ভিস এড দিন"),
                    onTap: () async {
                      Navigator.pop(context);
                      bool result = false;
                      if (_servicePost == null)
                        result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Post(_user)));
                      else
                        result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditPost(_servicePost)));

                      if (result) {
                        setState(() {
                          _user = null;
                        });
                        _initializeUser();
                      } else
                        setState(() {});
                    },
                  ),
                  ListTile(
                    title: Text('শিখুন'),
                    onTap: () {
                      launch('https://www.facebook.com/dinmojur5667');
                    },
                  ),
                  ListTile(
                    title: Text("টপ পারফর্মার"),
                    onTap: () {
                      if (_cIndex == 2) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LeaderBoard()));
                    },
                  ),
                  ListTile(
                    title: Text("অ্যাকাউন্ট"),
                    onTap: () {
                      if (_cIndex == 3) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Account()));
                    },
                  ),
                  ListTile(
                    title: Text('সাহায্য'),
                    onTap: () {
                      launch('https://www.facebook.com/dinmojur5667');
                    },
                  ),
                  ListTile(
                    title: Text("লগআউট"),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  )
                ],
              ),
            ),
          ));
  }

  Widget _buildListAd(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(10.0),
        child: Card(
            elevation: 20.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: Colors.white,
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Center(
                    child: AdmobBanner(
                        adUnitId: BannerAd.testAdUnitId,
                        adSize: AdmobBannerSize.BANNER,
                        listener:
                            (AdmobAdEvent event, Map<String, dynamic> args) {
                          switch (event) {
                            case AdmobAdEvent.loaded:
                              print('Admob banner loaded!');
                              break;

                            case AdmobAdEvent.opened:
                              print('Admob banner opened!');
                              break;

                            case AdmobAdEvent.closed:
                              print('Admob banner closed!');
                              break;

                            case AdmobAdEvent.failedToLoad:
                              print(
                                  'Admob banner failed to load. Error code: ${args['errorCode']}');
                              break;
                            default:
                              print('Something else');
                              break;
                          }
                        })))));
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _getPosts(),
      builder: (context, snapshot) {
        try {
          if (snapshot.data.length > 0) {
            List<DocumentSnapshot> doc = snapshot.data;

            // print(streamLiked);

            if (searchString.isNotEmpty) {
              List<String> query = searchString.split(' ');

              doc.retainWhere((doc) {
                List tags = doc.data['tag'];

                String queryItems =
                    doc.data['phone'] + doc.data['name'] + tags.join('');

                for (int i = 0; i < query.length; i++) {
                  print(queryItems.contains(query[i]));

                  return queryItems.contains(query[i]);
                }

                return false;
              });
            }

            print('post lenght=>' + doc.length.toString());
            return _buildList(context, doc);
          } else if (snapshot.data.length == 0)
            return Center(child: Text("No results found"));
        } catch (error) {}
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshotList) {
    int temp = postsPerAd;
    int count = 0;
    return Column(
        children: List.generate(snapshotList.length, (index) {
      // if (count < postsPerAd)
      //   count++;
      // else {
      //   DocumentSnapshot empty;
      //   snapshotList.insert(index, empty);
      //   count = 0;
      // }

      return _buildListItem(context, snapshotList[index]);
    }));
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    var record = data.data;
    List tags = record['tag'];
    List likedBy = record['likedBy'] == null ? [] : record['likedBy'];
    bool hasLiked = likedBy.contains(_user['uid']);
    int likes = likedBy.length;
    String likeString = '';
    if (likedBy.length < 999)
      likeString = ((hasLiked ? likes - 1 : likes)).toString();
    else if (likedBy.length > 999 && likedBy.length < 1000000) {
      likeString = ((hasLiked ? likes - 1 : likes) / 1000).toString() + 'k';
    } else if (likedBy.length > 999999 && likedBy.length < 1000 * 1000 * 1000) {
      likeString = ((hasLiked ? likes - 1 : likes) / 1000000).toString() + 'M';
    } else if (likedBy.length > 999999999 && likedBy.length < (1000000000000)) {
      likeString =
          ((hasLiked ? likes - 1 : likes) / 1000000000).toString() + 'B';
    }
    String likeLabel = hasLiked
        ? (likes == 1 ? "You" : "You and " + likeString + " others") +
            " like this person"
        : likes == 0 ? "" : likeString + " likes";

    GeoPoint geoP = record['location']['geopoint'];
    GeoFirePoint point = GeoFirePoint(geoP.latitude, geoP.longitude);
    String distance = point
        .distance(
            lat: _location.coords.latitude, lng: _location.coords.longitude)
        .floor()
        .toString();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Container(
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // CachedNetworkImage(
                //   imageUrl: record['image'],
                //   width: MediaQuery.of(context).size.width,
                //   height: Constants.postHeight,
                //   repeat: ImageRepeat.noRepeat,
                //   placeholder: (context, url) => Container(
                //     height: Constants.postHeight,
                //     decoration: BoxDecoration(
                //         image: DecorationImage(
                //             image: AssetImage(Constants.loadgingPlaceHolder),
                //             fit: BoxFit.cover,
                //             repeat: ImageRepeat.noRepeat)),
                //     child: Center(
                //       child: CircularProgressIndicator(),
                //     ),
                //   ),
                //   fadeInCurve: Curves.bounceInOut,
                //   fit: BoxFit.cover,
                // ),
                //SizedBox(height: 10.0),
                SizedBox(height: 20),
                Wrap(
                    alignment: WrapAlignment.center,
                    direction: Axis.horizontal,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      //this sized box is a padding alternative

                      // Container(
                      //     margin: EdgeInsets.only(left: 8),
                      //     child: CircleAvatar(
                      //       backgroundImage:
                      //           CachedNetworkImageProvider(record['image']),
                      //       radius: 40.0,
                      //     )),
                      ClipOval(
                        child: Container(
                          width: 100,
                          height: 100,
                          child: CachedNetworkImage(
                            imageUrl: record['dp'],
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
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 8.0,
                      ),
                      SizedBox(width: 10),
                      Text(
                        record['name'],
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Wrap(
                          spacing: 4.0,
                          children: List.generate(
                              tags.length,
                              (index) => Chip(
                                    label: Text(tags[index],
                                        style: TextStyle(color: Colors.white)),
                                    backgroundColor:
                                        Colors.greenAccent.shade700,
                                  ))),
                      SizedBox(width: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(Icons.location_on, size: 20),
                            ),
                            TextSpan(
                                text: ("$distance km away"),
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16.0)),
                          ],
                        ),
                      ),
                    ]),
                // Center(
                //   child: Chip(
                //     label: Text(('Tk ' + record['wage'] + ' hourly'),
                //         style: TextStyle(color: Colors.white)),
                //     backgroundColor: Colors.greenAccent.shade700,
                //   ),
                // ),
                Divider(),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    '$likeLabel',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    RaisedButton.icon(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(25.0))),
                        color: Colors.white,
                        icon: Icon(Icons.call, color: Constants.primaryColor),
                        onPressed: () {
                          _callWorker(record['phone']);
                        },
                        label: Text('Call')),
                    RaisedButton.icon(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(25.0))),
                        color: Colors.white,
                        onPressed: () {
                          _updateLikes(data.documentID, likedBy, hasLiked);
                        },
                        icon: hasLiked
                            ? Icon(Icons.favorite,
                                color: Constants.primaryColor)
                            : Icon(
                                Icons.favorite_border,
                                color: Colors.grey,
                              ),
                        label: Text('like')),
                    // if (_user['uid'] == record['uid']) ...[
                    //   IconButton(
                    //       icon: Icon(
                    //         Icons.delete_outline,
                    //         color: Colors.red,
                    //       ),
                    //       onPressed: () {
                    //         _deletePost(data.documentID, record['image']);
                    //       }),
                    // ]
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _updateLikes(String docId, List likedBy, bool hasLiked) async {
    setState(() {
      hasLiked = !hasLiked;
    });
    if (hasLiked) {
      if (likedBy.contains(_user['uid'])) return;
      likedBy.add(_user['uid']);
    } else {
      if (!likedBy.contains(_user['uid'])) return;
      likedBy.remove(_user['uid']);
    }
    Firestore.instance
        .collection(firestoreDir)
        .document(docId)
        .updateData(<String, dynamic>{
      "likedBy": likedBy,
      "likes": likedBy.length
    }).catchError((error) {
      print('like posting error $error');
    });
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

    print(userDoc.exists);
    if (!userDoc.exists) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Register()));
      return;
    }
    DocumentSnapshot post = (await Firestore.instance
        .collection('posts')
        .document(userF.phoneNumber)
        .get());

    setState(() {
      _servicePost = post.data;
      _user = userDoc.data;
      GeoPoint geo = _user['location']['geopoint'];
      _location = Geoflutterfire()
          .point(latitude: geo.latitude, longitude: geo.longitude);
    });
  }

  Stream<List<DocumentSnapshot>> _getPosts() {
    var collRef = _searchTags.contains("Liked")
        ? Firestore.instance
            .collection(firestoreDir)
            .where('likedBy', arrayContains: _user['uid'])
        : Firestore.instance.collection(firestoreDir);

    return Geoflutterfire()
        .collection(collectionRef: collRef)
        .within(center: _location, radius: _radius, field: 'location');
  }

  _initLocation() async {
    if (_isLocationCurrent) {
      setState(() {
        GeoPoint geo = _user['location']['geopoint'];

        setState(() {
          _location = GeoFirePoint(geo.latitude, geo.longitude);
          _isLocationCurrent = false;
        });
        _scaffoldkey.currentState.showSnackBar(SnackBar(
            content:
                Text('আপনার বাসার নিকটবর্তী সার্ভিসম্যানদের দেখানো হচ্ছে...')));
      });
    } else {
      Location location = new Location();

      bool _serviceEnabled;
      PermissionStatus _permissionGranted;
      LocationData _locationData;

      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          _scaffoldkey.currentState.showSnackBar(SnackBar(
              content: Text(
                  'লকেশন সার্ভিস অন করা হয়নি তাই আপনার বাসার নিকটবর্তী সার্ভিসম্যানদের দেখানো হচ্ছে...')));
          return;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          _scaffoldkey.currentState.showSnackBar(SnackBar(
              content: Text(
                  'লকেশন সার্ভিস অনুমদিত হয়নি তাই আপনার বাসার নিকটবর্তী সার্ভিসম্যানদের দেখানো হচ্ছে...')));
          return;
        }
      }
      _locationData = await location.getLocation();

      setState(() {
        _isLocationCurrent = true;
        _location =
            GeoFirePoint(_locationData.latitude, _locationData.longitude);
      });
      _scaffoldkey.currentState.showSnackBar(SnackBar(
          content: Text(
              'আপনার বর্তমান অবস্থানের নিকটবর্তী সার্ভিসম্যানদের দেখানো হচ্ছে...')));
    }
  }

  _callWorker(String phone) async {
    if (_callLimit == 0 && isRewardAdLoaded) {
      phoneCurrent = phone;
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('একটি এড দেখুন?'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                      'যেহেতু আমরা কোন কমিশন বা পেমেন্ট কারো কাছ থেকেই নেই না, তাই দয়া করে আমাদের একটি এড দেখুন, তারপর আপনার সার্ভিসম্যান এর কাছে সক্রিয় ভাবে কল যাবে।',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('না'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('ঠিক আছে'),
                  onPressed: () async {
                    // the phone has been launched from init
                    _videoAd.show().catchError(
                        (e) => print("error in showing ad: ${e.toString()}"));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    } else {
      launch("tel://$phone");
      print('$isRewardAdLoaded reward ad');
      if (_callLimit > 0) _callLimit--;
    }
  }

  _loadRewardedAd() async {
    RewardedVideoAd.instance.load(
        adUnitId: RewardedVideoAd.testAdUnitId, targetingInfo: targetingInfo);
  }

  _logout() async {
    _scaffoldkey.currentState
        .showSnackBar(SnackBar(content: Text('You are being logged out...')));

    var firebaseAuth = FirebaseAuth.instance;
    await firebaseAuth.signOut();
    _initializeUser();

    print("Logged out");
  }
}
