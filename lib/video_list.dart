import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import 'package:video_upload/video_player.dart';

class VideoList extends StatefulWidget {
  @override
  _VideoListState createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  List<DocumentSnapshot> documents;

  getData(AsyncSnapshot<QuerySnapshot> snapshot, context) {
    return snapshot.data.documents.map((doc) {
      return Column(
        children: <Widget>[
          FutureBuilder(
            future: FirebaseStorage.instance
                .ref()
                .child("videos/${doc["link"]}")
                .getDownloadURL(),
            builder: (context, projectSnap) {
              if (projectSnap.connectionState == ConnectionState.none ||
                  projectSnap.connectionState == ConnectionState.waiting) {
                //print('project snapshot data is: ${projectSnap.data}');
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Container(
                        height: MediaQuery.of(context).size.height * .38,
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                        height: MediaQuery.of(context).size.height * .38,
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: VideoPlayerScreen(
                            path: projectSnap.data, uid: doc["link"])),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video List'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: new BottomAppBar(
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(height: MediaQuery.of(context).size.height * .05),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton.extended(
        heroTag: "nu",
        icon: Icon(Icons.add),
        label: Text('Upload Video'),
        onPressed: () => Navigator.pop(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection("videos").snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData)
              return Center(
                child: new Text("There is no Videos"),
              );
            else
              return ListView(
                children: getData(snapshot, context),
              );
          }),
    );
  }
}
