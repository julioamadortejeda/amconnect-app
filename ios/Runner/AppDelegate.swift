import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AmConnectAudioPlugin") else {
      return
    }

    let messenger = registrar.messenger()

    // ── EventChannel: streams PCM chunks (Uint8List) from mic to Flutter ───────
    let inputChannel = FlutterEventChannel(name: "com.amconnect/audio_input",
                                           binaryMessenger: messenger)
    inputChannel.setStreamHandler(VoiceAudioManager.shared)

    // ── MethodChannel: control (start, playPcm, stopPlayback, stop) ───────────
    let controlChannel = FlutterMethodChannel(name: "com.amconnect/audio",
                                              binaryMessenger: messenger)
    controlChannel.setMethodCallHandler { (call, result) in
      switch call.method {

      case "startAudio":
        VoiceAudioManager.shared.startRequestingPermissionIfNeeded { error in
          if let error = error {
            result(FlutterError(code: "AUDIO_START_ERROR",
                                message: error.localizedDescription, details: nil))
          } else {
            result(nil as Any?)
          }
        }

      case "playPcm":
        guard let args = call.arguments as? [String: Any],
              let b64 = args["data"] as? String,
              let data = Data(base64Encoded: b64) else {
          result(FlutterError(code: "BAD_ARGS", message: "Expected {data: base64}", details: nil))
          return
        }
        VoiceAudioManager.shared.playPcm(data)
        result(nil as Any?)

      case "stopPlayback":
        VoiceAudioManager.shared.stopPlayback()
        result(nil as Any?)

      case "stopAudio":
        VoiceAudioManager.shared.stop()
        result(nil as Any?)

      case "isPlaybackDone":
        result(VoiceAudioManager.shared.isPlaybackDone)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
