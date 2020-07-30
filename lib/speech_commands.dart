import 'dart:async';

import 'package:flutter/services.dart';

class SpeechCommands {
  static const MethodChannel _channel = const MethodChannel('speech_commands');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> load(String model) async {
    // Errors occurring on the platform side cause invokeMethod to throw
    // PlatformExceptions.
    try {
      return _channel.invokeMethod('load', <String, dynamic>{'model': model});
    } on PlatformException catch (e) {
      throw 'Unable to init model $model: ${e.message}';
    }
  }
}
