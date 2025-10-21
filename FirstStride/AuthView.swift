//
//  AuthView.swift
//  FirstStride
//
//  Created by alani quintanilla on 9/25/25.
// continued by doug
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showForgot = false//controls the forgot password page
    @State private var isWorking = false     //shows ProgressView during work
    @State private var goToRegister = false//controls navigation to RegisterView
    //initialize main login page with links to createuser, forgotpassword, and guest continue
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    // Use UIKit color for iOS background
                    //use this to change brightness or red
                    Color(red: 1.0, green:0.3, blue: 0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        
                        Image("whitelogo")//load app logo
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200) // make a bit larger if you like
                        
                        Text("First-Stride")
                            .font(.custom("Palatino", size: 30)).bold()
                            .foregroundColor(.white)
                        //change font and size //with this
                        //app name and quick message with formats
                        Text("Reach your full potential")
                            .font(.custom("Palatino", size: 20))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        //email field
                        TextField("Email", text: $auth.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.roundedBorder)
                            .font(.custom("Palatino", size: 15))
                        
                        //password field
                        SecureField("Password", text: $auth.password)
                            .textFieldStyle(.roundedBorder)
                            .font(.custom("Palatino", size: 15))
                            //font
                        
                        //forgot password link
                        Button("Forgot password?") {
                            showForgot = true
                        }
                        .foregroundColor(.white)
                        .font(.custom("Palatino", size: 15))//font
                        .padding(.top, -6)
                        
                        
                        //error/info messages
                        if let msg = auth.errorMessage {
                            Text(msg).foregroundColor(.red).font(.footnote)
                        }
                        if let info = auth.infoMessage {
                            Text(info).foregroundStyle(.secondary).font(.footnote)
                        }
                        
                        // sign In
                        Button {
                            Task {
                                isWorking = true
                                await auth.signIn()
                                isWorking = false
                                if auth.user != nil { dismiss() } //splash will route to dashboard
                            }
                        } label: {
                            HStack {
                                if isWorking { ProgressView().padding(.trailing, 6) }
                                Text("Sign In")
                                    .foregroundColor(.white)
                                    .font(.custom("Palatino", size: 15))//font
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isWorking || auth.email.isEmpty || auth.password.isEmpty)// this disables button if any of these is //true. password or email are empty
                        
                        // create accountnavigate to dedicated screen
                        NavigationLink(isActive: $goToRegister) {
                            RegisterView().environmentObject(auth)
                        } label: {
                            EmptyView()
                        }
                        Button("Create Account") {
                            // clears previous user for new user to sign up
                            auth.regName = ""
                            auth.regBirthDate = Date()// changed this to allow for register of date birthdate
                            auth.regWeight = ""
                            auth.regHeight = ""
                            auth.regEmail = ""
                            auth.regPassword = ""
                            //keeps fields empty
                            goToRegister = true
                        }.font(.custom("Palatino", size: 15))
                            .foregroundColor(.white)//font
                        
                        // Continue as Guest (anonymous)
                        Button("Continue as Guest") {
                            Task {
                                isWorking = true
                                await auth.signInAnonymously()
                                isWorking = false
                                if auth.user != nil { dismiss() }//authorized user is no longer nill
                                //this dismisses authview and routes to dashboard
                            }
                        }
                        .font(.custom("Palatino", size: 15))//font
                        .padding(.top, 4)
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .sheet(isPresented: $showForgot) {
                        ForgotPasswordView()//takes you to forgot password
                            .environmentObject(auth)//keeps auth object or email in its field
                    }
                }
            }
        }
    }
}
