import 'dart:ffi'; // For FFI
import 'dart:io'; // For Platform.isX
import 'dart:async';

import 'package:flutter/services.dart';

final DynamicLibrary nativeTfliteLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_tflite.so")
    : DynamicLibrary.process();

final int Function(int x, int y) nativeAdd = nativeTfliteLib
    .lookup<NativeFunction<Int32 Function(Int32, Int32)>>("native_add")
    .asFunction();

final void Function() nativeAudioCreate = nativeTfliteLib
    .lookup<NativeFunction<Void Function()>>("native_audio_create")
    .asFunction();

final void Function() nativeAudioStart = nativeTfliteLib
    .lookup<NativeFunction<Void Function()>>("native_audio_start")
    .asFunction();

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

  static Future<void> record() async {
    // Errors occurring on the platform side cause invokeMethod to throw
    // PlatformExceptions.
    // try {
    //   return _channel.invokeMethod('record');
    // } on PlatformException catch (e) {
    //   throw 'Unable to record audio: ${e.message}';
    // }
    nativeAudioCreate();
    nativeAudioStart();
  }
}
