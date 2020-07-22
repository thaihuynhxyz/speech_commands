import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:speech_commands/speech_commands.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await SpeechCommands.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
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
        body: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Cell("Yes"),
                  Cell("No"),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Cell("Up"),
                  Cell("Down"),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Cell("Left"),
                  Cell("Right"),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Cell("On"),
                  Cell("Off"),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Cell("Stop"),
                  Cell("Go"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  ///
  /// This will be null if a [textSpan] is provided instead.
  final String data;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Text(data),
        margin: EdgeInsets.all(10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Color(0xFFAAAAAA),
            ),
            borderRadius: BorderRadius.all(Radius.circular(5))),
      ),
    );
  }
}
