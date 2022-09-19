//
//  File.swift
//  Travel notes
//
//  Created by Hayato Watanabe on 2022/09/19.
//

import UIKit
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSS3StoragePlugin

class Backend {
    static let shared = Backend()
    static func initialize() -> Backend {
        return .shared
    }
    private init() {
        // initialize amplify
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            print("Initialized Amplify")
        } catch  {
            print("Could not initialize Amplify: \(error)")
        }
        
        // listen to auth events
        // see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
        _ = Amplify.Hub.listen(to: .auth) { payload in
            
            switch payload.eventName {
                
            case HubPayload.EventName.Auth.signedIn:
                print("==Hub== User signed in, update UI")
                self.updateUserData(withSignInStatus: true)
                
            case HubPayload.EventName.Auth.signedOut:
                print("==Hub== User signed out, update UI")
                self.updateUserData(withSignInStatus: false)
                
            case HubPayload.EventName.Auth.sessionExpired:
                print("==Hub==  Session expired, show sign in UI")
                self.updateUserData(withSignInStatus: false)
                
            default:
                break
            }
        }
        
        // let's check if user is signed in or not
        _ = Amplify.Auth.fetchAuthSession { result in
            do {
                let session = try result.get()
                
                // let's update UserData and the UI
                self.updateUserData(withSignInStatus: session.isSignedIn)
            } catch {
                print("Fetch auth session failed with error - \(error)")
            }
        }
    }
    
    // MARK: - User Authentication

    // sign in with Cognito web user interface
    public func signIn() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        _ = Amplify.Auth.signInWithWebUI(presentationAnchor: window!) { result in
            switch result {
            case .success(_):
                print("Sign in succeeded")
            case .failure(let error):
                print("Sign in failed \(error)")
            }
        }
    }

    // sign out
    public func signOut() {
        _ = Amplify.Auth.signOut() { result in
            switch result {
            case .success:
                print("Successfully signed out")
            case .failure(let error):
                print("Sign out failed with error \(error)")
            }
        }
    }

    // change our internal state, this triggers an UI update on the main thread
    func updateUserData(withSignInStatus status: Bool) {
        DispatchQueue.main.async() {
            let userData: UserData = .shared
            userData.isSingnedIn = status
            
            // when user is signed in, query the database, otherwise empty our model
            if status {
                self.queryNotes()
            } else {
                userData.notes = []
            }
        }
    }
    
    // MARK: - API Access
    
    func queryNotes() {
        _ = Amplify.API.query(request: .list(NoteData.self)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let notesData):
                    print("Successfully retrieved list of Notes")
                    
                    // convert an array of NoteData to an array of Note class instances
                    for noteData in notesData {
                        let note = Note.init(from: noteData)
                        DispatchQueue.main.async() {
                            UserData.shared.notes.append(note)
                        }
                    }
                    
                case .failure(let error):
                    print("Can not retrieve result: error \(error.errorDescription)")
                }
            case .failure(let error):
                print("Can not retrieve Notes: error \(error)")
            }
        }
    }
    
    func createNote(note: Note) {
        
        // use note.data to access the NoteData instance
        _ = Amplify.API.mutate(request: .create(note.data)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    print("Successfully created note: \(data)")
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Got failed event with error \(error)")
            }
        }
    }
    
    func deleteNote(note: Note) {
        
        // use note.data to access the NoteData instance
        _ = Amplify.API.mutate(request: .delete(note.data)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    print("Successfully deleted note: \(data)")
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Got failed event with error \(error)")
            }
        }
    }
    
    // MARK: - Image Storage
    func storeImage(name: String, image: Data) {
        let _ = Amplify.Storage.uploadData(key: name, data: image) { event in
            switch event {
            case .success(let data):
                print("Image upload completed: \(data)")
            case .failure(let storageError):
                print("Image upload failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            }
        }
    }
    
    func retrieveImage(name: String, completed: @escaping (Data) -> Void) {
        let _ = Amplify.Storage.downloadData(key: name) { event in
            switch event {
            case let .success(data):
                print("Image \(name) loaded")
                completed(data)
            case let .failure(storageError):
                print("Can not download image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            }
        }
    }
    
    func deleteImage(name: String) {
        let _ = Amplify.Storage.remove(key: name) { event in
            switch event {
            case let .success(data):
                print("Image \(data) deleted")
            case let .failure(storageError):
                print("Can not delete image: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            }
        }
    }
}
