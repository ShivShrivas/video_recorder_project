import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoCaptureScreen(),
    );
  }
}
class VideoCaptureScreen extends StatefulWidget {
  @override
  _VideoCaptureScreenState createState() => _VideoCaptureScreenState();
}


class _VideoCaptureScreenState extends State<VideoCaptureScreen> {
  late CameraController _controller;
  late VideoPlayerController _videoController;
  late Future<void> _initializeControllerFuture;
  Timer? _timer;
  int _countdownSeconds = 31;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    setState(() {
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.ultraHigh,
      );
    });


    final filePath = DateTime.now().millisecondsSinceEpoch.toString() + '.mp4';
    _videoController = VideoPlayerController.asset('assets/$filePath');

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller!=null? Stack(
        children: <Widget>[
          FutureBuilder<void>(
            future: _controller.initialize(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Visibility(child: IconButton(

                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _toggleFlash();
                    },
                  ),visible: true,)
                  ,
                  Visibility(child: IconButton(
                    icon: Icon(
                      _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _toggleCamera();
                    },
                  ),visible: _countdownSeconds==31?true:false,),

                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  _startRecording(context);
                },
                child: Text(_countdownSeconds.toString()),
              ),
            ),
          ),
        ],
      ):Center(child: CircularProgressIndicator(),),
    );
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _updateFlash();
    });
  }

  void _updateFlash() {
    if (_isFlashOn) {
      _controller.setFlashMode(FlashMode.torch);
    } else {
      _controller.setFlashMode(FlashMode.off);
    }
  }

  void _toggleCamera() async {
    final cameras = await availableCameras();
    final newCamera = _isFrontCamera ? cameras.first : cameras.last;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    setState(() {
       _controller.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.ultraHigh,

      );
        _controller.initialize();
    });

    _updateFlash(); // Update flash mode after switching cameras
  }

  Future<void> _startRecording(BuildContext context) async {
    try {
      await _controller.startVideoRecording();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_countdownSeconds == 0) {
            _stopRecording();
            timer.cancel();
          } else {
            _countdownSeconds--;
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void _stopRecording() async {
    try {
      XFile videoFile = await _controller.stopVideoRecording();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayScreen(videoPath: videoFile.path),
        ),
      );
    } catch (e) {
      print(e);
    }
  }
}

class VideoPlayScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayScreen({required this.videoPath});

  @override
  _VideoPlayScreenState createState() => _VideoPlayScreenState();
}

class _VideoPlayScreenState extends State<VideoPlayScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(
      File(widget.videoPath),
    )..initialize().then((_) {
      setState(() {});
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Playback'),
      ),
      body: Center(
        child: _videoController.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}