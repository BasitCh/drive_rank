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

  // NOTE: incoming-URL handling for FirebaseAuth's OAuthProvider callback
  // (Google sign-in) lives in SceneDelegate.swift, not here — this app
  // has UIApplicationSceneManifest configured in Info.plist, which means
  // application(_:open:options:) is never called on iOS 13+; the actual
  // entry point for URL-open events is UISceneDelegate's
  // scene(_:openURLContexts:). Don't re-add a handler here; it would be
  // dead code.

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
