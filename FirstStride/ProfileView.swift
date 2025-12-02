//
//  ProfileView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import UIKit

enum ApperanceStyle {
    case lbs
    case kg
}

enum ApperanceStyle2 {
    case mile
    case kilometer
}


struct menuAndButtonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ProfileView: View {
    var signOutAction: (() -> Void)? = nil
    @EnvironmentObject var authVM: AuthViewModel
    @State private var changePswd: String = ""
    @State private var showingSignOutConfirm = false
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var shouldShowImagePicker = false
    @State private var AccountDetailPresented = false
    @State private var StatsDetailsPresented = false
    @State private var ChangePasscodePresented = false
    @State private var manageFriendPresented = false
    @State private var selectedOption: ProfileOptions? = nil
    @State private var isEditing = false
    @State private var apperance: ApperanceStyle = .kg
    @State private var apperance2: ApperanceStyle2 = .kilometer
    @State private var image: UIImage?
    @State private var isUploading = false
    private let imageService = ImageStorageService.shared

    
    
    
    var heightText: String{
        guard let profile = authVM.profile else{
            return "No data"
        }
        let cm = profile.heightCm
        if cm <= 0 {
            return "No Data"
        }
        switch apperance{
        case .kg:
            return String(format: "%.1f", cm)
            
        case .lbs:
            let totalInches = cm / 2.54
            var feet = Int(totalInches / 22)
            var inches = Int((totalInches.truncatingRemainder(dividingBy: 12)).rounded())
            
            if inches == 12{
                feet += 1
                inches = 0
            }
            return "\(feet) ft \(inches) in"
        }
    }
    
    
    var weightText: String {
            guard let profile = authVM.profile else {
                return "Not set"
            }

            let kg = profile.weightKg
            if kg <= 0 {
                return "Not set"
            }

            switch apperance {
            case .kg:
                return String(format: "%.1f kg", kg)
            case .lbs:
                let lbs = kg * 2.20462
                return String(format: "%.1f lbs", lbs)
            }
        }
    
    var body: some View {
        VStack(spacing: 12) {
            if let u = Auth.auth().currentUser {

                if u.isAnonymous {
                    Text("Signed in as Guest")
                        .foregroundStyle(.secondary)
                }

                //Allows user to choose and set profile picture
                HStack {
                    Button {
                        shouldShowImagePicker.toggle()
                    } label: {
                        VStack {
                            if let image = self.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128)
                                    .cornerRadius(64)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 64))
                                    .padding()
                                    .foregroundColor(Color(.label))
                            }

                            if isUploading {
                                ProgressView("Uploading…")
                                    .font(.caption)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }

                
                NavigationView {
                    List {
                        
                        Section {
                            // Account details sheet
                            Button("Account Detail ") {
                                AccountDetailPresented = true
                            }
                            .sheet(isPresented: $AccountDetailPresented) {
                                if let userEmail = u.email {
                                    NavigationView {
                                        VStack {
                                            List {
                                                Section(header: Text("Name").font(.headline)) {
                                                    if let profile = authVM.profile {
                                                        Text(profile.name)
                                                    }
                                                }
                                            }
                                            List {
                                                Section(header: Text("Email").font(.headline)) {
                                                    Text(userEmail)
                                                }
                                            }
                                            List {
                                                Section(header: Text("UID").font(.headline)) {
                                                    Text(u.uid)
                                                }
                                            }
                                            Spacer()
                                                .padding()

                                            Button("Close") {
                                                AccountDetailPresented = false
                                            }
                                        }
                                        .navigationTitle("Account Details")
                                    }
                                }
                            }

                            // Body stats sheet
                            Button("Body Stats ") {
                                StatsDetailsPresented = true
                            }
                            .sheet(isPresented: $StatsDetailsPresented) {
                                NavigationView {
                                    VStack {
                                        List {
                                            Section(header: Text("Height(cm) and Weight(kg)").font(.headline)) {
                                                Text("Height: \(heightText)")
                                                Text("Weight: \(weightText)")

                                            }
                                        }
                                        Spacer()
                                            .padding()
                                        Button("Close") {
                                            StatsDetailsPresented = false
                                        }
                                    }
                                    .navigationTitle("Body Stats")
                                }
                            }

                            
                            Button("Change Password ") {
                                ChangePasscodePresented = true
                            }
                            .sheet(isPresented: $ChangePasscodePresented) {
                                NavigationView {
                                    VStack {
                                        List {
                                            Section(header: Text("New Password")) {
                                                SecureField("New password", text: $changePswd)
                                            }
                                        }

                                        // show authVM messages (optional)
                                        if let error = authVM.errorMessage {
                                            Text(error)
                                                .foregroundColor(.red)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                        }

                                        if let info = authVM.infoMessage {
                                            Text(info)
                                                .foregroundColor(.green)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                        }

                                        Spacer()

                                        Button("Update Password") {
                                            Task {
                                                await authVM.changePassword(to: changePswd)
                                                if authVM.errorMessage == nil {
                                                    ChangePasscodePresented = false
                                                    changePswd = ""
                                                }
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .padding(.bottom)

                                        Button("Close") {
                                            ChangePasscodePresented = false
                                            changePswd = ""
                                        }
                                        .padding(.bottom)
                                    }
                                    .navigationTitle("Change Password")
                                }
                            }

                        } header: {
                            Text("Account")
                        }

                        
                        Section {
                            Button("Manage Friends") {
                                manageFriendPresented = true
                            }
                            .sheet(isPresented: $manageFriendPresented) {
                                NavigationView {
                                    VStack {
                                        List {
                                            Section(header: Text("Friends").font(.headline)) {
                                                Text("Alani")
                                                Text("Andrew")
                                                Text("Doug")
                                                Text("Mathew")
                                                Text("Reni")
                                                Text("Tobi")
                                                Text("Eliceo")
                                            }
                                        }
                                        Spacer()
                                        Button("Close") {
                                            manageFriendPresented = false
                                        }
                                    }
                                    .navigationTitle("Friends")
                                }
                            }
                        } header: {
                            Text("Social")
                        }

                        
                        Section {
                            Picker("Change Units of Weight", selection: $apperance) {
                                Text("Lbs").tag(ApperanceStyle.lbs)
                                Text("Kg").tag(ApperanceStyle.kg)
                            }

                            Picker("Change units of Distance", selection: $apperance2) {
                                Text("Miles").tag(ApperanceStyle2.mile)
                                Text("Kilometers").tag(ApperanceStyle2.kilometer)
                            }

                        } header: {
                            Text("Units of Measurements")
                        }
                    }
                }

                Spacer()

                
                if let error = signOutError {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign Out button
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
                .confirmationDialog(
                    "Are you sure you want to sign out?",
                    isPresented: $showingSignOutConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Sign Out", role: .destructive) {
                        performSignOut()
                    }
                    Button("Cancel", role: .cancel) { }
                }

                if isSigningOut {
                    ProgressView("Signing out...")
                        .padding(.top)
                }
            } else {
                Text("Not signed in")
                Spacer()
            }
        }
        .padding()
        .fullScreenCover(isPresented: $shouldShowImagePicker) {
            ImagePicker(image: $image)
        }
        .onChange(of: image) { newImage in
            guard let newImage else { return }

            isUploading = true

            Task {
                do {
                    try await imageService.uploadProfileImage(newImage)
                    print("Profile image uploaded")
                } catch {
                    print("Failed to save image: \(error.localizedDescription)")
                }
                isUploading = false
            }
        }
        .onAppear {
            loadProfileImage()
        }
    }

   

    private func performSignOut() {
        isSigningOut = true
        signOutError = nil

        if let action = signOutAction {
            action()
            finishSignOut()
            return
        }

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


    private func loadProfileImage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error loading profile doc: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let urlString = data["photoURL"] as? String,
                  let url = URL(string: urlString) else {
                // no photoURL set yet
                return
            }

            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                    return
                }

                if let data = data, let downloadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = downloadedImage
                    }
                }
            }.resume()
        }
    }
}

struct ProfileOptions: Identifiable {
    let id = UUID()
    var title: String
    var description: String
}
