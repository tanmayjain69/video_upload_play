import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String path;
  final String uid;

  VideoPlayerScreen({Key key, @required this.path, this.uid}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState(
        path: this.path,
      );
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFeature;
  final String path;
  bool icon;

  _VideoPlayerScreenState({Key key, @required this.path});

  @override
  void initState() {
    icon = false;
    _controller = VideoPlayerController.network(path);
    _initializeVideoPlayerFeature = _controller.initialize();
    _controller.setLooping(true);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double defaultScreenWidth = 411.42857142857144;
    double defaultScreenHeight = 891.4285714285714;
    ScreenUtil.init(
      context,
      width: defaultScreenWidth,
      height: defaultScreenHeight,
      allowFontScaling: true,
    );
    return Scaffold(
      body: FutureBuilder(
        future: _initializeVideoPlayerFeature,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox.expand(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * .95,
                      height: MediaQuery.of(context).size.height * .3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Container(
                          height: ScreenUtil().setHeight(45),
                          width: ScreenUtil().setHeight(45),
                          child: FloatingActionButton(
                            heroTag: 'none',
                            backgroundColor: Colors.deepOrange,
                            elevation: 0,
                            onPressed: () {
                              Firestore.instance
                                  .collection('videos')
                                  .document(widget.uid
                                      .substring(0, widget.uid.length - 4))
                                  .delete()
                                  .catchError((e) {
                                print(e);
                              });
                            },
                            child: Icon(
                              Icons.delete_forever,
                            ),
                          ),
                        ),
                        Container(
                          height: ScreenUtil().setHeight(45),
                          width: ScreenUtil().setHeight(45),
                          child: FloatingActionButton(
                            heroTag: 'none1',
                            backgroundColor: Colors.blue,
                            elevation: 0,
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                                icon = !icon;
                              });
                            },
                            child: Icon(
                              icon ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                        ),
                        Container(
                          height: ScreenUtil().setHeight(45),
                          width: ScreenUtil().setHeight(45),
                          child: FloatingActionButton(
                            heroTag: 'none2',
                            backgroundColor: Colors.blue,
                            elevation: 0,
                            onPressed: () {
                              setState(() {
                                _controller.pause();
                                icon = false;
                                _controller.seekTo(Duration.zero);
                              });
                            },
                            child: Icon(
                              Icons.refresh,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          return Container(
              width: MediaQuery.of(context).size.width * .95,
              height: MediaQuery.of(context).size.height * .5,
              child: Center(child: CircularProgressIndicator()));
        },
      ),

//        floatingActionButton: FloatingActionButton(
//          onPressed: () {
//            setState(() {
//
//              if (_controller.value.isPlaying) {
//                _controller.pause();
//              } else {
//                _controller.pause();
//                _controller.play();
//              }
//            });
//          },
//          child: Icon(
//            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//          ),
//        )
    );
  }
}
