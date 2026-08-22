import Firebase
import FirebaseAuth
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  // FirebaseAuth's OAuthProvider flow (Google sign-in — see
  // FirebaseAuthService.signInWithGoogle) redirects back into the app via
  // the custom URL scheme registered in Info.plist. This app uses iOS's
  // Scene-based lifecycle (UIApplicationSceneManifest in Info.plist), so
  // that callback arrives here, not in AppDelegate's
  // application(_:open:options:) (which is never called once scenes are
  // configured). Without this override, the callback URL fell through to
  // FlutterSceneDelegate's own openURLContexts handling and into
  // Flutter's deep-link system, where go_router failed to match it as an
  // app route ("GoException: no routes for location: ...") — it never
  // reached Firebase Auth's completion handler, so sign-in silently
  // never resolved. `Auth.auth().canHandle(url)` consumes exactly that
  // one URL and returns true; anything else falls through to Flutter
  // (via `super`) as normal.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    // NB: this method is reached via Firebase's GULSceneDelegateSwizzler
    // forwarding the SFSafariViewController OAuth callback through
    // NSInvocation. Do NOT call NSLog/os_log here — Swift's varargs
    // bridging (withVaList) reliably SIGBUS/KERN_PROTECTION_FAILURE
    // crashes when invoked from this specific ObjC-swizzled forwarding
    // context (confirmed via crash reports: every crash faulted inside
    // _platform_strlen/__CFStringAppendFormatCore under an NSLogv frame
    // called from exactly this method).
    let url = URLContexts.first?.url
    let handled = url.map { Auth.auth().canHandle($0) } ?? false
    if handled {
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
