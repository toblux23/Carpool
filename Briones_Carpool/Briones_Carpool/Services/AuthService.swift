import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var userId: String? = nil
    @Published var isAuthenticated: Bool = false
    @Published var isProfileCompleted: Bool = false
    @Published var userProfile: [String: Any]? = nil

    private var profileListener: ListenerRegistration?

    init() {
        self.userId = Auth.auth().currentUser?.uid
        self.isAuthenticated = self.userId != nil

        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userId = user?.uid
            self?.isAuthenticated = user != nil
            
            if let uid = user?.uid {
                self?.startListeningUserProfile(userId: uid)
            } else {
                self?.userProfile = nil
                self?.isProfileCompleted = false
                self?.profileListener?.remove()
                self?.profileListener = nil
            }
        }
    }

    func startListeningUserProfile(userId: String) {
        profileListener?.remove()
        let db = Firestore.firestore()
        profileListener = db.collection("profiles").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                self?.userProfile = nil
                self?.isProfileCompleted = false
                return
            }
            self?.userProfile = data
            // Check profile completion criteria, example:
            self?.isProfileCompleted = (data["fullName"] as? String)?.isEmpty == false
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let userId = authResult?.user.uid else {
                completion(.failure(NSError(domain: "App", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing user ID"])))
                return
            }

            let profileData: [String: Any] = [
                "email": email,
                "createdAt": Timestamp(date: Date())
            ]

            let db = Firestore.firestore()
            db.collection("profiles").document(userId).setData(profileData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.userId = userId
                    self.isAuthenticated = true
                    self.isProfileCompleted = false
                    completion(.success(()))
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.userId = authResult?.user.uid
            self.isAuthenticated = true
            self.isProfileCompleted = true
            completion(.success(()))
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        self.userId = nil
        self.isAuthenticated = false
        self.isProfileCompleted = false
        profileListener?.remove()
        profileListener = nil
    }
}
