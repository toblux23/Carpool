import SwiftUI
import FirebaseAuth
import FirebaseFirestore


enum AuthScreen { case signup, signin }

struct AuthContainerView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    @State private var screen: AuthScreen = .signin
    @State private var isSigningUp = false

    var body: some View {
        
        if authVM.isAuthenticated {
            MainContainerView()
        } else if isSigningUp {
            MultiStepProfileSetupView(onFinish: {
                authVM.isAuthenticated = true
                isSigningUp = false
            })
        } else {
            VStack {
                if screen == .signin {
                    SigninView(
                        onSwitch: { self.screen = .signup },
                        onSignedIn: {
                            authVM.isAuthenticated = true
                        })
                } else {
                    SignupView(
                        onSwitch: { self.screen = .signin },
                        onSignedUp: {
                            isSigningUp = true
                            print("profile setup")
                            print("$authVM.isAuthenticated: \(authVM.isAuthenticated)")
                        })
                }
            }
        }
    }
}


struct SigninView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var onSwitch: () -> Void
    var onSignedIn: () -> Void
    @State private var isAuthenticated = false
    @State private var email = ""
    @State private var password = ""
    @State private var signInError = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .resizable()
                        .frame(width: 44, height: 32)
                        .foregroundColor(.blue)
                    HStack(spacing: 0) {
                        Text("EU")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text("RIDE")
                            .font(.headline)
                            .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 32)
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.clear, lineWidth: 1))
                    .font(.body)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.clear, lineWidth: 1))
                    .font(.body)
                
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)

            Button(action: {
                authVM.signIn(email: email, password: password){
                    result in switch result {
                    case .success:
                        onSignedIn()
                        print("SUccessful Signin")
                    
                    case .failure(let error):
                        print("Error signing in: \(error)")
                    }
                }
                
            }) {
                    Text("Sign in")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(24)
                
            }
    
                
            .padding(.horizontal, 32)
            
            Text("- Or sign in with -")
                .foregroundColor(.gray)
                .font(.body)
                .padding(.top, 16)
            
            HStack(spacing: 80) {
                Image("gogol").resizable().frame(width: 36, height: 36)
                Image("microsoft").resizable().frame(width: 36, height: 36)
                Image("yahoo").resizable().frame(width: 36, height: 36)
            }
            .padding(.top, 8)
            HStack(spacing: 2) {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                Button(action: { onSwitch() }){
                    Text("Sign up")
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                }
            }
            .font(.body)
            .padding(.top, 16)
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct SignupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    var onSwitch: () -> Void
    var onSignedUp: () -> Void
    @State private var isAuthenticated = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .resizable()
                        .frame(width: 44, height: 32)
                        .foregroundColor(.blue)
                    HStack(spacing: 0) {
                        Text("EU")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text("RIDE")
                            .font(.headline)
                            .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 32)
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.clear, lineWidth: 1))
                    .font(.body)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.clear, lineWidth: 1))
                    .font(.body)
                SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.clear, lineWidth: 1))
                .font(.body)
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)

            Button(action: {
                guard password == confirmPassword else {
                    print("Password mismatch!")
                    return
                }
                authVM.signUp(email: email, password: password) { result in
                    switch result {
                    case .success():
                        onSignedUp()
                        print("Success")
                    case .failure(let error):
                        (print("Error: \(error)"))
                    }
                }
            })
            {
                Text("Sign up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(red: 128/255, green: 0, blue: 0))
                    .cornerRadius(24)
            }
            .padding(.horizontal, 32)
            
            Text("- Or sign in with -")
                .foregroundColor(.gray)
                .font(.body)
                .padding(.top, 16)

            HStack(spacing: 80) {
                Image("gogol").resizable().frame(width: 36, height: 36)
                Image("microsoft").resizable().frame(width: 36, height: 36)
                Image("yahoo").resizable().frame(width: 36, height: 36)
            }
            .padding(.top, 8)

            //Signin
            HStack(spacing: 2) {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                Button(action: { onSwitch() }) {
                        Text("Sign in")
                            .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                    
                }
            }
            .font(.body)
            .padding(.top, 16)

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}
#Preview {
    AuthContainerView()
        .environmentObject(AuthViewModel())
}

