import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_upload/video_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoUpload extends StatefulWidget {
  @override
  _VideoUploadState createState() => _VideoUploadState();
}

class _VideoUploadState extends State<VideoUpload> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Duration limit = Duration(minutes: 5);
  File _videoFile;
  VideoPlayerController _controller;

  Size size;
  Duration duration;

  void _toast() {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(
        'File Exceeds 20 mb',
        textAlign: TextAlign.center,
      ),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.deepOrange,
    )); //Toast
  }

  Future<void> pickVideo(ImageSource source) async {
    if (_controller != null) _clear();

    File selected = await ImagePicker.pickVideo(source: source);

    if (selected.lengthSync() > 2e+7) {
      _toast();
    } else {
      setState(() {
        _videoFile = selected;
        _controller = VideoPlayerController.file(selected)
          ..initialize().then((_) {
            if (_controller.value.duration > limit)
              setState(() => _videoFile = null);
            _controller.addListener(checkVideo);
          });
      });
    }
  }

  void checkVideo() {
    if (_controller.value.position == _controller.value.duration) {
      setState(() {
        _controller.pause();
        _controller.seekTo(Duration.zero);
      });
    }
  }

  /// Remove Video
  void _clear() {
    _controller.pause();
    setState(() => _videoFile = null);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Video Upload'),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: new FloatingActionButton(
        heroTag: 'nu',
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
        onPressed: () => pickVideo(ImageSource.gallery),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.video_library,
                  size: MediaQuery.of(context).size.width * .08,
                ),
                onPressed: () {
                  if (_videoFile != null) _clear();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VideoList()),
                  );
                }),
            IconButton(
              onPressed: _clear,
              icon: Icon(
                Icons.refresh,
                size: MediaQuery.of(context).size.width * .08,
              ),
            ),
          ],
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_videoFile != null) ...[
                Container(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * .03),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .03,
                    ),
                    RaisedButton(
                      onPressed: () {
                        setState(() {
                          _controller.seekTo(Duration.zero);
                          _controller.pause();
                        });
                      },
                      child: Icon(
                        Icons.refresh,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Uploader(
                    file: _videoFile,
                  ),
                )
              ] else ...[
                Container(
                  alignment: Alignment(0.0, 0.0),
                  child: Text(
                    "Choose a video to upload",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                GestureDetector(
                  onTap: () => pickVideo(ImageSource.gallery),
                  child: Icon(
                    Icons.cloud_upload,
                    color: Colors.blue[300],
                    size: MediaQuery.of(context).size.width * .4,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget used to handle the management of
class Uploader extends StatefulWidget {
  final File file;

  Uploader({Key key, this.file}) : super(key: key);

  createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  final FirebaseStorage _storage = FirebaseStorage(
      storageBucket: 'gs://pushnotification-242907.appspot.com');

  StorageUploadTask _uploadTask;
  DateTime url;

  _startUpload() {
    url = DateTime.now();
    String filePath = 'videos/${url}.mp4';

    setState(() {
      _uploadTask = _storage
          .ref()
          .child(filePath)
          .putFile(widget.file, StorageMetadata(contentType: 'video/mp4'));
    });
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
    if (_uploadTask != null) {
      return StreamBuilder<StorageTaskEvent>(
          stream: _uploadTask.events,
          builder: (context, snapshot) {
            var event = snapshot?.data?.snapshot;

            double progressPercent = event != null
                ? event.bytesTransferred / event.totalByteCount
                : 0;
            if (_uploadTask.isComplete) {
              Firestore.instance
                  .collection("videos")
                  .document("${url}")
                  .setData({
                'link': '${url}.mp4',
              });
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '🎉🎉🎉',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      height: 2,
                      fontSize: ScreenUtil().setSp(25),
                    ),
                  ),
                  LinearProgressIndicator(value: progressPercent),
                  Text(
                    '${(progressPercent * 100).toStringAsFixed(2)} % ',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(20),
                    ),
                  ),
                ],
              );
            }
            if (_uploadTask.isInProgress) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LinearProgressIndicator(value: progressPercent),
                  Text(
                    '${(progressPercent * 100).toStringAsFixed(2)} % ',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(20),
                    ),
                  ),
                ],
              );
            }
            return Column();
          });
    } else {
      return FlatButton.icon(
          color: Colors.blueAccent,
          label: Text(
            'Upload to Firebase',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(
            Icons.cloud_upload,
            color: Colors.white,
          ),
          onPressed: _startUpload);
    }
  }
}
