import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var user: User? = nil                   // Firebase auth user
    @Published var profile: UserProfile? = nil         // Firestore profile

    // Login fields
    @Published var email: String = ""
    @Published var password: String = ""

    // Registration fields
    @Published var regName: String = ""
    @Published var regBirthDate: Date = Date()
    @Published var regWeight: String = ""
    @Published var regHeight: String = ""
    @Published var regEmail: String = ""
    @Published var regPassword: String = ""

    // Error/info messages
    @Published var errorMessage: String? = nil
    @Published var infoMessage: String? = nil

    // Firebase listener
    private var handle: AuthStateDidChangeListenerHandle?
    private let store = FirestoreService()

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                if let uid = user?.uid {
                    self?.profile = try? await self?.store.getUserProfile(uid: uid)
                } else {
                    self?.profile = nil
                }
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signUpWithProfile() async {
        errorMessage = nil
        infoMessage = nil

        do {
            // Create auth user
            let result = try await Auth.auth().createUser(
                withEmail: regEmail,
                password: regPassword
            )
            let uid = result.user.uid

            // Calculate age
            let calendar = Calendar.current
            let now = Date()
            let ageComponents = calendar.dateComponents([.year], from: regBirthDate, to: now)
            let ageVal = ageComponents.year ?? 0

            // Parse weight/height as Double
            let weightVal = Double(regWeight.trimmingCharacters(in: .whitespaces)) ?? 0
            let heightVal = Double(regHeight.trimmingCharacters(in: .whitespaces)) ?? 0

            // Build user profile
            let p = UserProfile(
                uid: uid,
                name: regName.trimmingCharacters(in: .whitespacesAndNewlines),
                age: ageVal,
                weightKg: weightVal,
                heightCm: heightVal,
                email: result.user.email,
                createdAt: now,
                updatedAt: now
            )

            // Save profile
            try await store.setUserProfile(p)
            profile = p

            // Set Firebase Auth display name
            let change = result.user.createProfileChangeRequest()
            change.displayName = p.name
            try await change.commitChanges()

            infoMessage = "Account created!"

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn() async {
        errorMessage = nil
        infoMessage = nil
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInAnonymously() async {
        errorMessage = nil
        infoMessage = nil
        do {
            _ = try await Auth.auth().signInAnonymously()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset(email: String) async {
        errorMessage = nil
        infoMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            infoMessage = "Password reset email sent."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changePassword(to newPassword: String) async {
        errorMessage = nil
        infoMessage = nil

        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user is currently signed in."
            return
        }

        do {
            try await user.updatePassword(to: newPassword)
            infoMessage = "Password updated successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
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
