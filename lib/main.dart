import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: VideoApp(),
    );
  }
}

class VideoApp extends StatefulWidget {
  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController _controller;
  String percentage = "0.0";
  String url =
      'http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4';
  String path;
  File file;
  @override
  void initState() {
    super.initState();
    getPath();
    downloadFiles(url).then((result) => getPermission());
    // getPermission();
  }

  getPermission() async {
    PermissionStatus permissionResult =
        await SimplePermissions.requestPermission(
            Permission.WriteExternalStorage);
    if (permissionResult == PermissionStatus.authorized) {
      // code of read or write file in external storage (SD card)
      setState(() {
        file = File(path);
      });
    }
  }

  getPath() async {
    var tempDir = await getTemporaryDirectory();

    // setState(() {
    //   path = tempDir.path + "/big_buck_bunny_720p_20mb.mp4";
    // });
    _controller = VideoPlayerController.file(File(tempDir.path + "/big_buck_bunny_720p_20mb.mp4"))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    print('full path $path');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: Center(
          child: _controller.value.initialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : Container(child: Text(percentage.toString())),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future downloadFiles(String url) async {
    try {
      Dio dio = Dio();

      Response response = await dio.get(
        url,
        onReceiveProgress: showDownloadProgress,

        //Received data with List<int>
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status < 500;
            }),
      );
      print("header section    " + response.headers.toString());
      File file = File(path);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);

      await raf.close();

      return true;
    } catch (e) {
      print(e);
    }
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      print((received / total * 100).toString() + "%");

      setState(() {
        percentage = (received / total * 100).toString() + "%";
      });
    }
  }
}
