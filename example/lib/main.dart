import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:speech_commands/speech_commands.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_commands_example/recognize_commands.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Constants that control the behavior of the recognition code and model
  // settings. See the audio recognition tutorial for a detailed explanation of
  // all these, but you should customize them to match your training settings if
  // you are running your own model.
  static const int SAMPLE_RATE = 16000;
  static const int SAMPLE_DURATION_MS = 1000;

//   static const int RECORDING_LENGTH =  SAMPLE_RATE * SAMPLE_DURATION_MS / 1000;
  static const int AVERAGE_WINDOW_DURATION_MS = 1000;
  static const double DETECTION_THRESHOLD = 0.5;
  static const int SUPPRESSION_MS = 1500;
  static const int MINIMUM_COUNT = 3;
  static const int MINIMUM_TIME_BETWEEN_SAMPLES_MS = 30;
  static const String MODEL_FILENAME = 'models/conv_actions_frozen.tflite';

  dynamic _labels = new List<String>();
  dynamic _displayedLabels = new List<String>();
  RecognizeCommands _recognizeCommands;
  PermissionStatus _permissionStatus = PermissionStatus.undetermined;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    loadLabel();

    // Set up an object to smooth recognition results to increase accuracy.
    _recognizeCommands = RecognizeCommands(
        _labels,
        AVERAGE_WINDOW_DURATION_MS,
        DETECTION_THRESHOLD,
        SUPPRESSION_MS,
        MINIMUM_COUNT,
        MINIMUM_TIME_BETWEEN_SAMPLES_MS);

    startRecording();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    await SpeechCommands.load(MODEL_FILENAME);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFFFFA800),
        primaryColorDark: Color(0xFFFF6F00),
        accentColor: Color(0xFF425066),
      ),
      home: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Container(
            color: Colors.white,
            child: Image.asset(
              'images/tfl2_logo_dark.png',
              fit: BoxFit.scaleDown,
              height: 32,
            ),
            padding: EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                Container(
                  child: Text(
                    _displayedLabels.join(', '),
//                    "Say one of the words below!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  padding: EdgeInsets.all(10),
                  color: Color(0xFFFFA800),
                  alignment: Alignment.center,
                ),
                Expanded(
                  child: Row(children: <Widget>[Cell("Yes"), Cell("No")]),
                ),
                Expanded(
                  child: Row(children: <Widget>[Cell("Up"), Cell("Down")]),
                ),
                Expanded(
                  child: Row(children: <Widget>[Cell("Left"), Cell("Right")]),
                ),
                Expanded(
                  child: Row(children: <Widget>[Cell("On"), Cell("Off")]),
                ),
                Expanded(
                  child: Row(children: <Widget>[Cell("Stop"), Cell("Go")]),
                ),
                SizedBox(height: 100)
              ],
            ),
            Sheet(),
          ],
        ),
      ),
    );
  }

  Future<String> loadLabel() async {
    var label = await rootBundle.loadString('models/conv_actions_labels.txt');
    setState(() {
      // Load the labels for the model, but only display those that don't start
      // with an underscore.
      _labels = LineSplitter().convert(label);
      _displayedLabels = _labels
          .where((value) => !value.startsWith('_'))
          .map((e) => '${e.substring(0, 1).toUpperCase()}${e.substring(1)}');
    });
    return label;
  }

  void startRecording() {
    if (_permissionStatus == PermissionStatus.granted) {
      developer.log('startRecording');
      SpeechCommands.record();
    } else {
      requestPermission(Permission.speech);
    }
  }

  Future<void> requestPermission(Permission permission) async {
    final status = await permission.status;
    setState(() => _permissionStatus = status);

    if (status == PermissionStatus.granted) {
      startRecording();
    } else {
      final status = await permission.request();

      setState(() {
        _permissionStatus = status;
        if (status == PermissionStatus.granted) startRecording();
      });
    }
  }
}

class Cell extends StatelessWidget {
  const Cell(
    this.data, {
    Key key,
  })  : assert(
          data != null,
          'A non-null String must be provided to a Text widget.',
        ),
        super(key: key);

  /// The text to display.
  final String data;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Text(data),
        margin: EdgeInsets.all(10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Color(0xFFAAAAAA)),
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
      ),
    );
  }
}

class Sheet extends StatefulWidget {
  @override
  _SheetState createState() {
    return _SheetState();
  }
}

class _SheetState extends State<Sheet> {
  String _image = 'images/icn_chevron_up.png';

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height - 24 - 56;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (DraggableScrollableNotification notification) {
        if (notification.extent >
            (notification.maxExtent + notification.minExtent) / 2) {
          _image = 'images/icn_chevron_down.png';
        } else {
          _image = 'images/icn_chevron_up.png';
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 88 / height,
        minChildSize: 88 / height,
        maxChildSize: 156 / height,
        builder: (BuildContext context, ScrollController scrollController) {
          _scrollListener() {
            var position = scrollController.position;
            if (position.userScrollDirection == ScrollDirection.reverse) {
              _image = 'images/icn_chevron_down.png';
            } else if (position.userScrollDirection ==
                ScrollDirection.forward) {
              _image = 'images/icn_chevron_up.png';
            }
          }

          scrollController.addListener(_scrollListener);
          return SingleChildScrollView(
            controller: scrollController,
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(
                        _image,
                        fit: BoxFit.scaleDown,
                        height: 5,
                      ),
                      SizedBox(height: 10),
                      Row(children: <Widget>[
                        Text("Sample Rate"),
                        Spacer(),
                        Text("16000 Hz"),
                      ]),
                      SizedBox(height: 10),
                      Row(children: <Widget>[
                        Text("Inference Time"),
                        Spacer(),
                        Text("32ms"),
                      ]),
                      SizedBox(height: 8),
                      Container(height: 1, color: Color(0xFFAAAAAA)),
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Text("Threads"),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Icon(Icons.remove),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('1'),
                                  ),
                                  Icon(Icons.add),
                                ],
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1, color: Color(0xFFAAAAAA)),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(height: 1, color: Color(0xFFAAAAAA)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
