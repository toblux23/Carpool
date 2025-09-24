import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SwiftData
import UIKit

// SwiftData model for local storage
@Model
class UserProfile {
    @Attribute var id: UUID
    @Attribute var userId: String
    @Attribute var fullName: String
    @Attribute var phoneNumber: String
    @Attribute var isDriver: Bool
    @Attribute var isRider: Bool
    @Attribute var driverLicense: String
    @Attribute var profileImageData: Data?
    @Attribute var licenseImageData: Data?

    init(id: UUID = UUID(), userId: String, fullName: String, phoneNumber: String, isDriver: Bool, isRider: Bool, driverLicense: String, profileImageData: Data?, licenseImageData: Data?) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.isDriver = isDriver
        self.isRider = isRider
        self.driverLicense = driverLicense
        self.profileImageData = profileImageData
        self.licenseImageData = licenseImageData
    }
}

struct AlertMessage: Identifiable {
    var id: String { message }
    let message: String
}

struct MultiStepProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var step = 1
    var onFinish: () -> Void

    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var isDriver: Bool = false
    @State private var isRider: Bool = true
    @State private var driverLicense: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var driverLicenseImage: UIImage? = nil

    @State private var isLoading = false
    @State private var errorMessage: AlertMessage?

    let darkRed = Color(red: 128 / 255, green: 0, blue: 0)

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 1:
                    PersonalInfoView(fullName: $fullName, phoneNumber: $phoneNumber) {
                        step = 2
                    }
                case 2:
                    UserTypeView(
                        isDriver: $isDriver,
                        isRider: $isRider,
                        driverLicense: $driverLicense,
                        driverLicenseImage: $driverLicenseImage,
                        onNext: { step = 3 },
                        onBack: { step = 1 }
                    )
                case 3:
                    ProfilePictureView(
                        profileImage: $profileImage,
                        driverLicenseImage: $driverLicenseImage,
                        fullName: $fullName,
                        phoneNumber: $phoneNumber,
                        isDriver: $isDriver,
                        driverLicense: $driverLicense,
                        onBack: { step = 2 },
                        onFinish: saveProfile
                    )
                default:
                    Text("Unknown step")
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView("Saving...")
                        .progressViewStyle(CircularProgressViewStyle(tint: darkRed))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                }
            }
            .alert(item: $errorMessage) { alertMsg in
                Alert(title: Text("Error"), message: Text(alertMsg.message), dismissButton: .default(Text("OK")))
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    func saveProfile() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                guard let user = Auth.auth().currentUser else {
                    throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }
                let userId = user.uid

                let profileImageData = profileImage?.jpegData(compressionQuality: 0.7)
                let licenseImageData = driverLicenseImage?.jpegData(compressionQuality: 0.7)

                let profileData: [String: Any] = [
                    "userId": userId,
                    "fullName": fullName,
                    "phoneNumber": phoneNumber,
                    "isDriver": isDriver,
                    "isRider": isRider,
                    "driverLicense": isDriver ? driverLicense : "",
                    "updatedAt": Timestamp(date: Date()),
                    "Status": "Pending"
                ]

                // Save to Firestore
                let db = Firestore.firestore()
                try await db.collection("profiles").document(userId).setData(profileData, merge: true)

                // Save images locally in SwiftData
                let localProfile = UserProfile(
                    userId: userId,
                    fullName: fullName,
                    phoneNumber: phoneNumber,
                    isDriver: isDriver,
                    isRider: isRider,
                    driverLicense: isDriver ? driverLicense : "",
                    profileImageData: profileImageData,
                    licenseImageData: licenseImageData
                )

                modelContext.insert(localProfile)
                try modelContext.save()

                print("Profile saved remotely and images stored locally.")
                isLoading = false
                onFinish()
            } catch {
                isLoading = false
                errorMessage = AlertMessage(message: error.localizedDescription)
                print("Error saving profile:", error)
            }
        }
    }
}



// Supporting views

struct PersonalInfoView: View {
    @Binding var fullName: String
    @Binding var phoneNumber: String
    var onNext: () -> Void

    let darkRed = Color(red: 128/255, green: 0, blue: 0)
    @FocusState private var focusedField: Field?

    enum Field {
        case fullNameField
        case phoneField
    }

    var body: some View {
        Form {
            Section(header: Text("Full Name").foregroundColor(darkRed)) {
                TextField("Your full name", text: $fullName)
                    .focused($focusedField, equals: .fullNameField)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .phoneField
                    }
            }
            Section(header: Text("Phone Number").foregroundColor(darkRed)) {
                TextField("Your phone number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .focused($focusedField, equals: .phoneField)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }
            }
            Button(action: {
                focusedField = nil
                onNext()
            }) {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(darkRed)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(fullName.isEmpty || phoneNumber.isEmpty)
        }
    }
}

struct UserTypeView: View {
    @Binding var isDriver: Bool
    @Binding var isRider: Bool
    @Binding var driverLicense: String
    @Binding var driverLicenseImage: UIImage?
    var onNext: () -> Void
    var onBack: () -> Void

    let darkRed = Color(red: 128/255, green: 0, blue: 0)
    @State private var showingLicenseImagePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Select your role(s)")
                    .font(.title2)
                    .bold()
                    .foregroundColor(darkRed)
                    .padding(.top)

                HStack {
                    Text("Rider")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $isRider)
                        .toggleStyle(SwitchToggleStyle(tint: darkRed))
                }

                HStack {
                    Text("Driver")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $isDriver)
                        .toggleStyle(SwitchToggleStyle(tint: darkRed))
                }

                if isDriver {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Driver License Number")
                            .font(.headline)
                            .foregroundColor(darkRed)
                        TextField("Enter license number", text: $driverLicense)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)

                        Text("Driver's License Picture")
                            .font(.headline)
                            .foregroundColor(darkRed)

                        Button(action: {
                            showingLicenseImagePicker = true
                        }) {
                            if let licenseImage = driverLicenseImage {
                                Image(uiImage: licenseImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 140)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(darkRed, lineWidth: 3))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 200, height: 140)
                                    .overlay(Text("Tap to add").foregroundColor(.gray))
                            }
                        }
                        .sheet(isPresented: $showingLicenseImagePicker) {
                            ImagePicker(image: $driverLicenseImage)
                        }
                    }
                    .padding(.vertical)
                }

                HStack {
                    Button("Back") {
                        onBack()
                    }
                    .foregroundColor(darkRed)
                    Spacer()
                    Button("Next") {
                        onNext()
                    }
                    .disabled(!isRider && !isDriver || (isDriver && (driverLicense.isEmpty || driverLicenseImage == nil)))
                    .padding()
                    .background((isRider || isDriver) ? darkRed : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

struct ProfilePictureView: View {
    @Binding var profileImage: UIImage?
    @Binding var driverLicenseImage: UIImage?
    @Binding var fullName: String
    @Binding var phoneNumber: String
    @Binding var isDriver: Bool
    @Binding var driverLicense: String
    var onBack: () -> Void
    var onFinish: () -> Void

    let darkRed = Color(red: 128/255, green: 0, blue: 0)

    @State private var showingProfileImagePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Add pictures")
                    .font(.title2)
                    .bold()
                    .foregroundColor(darkRed)

                VStack(spacing: 20) {
                    Text("Profile Picture")
                        .font(.headline)
                        .foregroundColor(darkRed)

                    Button(action: {
                        showingProfileImagePicker = true
                    }) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(darkRed, lineWidth: 3))
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 140, height: 140)
                                .overlay(Text("Tap to add").foregroundColor(.gray))
                        }
                    }
                    .sheet(isPresented: $showingProfileImagePicker) {
                        ImagePicker(image: $profileImage)
                    }
                }

                HStack {
                    Button("Back") {
                        onBack()
                    }
                    .foregroundColor(darkRed)
                    .padding()

                    Spacer()

                    Button("Finish") {
                        onFinish()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(darkRed)
                    .cornerRadius(12)
                    .disabled(
                        fullName.isEmpty
                            || phoneNumber.isEmpty
                            || (isDriver && (driverLicense.isEmpty || driverLicenseImage == nil))
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

#Preview {
    MultiStepProfileSetupView(onFinish: {
        print("Profile setup finished")
    })
}
