//
//  ProfileView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//
import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileView: View {
    var signOutAction: (() -> Void)? = nil

    @State private var showingSignOutConfirm = false
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var avatarImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showSheet = false
    
    @State private var profileOptList = [
        ProfileOptions(title: "Account Details", description: "View Account Details"),
        ProfileOptions(title: "Measuerments", description: "Change body measuerments"),
        ProfileOptions(title: "Mange Friends", description: "Mange Your Friends"),
        ProfileOptions(title: "Units of Weight", description: "Chnage the units of Weight Kg, lb")
    ]
    @State private var selectedOption: ProfileOptions? = nil
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 12) {
            if let u = Auth.auth().currentUser {
                
                Text("Profile")
                    .font(.headline)
                //Text(u.uid).font(.footnote).textSelection(.enabled)
                if let userName = u.email {Text(userName)}
                if u.isAnonymous { Text("Signed in as Guest").foregroundStyle(.secondary) }
                
                HStack() {
                    
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Image(uiImage: avatarImage ?? UIImage(resource: .defaultAvatar))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipShape(.circle)
                    }
                }
                
                NavigationView{
                    List{
                        Section(header: Text("Account Details")){
                            ForEach(profileOptList){ option in
                                HStack{
                                    VStack(alignment: .leading){
                                        Text(option.title)
                                            .font(.headline)
                                        Text(option.description)
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedOption = option
                                    isEditing = true
                                }
                            }
                        }
                   }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("Profile")
                    .sheet(isPresented: $isEditing){
                        if let selectedOption = selectedOption,
                           let index = profileOptList.firstIndex(where: { $0.id == selectedOption.id}){
                            EditProfileSheet(
                                option: $profileOptList[index],
                                isPresented: $isEditing
                            )
                        }
                    }
                }



                Spacer()

                if let error = signOutError {
                    Text(error).foregroundColor(.red).multilineTextAlignment(.center).padding(.horizontal)
                }
                
                

                Button(role: .destructive) {
                    showingSignOutConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground).opacity(0.06))
                    .cornerRadius(8)
                }
                .disabled(isSigningOut)
                .padding(.horizontal)
                .confirmationDialog("Are you sure you want to sign out?", isPresented: $showingSignOutConfirm, titleVisibility: .visible) {
                    Button("Sign Out", role: .destructive) {
                        performSignOut()
                    }
                    Button("Cancel", role: .cancel) { }
                }

                if isSigningOut {
                    ProgressView("Signing out...").padding(.top)
                }
            } else {
                Text("Not signed in")
                Spacer()
            }
        }
        .padding()
        .onChange(of: photoPickerItem){_,_ in
            Task {
                if let photoPickerItem,
                    let data = try? await photoPickerItem.loadTransferable(type: Data.self){
                    if let image = UIImage(data: data){
                        avatarImage = image
                    }
                }
                photoPickerItem = nil
            }
        }
    }

    private func performSignOut() {
        isSigningOut = true
        signOutError = nil

        // If a closure was provided by the parent, call it so parent handles sign-out.
        if let action = signOutAction {
            action()
            finishSignOut()
            return
        }

        // Otherwise, fall back to Firebase sign out directly.
        do {
            try Auth.auth().signOut()
            finishSignOut()
        } catch {
            signOutError = error.localizedDescription
            isSigningOut = false
        }
    }

    
    private func finishSignOut() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isSigningOut = false
        }
    }
}




struct ProfileOptions: Identifiable{
    let id = UUID()
    var title: String
    var description: String
}


struct OptionDetailView: View {
    let option: ProfileOptions
    
    var body: some View{
        Text(option.title)
            .font(.largeTitle)
        Text(option.description)
            .font(.body)
    }
    
}


struct EditProfileSheet: View{
    
    @Binding var option: ProfileOptions
    @Binding var isPresented: Bool
    
    var body: some View{
        NavigationView{
            Form {
                Section(header: Text("Edit")){
                    TextField("Title", text: $option.title)
                    TextField("Title", text: $option.description)
                }
            }
            .navigationTitle("Edit Option")
            .toolbar{
                ToolbarItem(placement: .confirmationAction){
                    Button("Done"){
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction){
                    Button("Cancel"){
                        isPresented = false

            }
                }
            }
        }
    }
}
