package org.demen.speech_commands;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import org.tensorflow.lite.Interpreter;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.util.Objects;

/**
 * SpeechCommandsPlugin
 */
public class SpeechCommandsPlugin implements FlutterPlugin, MethodCallHandler {

    private static volatile SpeechCommandsPlugin instance;

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private AssetManager assetManager;

    private Interpreter tfLite;

    void load(String model) throws IOException {
        tfLite = new Interpreter(loadModelFile(FlutterLoader.getInstance().getLookupKeyForAsset(model)).asReadOnlyBuffer());
    }

    private MappedByteBuffer loadModelFile(String modelPath) throws IOException {
        AssetFileDescriptor fileDescriptor = assetManager.openFd(modelPath);
        FileInputStream inputStream = new FileInputStream(fileDescriptor.getFileDescriptor());
        FileChannel fileChannel = inputStream.getChannel();
        long startOffset = fileDescriptor.getStartOffset();
        long declaredLength = fileDescriptor.getDeclaredLength();
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "speech_commands");
        channel.setMethodCallHandler(this);
        assetManager = flutterPluginBinding.getApplicationContext().getAssets();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "load": {
                try {
                    final String model = call.argument("model");
                    getInstance().load(model);
                    result.success(null);
                } catch (Exception e) {
                    result.error("loadError", e.getMessage(), e.getCause());
                }
                break;
            }
            default:
                result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    public SpeechCommandsPlugin() {
        // Protect against instantiation via reflection
        if (instance == null) {
            instance = this;
        } else {
            throw new IllegalStateException("Already initialized.");
        }
    }

    /**
     * The instance doesn't get created until the method is called for the first time.
     */
    public static synchronized SpeechCommandsPlugin getInstance() {
        if (instance == null) {
            synchronized (SpeechCommandsPlugin.class) {
                if (instance == null) {
                    instance = new SpeechCommandsPlugin();
                }
            }
        }
        return instance;
    }
}
