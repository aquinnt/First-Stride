//
//  RegisterViewController.swift
//  FirstStride
//
//  Created by douglas miranda on 9/28/25.
//

import SwiftUI
// define registerview different from user view
struct RegisterView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false

    var body: some View {
        Form {//prompt user for their information to be registered hence reg
            Section(header: Text("About you")) {
                TextField("Full name", text: $auth.regName)//auth object to regname
                    .textInputAutocapitalization(.words)
                DatePicker(
                    "Birthdate",
                    selection: $auth.regBirthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
               
                .padding()
                
                TextField("Weight (kg)", text: $auth.regWeight)
                    .keyboardType(.decimalPad)

                TextField("Height (cm)", text: $auth.regHeight)
                    .keyboardType(.decimalPad)
            }//.auth registers their infor to firebase for auth

            Section(header: Text("Sign in details")) {
                TextField("Email", text: $auth.regEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    //sign in infor for future sign in
                SecureField("Password", text: $auth.regPassword)
            }

            if let msg = auth.errorMessage {
                Text(msg).foregroundColor(.red).font(.footnote)
            }//error or info message
            if let info = auth.infoMessage {
                Text(info).foregroundStyle(.secondary).font(.footnote)
            }

            Button {
                Task {
                    isWorking = true// while prcoessing registration
                    await auth.signUpWithProfile()// signs up user to firebase
                    isWorking = false// releases process
                    //if sign up succeeded, user will be not nil; dismiss back to splash which routes to AppShell
                    if auth.user != nil { dismiss() }// dismiss registerview and go to dashboard
                }
            } label: {
                HStack {
                    if isWorking { ProgressView().padding(.trailing, 6) }
                    Text("Create Account")
                }
            }
            .buttonStyle(.borderedProminent)// button style
            .disabled(isWorking || auth.regName.isEmpty || auth.regEmail.isEmpty || auth.regPassword.count < 6)
            //diables button when name email and pass are empty
            // forces user to fill out fields
        }
        .navigationTitle("Create Account")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }// this button dismisses regview to dashboard
            }
        }
    }
}
