//
//  AppDelegate.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ValueTransformer.setValueTransformer(MLMultiArrayTransformer(), forName: NSValueTransformerName("MLMultiArrayTransformer"))
        return true
    }

}
