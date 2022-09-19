//
//  ContentView.swift
//  Travel notes
//
//  Created by Hayato Watanabe on 2022/09/19.
//

import SwiftUI

// singleton object to store user data
class UserData: ObservableObject {
    private init()  {}
    static let shared = UserData()
    
    @Published var notes: [Note] = []
    @Published var isSingnedIn = false
}

// the data class to represents Notes
class Note: Identifiable, ObservableObject {
    var id: String
    var name: String
    var description: String?
    var imageName: String?
    @Published var image: Image?
    
    init(id: String, name: String, description: String? = nil, imageName: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = imageName
    }
    
    convenience init(from data: NoteData) {
        self.init(id: data.id, name: data.name, description: data.description, imageName: data.image)
        
        // store API object for easy retrieval later
        self._data = data
    }
    
    fileprivate var _data: NoteData?
    
    // access the privately stored NoteData or build one if we don't have one
    var data: NoteData {
        if (_data == nil) {
            _data = NoteData(id: self.id, name: self.name, description: self.description, image: self.imageName)
        }
        
        return _data!
    }
}

// a view to represent a single list item
struct ListRow: View {
    @ObservedObject var note: Note
    var body: some View {
        
        return HStack(alignment: .center, spacing: 5.0) {
            
            // if there is an image, display it on the left
            if (note.image != nil) {
                note.image!
                .resizable()
                .frame(width: 50, height: 50)
            }
            
            // the right part is a vertical stack with the title and description
            VStack(alignment: .leading, spacing: 5.0) {
                Text(note.name)
                .bold()
                
                if ((note.description) != nil) {
                    Text(note.description!)
                }
            }
        }
    }
}

// this is the main view of our app
// it is made of a Table with one line per Note
struct ContentView: View {
    @ObservedObject private var userData: UserData = .shared
    
    @State var showCreateNote = false
    
    @State var name = "New Note"
    @State var description = "This is a new note"
    @State var imageName = "image"
    
    var body: some View {
        ZStack {
            if (userData.isSingnedIn) {
                NavigationView {
                    List {
                        ForEach(userData.notes) { note in
                            ListRow(note: note)
                        }
                    }
                    .navigationBarTitle(Text("Notes"))
                    .navigationBarItems(leading: SignOutButton(),
                                        trailing: Button(action: {
                        self.showCreateNote.toggle()
                    }) {
                        Image(systemName: "plus")
                    })
                }.sheet(isPresented: $showCreateNote) {
                    AddNoteView(isPresented: self.$showCreateNote, userData: self.userData)
                }
            } else {
                SignInButton()
            }
        }
    }
}

struct SignInButton: View {
    var body: some View {
        Button(action: { Backend.shared.signIn() }) {
            HStack {
                Image(systemName: "person.fill")
                    .scaleEffect(1.5)
                    .padding()
                Text("Sign In")
                    .font(.largeTitle)
            }
            .padding()
            .foregroundColor(.white)
            .background(.green)
            .cornerRadius(30)
        }
    }
}

struct SignOutButton: View {
    var body: some View {
        Button(action: { Backend.shared.signOut() }) {
            Text("Sign Out")
        }
    }
}

struct AddNoteView: View {
    @Binding var isPresented: Bool
    var userData: UserData
    
    @State var name = "New Note"
    @State var description = "This is a new note"
    @State var imageName = "image"
    
    var body: some View {
        Form {
            Section(header: Text("TEXT")) {
                TextField("Name", text: $name)
                TextField("Name", text: $description)
            }
            
            Section(header: Text("PICTURE")) {
                TextField("Name", text: $imageName)
            }
            
            Section {
                Button(action: {
                    self.isPresented = false
                    let noteData = NoteData(id: UUID().uuidString, name: self.$name.wrappedValue, description: self.$description.wrappedValue)
                    let note = Note(from: noteData)
                    
                    // asynchronously store the note (and assume it will succeed)
                    Backend.shared.createNote(note: note)
                    
                    // add the new note in our userdata, this will refresh UI
                    self.userData.notes.append(note)
                }) {
                    Text("Create this note")
                }
            }
        }
    }
}

// this is use to preview the UI in Xcode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        let _ = prepareTestData()
        
        return ContentView()
    }
}

// this is a test data set to preview th UI in Xcode
func prepareTestData() -> UserData {
    let userData = UserData.shared
    userData.isSingnedIn = true
    let description = "this is very long description that should fit on multiple lines.\nit even has a line break\nor two."
    
    let n1 = Note(id: "01", name: "Hello, world", description: description, imageName: "mic")
    let n2 = Note(id: "02", name: "A new note", description: description, imageName: "phone")
    
    n1.image = Image(systemName: n1.imageName!)
    n2.image = Image(systemName: n2.imageName!)
    
    userData.notes = [n1, n2]
    
    return userData
}
