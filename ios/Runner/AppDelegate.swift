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
    
    VoiceAudioManager.shared.onPlaybackFinished = {
      DispatchQueue.main.async {
        controlChannel.invokeMethod("playbackFinished", arguments: nil)
      }
    }

    // Reenvía los logs nativos de audio a Dart — print() de Swift no aparece
    // en la consola de `flutter run` cuando corre en dispositivo físico.
    VoiceAudioManager.shared.onLog = { msg in
      DispatchQueue.main.async {
        controlChannel.invokeMethod("nativeLog", arguments: msg)
      }
    }

    controlChannel.setMethodCallHandler { (call, result) in
      switch call.method {

      case "startAudio":
        VoiceAudioManager.shared.startRequestingPermissionIfNeeded { error in
          if let error = error {
            let nsError = error as NSError
            // code -1/-2 en el dominio "VoiceAudio" = permiso de mic denegado
            // (ver AudioManager.swift) — se distingue para que Dart pueda
            // mostrar "permiso denegado" en vez de un error genérico.
            let isPermissionDenied = nsError.domain == "VoiceAudio"
                && (nsError.code == -1 || nsError.code == -2)
            result(FlutterError(
                code: isPermissionDenied ? "MIC_PERMISSION_DENIED" : "AUDIO_START_ERROR",
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

      case "getAudioDevices":
        result(VoiceAudioManager.shared.getAudioDevices())

      case "selectAudioDevice":
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "Expected {id: String}", details: nil))
          return
        }
        VoiceAudioManager.shared.selectAudioDevice(id)
        result(nil as Any?)

      case "useBuiltInMic":
        VoiceAudioManager.shared.useBuiltInMic()
        result(nil as Any?)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
