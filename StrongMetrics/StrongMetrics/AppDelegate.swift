// AppDelegate.swift

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        customizeAppearance()
        return true
    }

    private func customizeAppearance() {
        // Navigation bar appearance (unused but set globally for any push-presented VCs)
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = AuraPalette.cosmicDeep
            appearance.titleTextAttributes = [
                .foregroundColor: AuraPalette.starWhite,
                .font: AuraTypeface.headline(18)
            ]
            UINavigationBar.appearance().standardAppearance  = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }

        // Force portrait orientation globally
//        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

//    // MARK: Orientation Lock (portrait only for iPhone)
//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        // iPad: allow landscape in compatible mode (runs portrait-layout, just scaled)
//        if UIDevice.current.userInterfaceIdiom == .pad { return .all }
//        return .portrait
//    }
}
