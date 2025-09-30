//
//  ForgotPasswordVC.swift
//  FirstStride
//
//  Created by douglas miranda on 9/28/25.
//

import SwiftUI
// define the forgotpassword view
struct ForgotPasswordView: View {
    //gives us access to authviewmodel
    @EnvironmentObject var auth: AuthViewModel
    // close screen or dismiss when done
    @Environment(\.dismiss) private var dismiss
    // inputted email
    @State private var resetEmail: String = ""
    // flag when not running
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Email", text: $resetEmail)// prompt user for email
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                if let msg = auth.errorMessage {
                    Text(msg).foregroundColor(.red).font(.footnote)
                }//error or info message if email is correct or in file
                if let info = auth.infoMessage {
                    Text(info).foregroundStyle(.secondary).font(.footnote)
                }
                
                // button to send link for password reset
                Button {
                    Task {
                        isWorking = true
                        await auth.sendPasswordReset(email: resetEmail)//wait, send email, confirm
                        isWorking = false
                    }
                } label: {
                    HStack {
                        if isWorking { ProgressView().padding(.trailing, 6) }
                        Text("Send reset link")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking || resetEmail.isEmpty)
            }
            .navigationTitle("Forgot Password")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {//dismisses this page back to authview
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
