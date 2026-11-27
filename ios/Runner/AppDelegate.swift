import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var secureScreen: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerSecureScreen(engineBridge.pluginRegistry)
  }

  /// iOS cannot block screenshots; it reports when the screen is recorded
  /// or mirrored, and sensitive screens then hide their content.
  /// See lib/core/security/secure_screen.dart.
  private func registerSecureScreen(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "CivicSecureScreen") else { return }
    let channel = FlutterMethodChannel(
      name: "civic/secure_screen",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isCaptured":
        result(UIScreen.main.isCaptured)
      case "enable", "disable":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { _ in
      channel.invokeMethod("capturedChanged", arguments: UIScreen.main.isCaptured)
    }
    secureScreen = channel
  }
}
