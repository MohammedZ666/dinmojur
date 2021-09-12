import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'common_widgets.dart';

class LeaderBoard extends StatefulWidget {
  @override
  _LeaderBoardState createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderBoard> {
  final int _cIndex = 2;
  List users = [];
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return users.length == 0
        ? LoadingWidget()
        : Scaffold(
            bottomNavigationBar: BottomNavBar(_cIndex),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                    elevation: 100.0,
                    floating: true,
                    stretch: true,
                    backgroundColor: Colors.white,
                    stretchTriggerOffset: 100.0,
                    expandedHeight: 100.0,
                    centerTitle: true,
                    title: Icon(
                      Icons.insert_chart,
                      color: Constants.primaryColor,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text('leaderboard',
                          style: TextStyle(
                              fontWeight: FontWeight.w300, fontSize: 20.0)),
                      // background: Image.asset(
                      //   Constants.background,
                      //   fit: BoxFit.cover,
                      // ),
                      stretchModes: [
                        StretchMode.zoomBackground,
                      ],
                    )),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildListItem(index),
                      childCount: users.length),
                ),
              ],
            ),
          );
  }

  Widget _buildListItem(index) {
    DocumentSnapshot userDoc = users[index];
    Map<String, dynamic> data = userDoc.data;
    int rank = index + 1;
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Card(
          child: ListTile(
            leading: Text('$rank',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
            title: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(data['image']),
                ),
                SizedBox(width: 8),
                Text(
                  data['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
            trailing: Text(
              data['likes'].toString(),
              style: TextStyle(
                  color: Constants.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }

  Future<void> _loadUsers() async {
    List<DocumentSnapshot> docs = (await Firestore.instance
            .collection('posts')
            .orderBy('likes', descending: true)
            .getDocuments())
        .documents;
    setState(() {
      users = docs;
    });
  }
}
