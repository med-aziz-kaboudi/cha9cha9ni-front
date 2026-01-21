import Flutter
import UIKit
// Firebase disabled - requires paid Apple Developer account for push notifications
// import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var privacyOverlay: UIVisualEffectView?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase disabled - requires paid Apple Developer account for push notifications
    // FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Add blur overlay when app goes to background
  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    showPrivacyOverlay()
  }
  
  // Remove blur overlay when app becomes active
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    hidePrivacyOverlay()
  }
  
  private func showPrivacyOverlay() {
    guard privacyOverlay == nil, let window = self.window else { return }
    
    // Create blur effect with light style
    let blurEffect = UIBlurEffect(style: .systemMaterialLight)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = window.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.tag = 999
    
    // Add your horizontal logo - responsive to screen size
    let logoView = UIImageView(image: UIImage(named: "Logo"))
    logoView.contentMode = .scaleAspectFit
    logoView.translatesAutoresizingMaskIntoConstraints = false
    blurView.contentView.addSubview(logoView)
    
    // Center logo and make it 60% of screen width (responsive for all devices)
    NSLayoutConstraint.activate([
      logoView.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
      logoView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
      logoView.widthAnchor.constraint(equalTo: blurView.contentView.widthAnchor, multiplier: 0.6),
      logoView.heightAnchor.constraint(equalTo: logoView.widthAnchor, multiplier: 0.4)
    ])
    
    window.addSubview(blurView)
    privacyOverlay = blurView
  }
  
  private func hidePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
