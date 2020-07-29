import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                Container(
                  child: Text(
                    "Say one of the words below!",
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
        initialChildSize: 96 / height,
        minChildSize: 96 / height,
        maxChildSize: 144 / height,
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
                            Padding(
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
                            )
                          ],
                        ),
                      )
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
