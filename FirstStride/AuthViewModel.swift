//
//  Authentication.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
// ccontinuied by doug
import Foundation
import FirebaseAuth
import FirebaseFirestore


@MainActor
final class AuthViewModel: ObservableObject {// handles auth logic
//firebase authorization
    @Published var user: User? = nil//firebase auth user
    @Published var profile: UserProfile? = nil//our firestore profile

//login fields
    @Published var email: String = "" //email for login
    @Published var password: String = ""//password for login

 //reg fields
    @Published var regName: String = "" //display name
    @Published var regBirthDate: Date = Date()//changeds this to date() for date birthdate 
    @Published var regWeight: String = ""//weight kg as string
    @Published var regHeight: String = ""//height cm
    @Published var regEmail: String = ""// email for sign up
    @Published var regPassword: String = "" //password for sign-up

   // error and info message
    @Published var errorMessage: String? = nil//for showing errors
    @Published var infoMessage: String? = nil //for info notices

    private var handle: AuthStateDidChangeListenerHandle?
    private let store = FirestoreService()

    init() {
        // this checks if user or phoen is registered and opens to dashboard if user is recognized
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                if let uid = user?.uid {
                    // fetch the profile if we have a user
                    self?.profile = try? await self?.store.getUserProfile(uid: uid)
                } else {
                    self?.profile = nil//if no profile, then profile is nill
                }
            }
        }
    }
// deinitialize listener when the view model is deallocated
    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }


    //creates a firebase auth account and writes the userProfile to firestore.
    func signUpWithProfile() async {
        errorMessage = nil
        infoMessage = nil

        do {
            //create auth user
            let result = try await Auth.auth().createUser(withEmail: regEmail, password: regPassword)
            let uid = result.user.uid

            //parse numeric fields safely
            // allowed for calendar view for age picking
            let calendar = Calendar.current
            let now = Date()
            let ageComponents = calendar.dateComponents([.year], from: regBirthDate, to: now)
            let ageVal = ageComponents.year ?? 0
            let weightVal = Double(regWeight.trimmingCharacters(in: .whitespaces))
            let heightVal = Double(regHeight.trimmingCharacters(in: .whitespaces))

            //build profile model with intput
           
            let p = UserProfile(
                uid: uid, //created by firebase
                name: regName.trimmingCharacters(in: .whitespacesAndNewlines),
                age: ageVal,
                weightKg: weightVal,//will figure out how to convert to freedom units in next sprint
                heightCm: heightVal,
                email: result.user.email,//firebase allocated user
                createdAt: now,
                updatedAt: now
            )

            //store to firestore
            try await store.setUserProfile(p)

            // keep local state in sync
            profile = p

            // set displayName on the auth user
            let change = result.user.createProfileChangeRequest()
            change.displayName = p.name
            try await change.commitChanges()
            //notify the user
            infoMessage = "Account created!"
        } catch {//else, show error message with description
            errorMessage = error.localizedDescription
        }
    }

    //signs in with email/password.
    func signIn() async {
        errorMessage = nil//these clear previopus messages
        infoMessage = nil
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)//verifies against firebase
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    //anonymous sign-in for guests
    func signInAnonymously() async {
        //creates anonymous user
        errorMessage = nil
        infoMessage = nil
        do {
            _ = try await Auth.auth().signInAnonymously()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    //send password to email for reset
    func sendPasswordReset(email: String) async {
        errorMessage = nil
        infoMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)//allows firebase to send email to user for password reset
            infoMessage = "Password reset email sent."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    //sign out and clear user fields
    func signOut() {
        try? Auth.auth().signOut()//signs out firebase user
        user = nil
        profile = nil
        email = ""
        password = ""
        regName = ""
        regBirthDate = Date()
        regWeight = ""
        regHeight = ""
        regEmail = ""
        regPassword = ""
    
    }
}
