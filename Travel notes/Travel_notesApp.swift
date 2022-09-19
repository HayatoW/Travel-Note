//
//  Travel_notesApp.swift
//  Travel notes
//
//  Created by Hayato Watanabe on 2022/09/19.
//

import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // initialize Amplify
        let _ = Backend.initialize()
        
        return true
    }
}

@main
struct Travel_notesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
