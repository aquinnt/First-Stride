//
//  ProfileView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
//


import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

struct Friend: Identifiable, Codable {
    let id: String
    let name: String
}

// Weight units
enum ApperanceStyle {
    case lbs
    case kg
}

// Height units (your code uses .mile as inches)
enum ApperanceStyle2 {
    case mile
    case centimeter
}

struct ProfileView: View {
    var signOutAction: (() -> Void)? = nil
    @EnvironmentObject var authVM: AuthViewModel



    // Main State

    @State private var changePswd: String = ""
    @State private var showingSignOutConfirm = false
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var shouldShowImagePicker = false

    // Sheet Visibility
    @State private var AccountDetailPresented = false
    @State private var StatsDetailsPresented = false
    @State private var ChangePasscodePresented = false
    @State private var manageFriendPresented = false

    // Units
    @State private var apperance: ApperanceStyle = .kg
    @State private var apperance2: ApperanceStyle2 = .centimeter

    // Profile Editing State
    @State private var editedName: String = ""
    @State private var editedHeight: String = ""
    @State private var editedWeight: String = ""

    // Image
    @State private var image: UIImage?
    @State private var isUploading = false
    private let imageService = ImageStorageService.shared
    @State private var friends: [Friend] = []
    @State private var newFriendName: String = ""

    
    
    
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
                
                // Button Style
                struct ProfileActionButton: ViewModifier {
                    func body(content: Content) -> some View {
                        content
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                        
                            .padding(.horizontal)
                    }
                }
                
                
                var body: some View {
                    NavigationView {
                        ScrollView {
                            VStack(spacing: 22) {
                                
                                
                                VStack(spacing: 16) {
                                    
                                    Button { shouldShowImagePicker.toggle() } label: {
                                        VStack {
                                            if let image = self.image {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 128, height: 128)
                                                    .clipShape(Circle())
                                            } else {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 64))
                                                    .padding()
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            if isUploading {
                                                ProgressView("Uploading…")
                                                    .font(.caption)
                                                    .padding(.top, 4)
                                            }
                                        }
                                    }
                                    
                                    Text(authVM.profile?.name ?? "User")
                                        .font(.title2).fontWeight(.bold)
                                    
                                    // AGE DISPLAY
                                    if let age = calculateAge(from: authVM.profile?.birthday) {
                                        Text("Age: \(age)")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                    }
                                    
                                    Text(Auth.auth().currentUser?.email ?? "No email")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    
                                    
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color(.systemGray6))
                                        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                                )
                                .padding(.horizontal)
                                
                                
                                
                                profileCard(title: "Account", icon: "person.crop.circle") {
                                    
                                    Button("Account Details") {
                                        editedName = authVM.profile?.name ?? ""
                                        AccountDetailPresented = true
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())
                                    
                                    Button("Body Stats") {
                                        preloadStats()
                                        StatsDetailsPresented = true
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())
                                    
                                    Button("Change Password") {
                                        ChangePasscodePresented = true
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())
                                }
                                
                                
                                
                                
                                
                                profileCard(title: "Social", icon: "person.3.fill") {
                                    
                                    Button("Manage Friends") {
                                        manageFriendPresented = true
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())
                                }
                                
                                
                                
                                
                                profileCard(title: "Units & Measurements", icon: "ruler") {
                                    
                                    Picker("Weight", selection: $apperance) {
                                        Text("Lbs").tag(ApperanceStyle.lbs)
                                        Text("Kg").tag(ApperanceStyle.kg)
                                    }
                                    
                                    Picker("Height Units", selection: $apperance2) {
                                        Text("Inches").tag(ApperanceStyle2.mile)
                                        Text("Centimeters").tag(ApperanceStyle2.centimeter)
                                    }
                                }
                                
                                
                                
                                
                                Button {
                                    showingSignOutConfirm = true
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Sign Out")
                                        Spacer()
                                    }
                                }
                                .modifier(ProfileActionButton())
                                
                            }
                            .padding(.vertical)
                        }
                        .navigationTitle("Profile")
                    }
                    
                    // IMAGE PICKER
                    .fullScreenCover(isPresented: $shouldShowImagePicker) {
                        ImagePicker(image: $image)
                    }
                    
                    // LOAD IMAGE
                    .onAppear { loadProfileImage() }
                    
                    // AUTO SAVE UPLOAD
                    .onChange(of: image) { img in
                        if let img = img { uploadImage(img) }
                    }
                    
                    
                    .sheet(isPresented: $AccountDetailPresented) { accountDetailPage }
                    .sheet(isPresented: $StatsDetailsPresented) { bodyStatsPage }
                    .sheet(isPresented: $ChangePasscodePresented) { changePasswordPage }
                    .sheet(isPresented: $manageFriendPresented) { friendsPage }
                }
                
                
                @ViewBuilder
                func profileCard<Content: View>(title: String,
                                                icon: String,
                                                @ViewBuilder content: () -> Content) -> some View {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(.red)
                                .font(.title2)
                            Text(title)
                                .font(.title3).fontWeight(.semibold)
                            Spacer()
                        }
                        
                        content()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    )
                    .padding(.horizontal)
                }
                
<<<<<<< HEAD
                // ---------------------------------------------------------
                // MARK: SHEET PAGES
                // ---------------------------------------------------------
=======
                    profileCard(title: "Social", icon: "person.3.fill") {

                        Button("Manage Friends") {
                            manageFriendPresented = true
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }



                    
                    profileCard(title: "Units & Measurements", icon: "ruler") {

                        Picker("Weight", selection: $apperance) {
                            Text("Lbs").tag(ApperanceStyle.lbs)
                            Text("Kg").tag(ApperanceStyle.kg)
                        }

                        Picker("Height Units", selection: $apperance2) {
                            Text("Inches").tag(ApperanceStyle2.mile)
                            Text("Centimeters").tag(ApperanceStyle2.centimeter)
                        }
                    }



                    
                    Button {
                        showingSignOutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                    .modifier(ProfileActionButton())

                }
                .padding(.vertical)
            }
                        .navigationTitle("Profile")
        }

        // IMAGE PICKER
        .fullScreenCover(isPresented: $shouldShowImagePicker) {
            ImagePicker(image: $image)
        }

        // LOAD IMAGE
        .onAppear { loadProfileImage() }

        // AUTO SAVE UPLOAD
        .onChange(of: image) { img in
            if let img = img { uploadImage(img) }
        }

        
        .sheet(isPresented: $AccountDetailPresented) { accountDetailPage }
        .sheet(isPresented: $StatsDetailsPresented) { bodyStatsPage }
        .sheet(isPresented: $ChangePasscodePresented) { changePasswordPage }
        .sheet(isPresented: $manageFriendPresented) { friendsPage }
        
        .alert("Sign Out?", isPresented: $showingSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                authVM.signOut()
            }
            Button("Cancel", role: .cancel) { }
        }

    }

    
    @ViewBuilder
    func profileCard<Content: View>(title: String,
                                    icon: String,
                                    @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.red)
                    .font(.title2)
                Text(title)
                    .font(.title3).fontWeight(.semibold)
                Spacer()
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        )
        .padding(.horizontal)
    }



    // ACCOUNT DETAILS
    var accountDetailPage: some View {
        NavigationView {
            VStack(spacing: 20) {

                headerCard(title: "Update Account Info",
                           subtitle: "Modify your personal account information.")

                List {
                    Section(header: Text("Name")) {
                        HStack {
                            Image(systemName: "person").foregroundColor(.red)
                            TextField("Name", text: $editedName)
                        }
                    }
                    Section(header: Text("Age")) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.red)
                            Text("\(authVM.profile?.age ?? 0) years old")
                                .foregroundColor(.primary)
                        }
                    }

                    Section(header: Text("Email")) {
                        HStack {
                            Image(systemName: "envelope").foregroundColor(.red)
                            Text(Auth.auth().currentUser?.email ?? "")
                        }
                    }
                    Section(header: Text("UID")) {
                        HStack {
                            Image(systemName: "number").foregroundColor(.red)
                            Text(Auth.auth().currentUser?.uid ?? "").foregroundColor(.secondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)

                Spacer()

                Button("Save Changes") {
                    Task { await saveUpdatedName() }
                    AccountDetailPresented = false
                }
                .modifier(ProfileActionButton())

                Button("Cancel") { AccountDetailPresented = false }
                    .foregroundColor(.secondary)
>>>>>>> 7cc2357ceb6453a83666b956c41b66354275a2fd
                
                // ACCOUNT DETAILS
                var accountDetailPage: some View {
                    NavigationView {
                        VStack(spacing: 20) {
                            
                            headerCard(title: "Update Account Info",
                                       subtitle: "Modify your personal account information.")
                            
                            List {
                                Section(header: Text("Name")) {
                                    HStack {
                                        Image(systemName: "person").foregroundColor(.red)
                                        TextField("Name", text: $editedName)
                                    }
                                }
                                Section(header: Text("Age")) {
                                    HStack {
                                        Image(systemName: "calendar").foregroundColor(.red)
                                        Text("\(authVM.profile?.age ?? 0) years old")
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                Section(header: Text("Email")) {
                                    HStack {
                                        Image(systemName: "envelope").foregroundColor(.red)
                                        Text(Auth.auth().currentUser?.email ?? "")
                                    }
                                }
                                Section(header: Text("UID")) {
                                    HStack {
                                        Image(systemName: "number").foregroundColor(.red)
                                        Text(Auth.auth().currentUser?.uid ?? "").foregroundColor(.secondary)
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            
                            Spacer()
                            
                            Button("Save Changes") {
                                Task { await saveUpdatedName() }
                                AccountDetailPresented = false
                            }
                            .modifier(ProfileActionButton())
                            
                            Button("Cancel") { AccountDetailPresented = false }
                                .foregroundColor(.secondary)
                            
                            
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Account Details")
                    }
                }
                
                
                // BODY STATS PAGE
                var bodyStatsPage: some View {
                    NavigationView {
                        VStack(spacing: 20) {
                            
                            headerCard(title: "Update Your Body Stats",
                                       subtitle: "Keep your height & weight updated.")
                            
                            List {
                                Section(header: Text("Height (\(apperance2 == .mile ? "inches" : "cm"))")) {
                                    HStack {
                                        Image(systemName: "ruler").foregroundColor(.red)
                                        TextField(apperance2 == .mile ? "Inches" : "Centimeters",
                                                  text: $editedHeight)
                                        .keyboardType(.decimalPad)
                                    }
                                }
                                Section(header: Text("Weight (\(apperance == .lbs ? "lbs" : "kg"))")) {
                                    HStack {
                                        Image(systemName: "scalemass").foregroundColor(.red)
                                        TextField(apperance == .lbs ? "Pounds" : "Kilograms",
                                                  text: $editedWeight)
                                        .keyboardType(.decimalPad)
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            
                            Spacer()
                            
                            Button("Save Body Stats") {
                                Task { await saveBodyStats() }
                                StatsDetailsPresented = false
                            }
                            .modifier(ProfileActionButton())
                            
                            Button("Cancel") { StatsDetailsPresented = false }
                                .foregroundColor(.secondary)
                            
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Body Stats")
                    }
                }
                
                
                // CHANGE PASSWORD PAGE
                var changePasswordPage: some View {
                    NavigationView {
                        VStack(spacing: 20) {
                            
                            headerCard(title: "Change Password",
                                       subtitle: "Enter your new password.")
                            
                            List {
                                Section(header: Text("New Password")) {
                                    HStack {
                                        Image(systemName: "lock.fill").foregroundColor(.red)
                                        SecureField("New Password", text: $changePswd)
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            
                            if let error = authVM.errorMessage {
                                Text(error).foregroundColor(.red)
                            }
                            if let info = authVM.infoMessage {
                                Text(info).foregroundColor(.green)
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
                            .modifier(ProfileActionButton())
                            
                            Button("Cancel") {
                                ChangePasscodePresented = false
                            }
                            .foregroundColor(.secondary)
                            
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Change Password")
                    }
                }
                
                
                // FRIENDS PAGE
                var friendsPage: some View {
                    NavigationView {
                        VStack(spacing: 20) {
                            
                            headerCard(title: "Manage yourFriends",
                                       subtitle: "View your friends list.")
                            
                            List {
                                Section(header: Text("Friends")) {
                                    Label("Alani", systemImage: "person.fill")
                                    Label("Andrew", systemImage: "person.fill")
                                    Label("Doug", systemImage: "person.fill")
                                    Label("Mathew", systemImage: "person.fill")
                                    Label("Reni", systemImage: "person.fill")
                                    Label("Tobi", systemImage: "person.fill")
                                    Label("Eliceo", systemImage: "person.fill")
                                }
                            }
                            .scrollContentBackground(.hidden)
                            
                            Spacer()
                            
                            Button("Close") {
                                manageFriendPresented = false
                            }
                            .foregroundColor(.secondary)
                            
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Friends")
                    }
                }
                
                
                // ---------------------------------------------------------
                // MARK: HELPERS
                // ---------------------------------------------------------
                func headerCard(title: String, subtitle: String) -> some View {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title).font(.title3).fontWeight(.bold)
                        Text(subtitle).font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    )
                    .padding(.horizontal)
                }
                
                
                private func preloadStats() {
                    let hCm = authVM.profile?.heightCm ?? 0
                    let wKg = authVM.profile?.weightKg ?? 0
                    
                    editedHeight = apperance2 == .mile
                    ? String(format: "%.1f", hCm / 2.54)
                    : String(format: "%.0f", hCm)
                    
                    editedWeight = apperance == .lbs
                    ? String(format: "%.1f", wKg * 2.20462)
                    : String(format: "%.1f", wKg)
                }
                
                
                // ---------------------------------------------------------
                // MARK: SAVE FUNCTIONS
                // ---------------------------------------------------------
                private func saveUpdatedName() async {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    let db = Firestore.firestore()
                    
                    do {
                        try await db.collection("users").document(uid)
                            .updateData(["name": editedName])
                        authVM.profile?.name = editedName
                    } catch {
                        print("Name update failed:", error.localizedDescription)
                    }
                }
                
                
                private func saveBodyStats() async {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    let db = Firestore.firestore()
                    
                    // Convert height
                    let heightValue = Double(editedHeight) ?? 0
                    let heightCm = apperance2 == .mile
                    ? heightValue * 2.54
                    : heightValue
                    
                    // Convert weight
                    let weightValue = Double(editedWeight) ?? 0
                    let weightKg = apperance == .lbs
                    ? weightValue / 2.20462
                    : weightValue
                    
                    do {
                        try await db.collection("users").document(uid).updateData([
                            "heightCm": heightCm,
                            "weightKg": weightKg
                        ])
                        authVM.profile?.heightCm = heightCm
                        authVM.profile?.weightKg = weightKg
                    } catch {
                        print("Stats update failed:", error.localizedDescription)
                    }
                }
                
                
                // ---------------------------------------------------------
                // MARK: IMAGE UPLOAD + LOAD
                // ---------------------------------------------------------
                private func uploadImage(_ img: UIImage) {
                    isUploading = true
                    Task {
                        do { try await imageService.uploadProfileImage(img) }
                        catch { print("Image upload error:", error) }
                        isUploading = false
                    }
                }
                func calculateAge(from birthday: Date?) -> Int? {
                    guard let birthday = birthday else { return nil }
                    let now = Date()
                    let calendar = Calendar.current
                    let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
                    return ageComponents.year
                }
                private func loadFriends() {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    
                    Firestore.firestore()
                        .collection("users")
                        .document(uid)
                        .collection("friends")
                        .getDocuments { snapshot, error in
                            if let error = error {
                                print("Error loading friends:", error)
                                return
                            }
                            
                            guard let docs = snapshot?.documents else { return }
                            
                            self.friends = docs.compactMap { doc in
                                let data = doc.data()
                                guard let name = data["name"] as? String else { return nil }
                                return Friend(id: doc.documentID, name: name)
                            }
                        }
                }
                
                private func addFriend() {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    let trimmed = newFriendName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    
                    let friend = Friend(id: UUID().uuidString, name: trimmed)
                    
                    Firestore.firestore()
                        .collection("users")
                        .document(uid)
                        .collection("friends")
                        .document(friend.id)
                        .setData(["name": friend.name]) { error in
                            if let error = error {
                                print("Error adding friend:", error)
                                return
                            }
                            // Update local UI list
                            self.friends.append(friend)
                            self.newFriendName = ""
                        }
                }
                
                private func deleteFriend(at offsets: IndexSet) {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    
                    offsets.forEach { index in
                        let friend = friends[index]
                        
                        Firestore.firestore()
                            .collection("users")
                            .document(uid)
                            .collection("friends")
                            .document(friend.id)
                            .delete { error in
                                if let error = error {
                                    print("Error deleting friend:", error)
                                }
                            }
                        
                        friends.remove(at: index)
                    }
                }
<<<<<<< HEAD
                
                
                
                private func loadProfileImage() {
                    guard let uid = Auth.auth().currentUser?.uid else { return }
                    
                    Firestore.firestore().collection("users").document(uid)
                        .getDocument { snapshot, _ in
                            guard let data = snapshot?.data(),
                                  let urlString = data["photoURL"] as? String,
                                  let url = URL(string: urlString)
                            else { return }
                            
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                if let data = data, let img = UIImage(data: data) {
                                    DispatchQueue.main.async { self.image = img }
                                }
                            }.resume()
                        }
=======
                .modifier(ProfileActionButton())

                Button("Cancel") {
                    ChangePasscodePresented = false
                }
                .foregroundColor(.secondary)

            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Change Password")
        }
    }


    // FRIENDS PAGE
    var friendsPage: some View {
        NavigationView {
            VStack(spacing: 20) {

                headerCard(title: "Manage yourFriends",
                           subtitle: "View your friends list.")

                List {
                    Section(header: Text("Friends")) {
                        Label("Alani", systemImage: "person.fill")
                        Label("Andrew", systemImage: "person.fill")
                        Label("Doug", systemImage: "person.fill")
                        Label("Mathew", systemImage: "person.fill")
                        Label("Reni", systemImage: "person.fill")
                        Label("Tobi", systemImage: "person.fill")
                        Label("Eliceo", systemImage: "person.fill")
                    }
                }
                .scrollContentBackground(.hidden)

                Spacer()

                Button("Close") {
                    manageFriendPresented = false
                }
                .foregroundColor(.secondary)

            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Friends")
        }
    }


    func headerCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title3).fontWeight(.bold)
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        )
        .padding(.horizontal)
    }


    private func preloadStats() {
        let hCm = authVM.profile?.heightCm ?? 0
        let wKg = authVM.profile?.weightKg ?? 0

        editedHeight = apperance2 == .mile
            ? String(format: "%.1f", hCm / 2.54)
            : String(format: "%.0f", hCm)

        editedWeight = apperance == .lbs
            ? String(format: "%.1f", wKg * 2.20462)
            : String(format: "%.1f", wKg)
    }


    
    private func saveUpdatedName() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        do {
            try await db.collection("users").document(uid)
                .updateData(["name": editedName])
            authVM.profile?.name = editedName
        } catch {
            print("Name update failed:", error.localizedDescription)
        }
    }


    private func saveBodyStats() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Convert height
        let heightValue = Double(editedHeight) ?? 0
        let heightCm = apperance2 == .mile
            ? heightValue * 2.54
            : heightValue

        // Convert weight
        let weightValue = Double(editedWeight) ?? 0
        let weightKg = apperance == .lbs
            ? weightValue / 2.20462
            : weightValue

        do {
            try await db.collection("users").document(uid).updateData([
                "heightCm": heightCm,
                "weightKg": weightKg
            ])
            authVM.profile?.heightCm = heightCm
            authVM.profile?.weightKg = weightKg
        } catch {
            print("Stats update failed:", error.localizedDescription)
        }
    }


    
    private func uploadImage(_ img: UIImage) {
        isUploading = true
        Task {
            do { try await imageService.uploadProfileImage(img) }
            catch { print("Image upload error:", error) }
            isUploading = false
        }
    }
    func calculateAge(from birthday: Date?) -> Int? {
        guard let birthday = birthday else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        return ageComponents.year
    }
    private func loadFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("friends")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading friends:", error)
                    return
                }

                guard let docs = snapshot?.documents else { return }

                self.friends = docs.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String else { return nil }
                    return Friend(id: doc.documentID, name: name)
>>>>>>> 7cc2357ceb6453a83666b956c41b66354275a2fd
                }
            }
            func saveWeightEntry(newWeight: Double) async throws {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                
                let entry = WeightEntry(
                    id: UUID().uuidString,
                    weight: newWeight,
                    date: Date()
                )
                
                try await Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .collection("weightHistory")
                    .document(entry.id)
                    .setData([
                        "weight": entry.weight,
                        "date": entry.date
                    ])
            }
        
