import Flutter
import UIKit

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
    // Optionale Apple-Music-Anbindung (MusicKit, iOS 15+).
    if #available(iOS 15.0, *) {
      if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppleMusicPlugin") {
        AppleMusicPlugin.register(with: registrar)
      }
    }
  }
}
