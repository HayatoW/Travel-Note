//
//  File.swift
//  Travel notes
//
//  Created by Hayato Watanabe on 2022/09/19.
//

import UIKit
import Amplify
import AWSCognitoAuthPlugin

class Backend {
    static let shared = Backend()
    static func initialize() -> Backend {
        return .shared
    }
    private init() {
        // initialize amplify
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("Initialized Amplify")
        } catch  {
            print("Could not initialize Amplify: \(error)")
        }
    }
}
