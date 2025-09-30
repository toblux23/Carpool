import SwiftUI
import FirebaseAuth
import SwiftData
import FirebaseFirestore
struct HomeView: View {
    @State private var showingFindRide = false
    @State private var showingCreateRide = false
    @State private var navigateToProfile = false

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var context
    private var localUserId: String? {
        authVM.userId
    }
    @Query var profiles: [UserProfile]

    var currentProfile: UserProfile? {
        profiles.first { $0.userId == authVM.userId }
    }
    
    var body: some View {
        NavigationStack
        {
            VStack {
                Spacer().frame(height: 12)

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("GOOD DAY,")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.black)
                        Text(authVM.userProfile?["fullName"] as? String ?? "User")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 20)
                    .padding(.vertical, 18)
                    Spacer()

                    Button(action: {
                        print("Profile Image tapped")
                        navigateToProfile = true
                    }) {
                        if let imageData = currentProfile?.profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 2)
                                .padding(.trailing, 20)
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 2)
                                .padding(.trailing, 20)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 20)
                .padding(.vertical, 30)

                Spacer().frame(height: 12)

                Image("homepage_image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 240)
                    .padding(.horizontal, 8)

                Spacer().frame(height: 24)


                Button(action: {
                    showingFindRide = true
                }) {
                    Text("Find a Ride")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(22)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .sheet(isPresented: $showingFindRide) {
                    FindRideView()
                }

                Button(action: {
                    showingCreateRide = true
                }) {
                    Text("Start your Ride")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color(red: 128/255, green: 0, blue: 0), lineWidth: 2)
                        )
                }
                .padding(.horizontal, 28)
                .sheet(isPresented: $showingCreateRide) {
                    CreateRideView()
                }

                Spacer()
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden(true)

            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView()
                    .environmentObject(authVM)
            }
        }
    }
}


// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var profileImageData: Data? = nil
    @State private var fullName: String = "Driver Name"
    @State private var status: String = "pending"
    @State private var createdAt: Date = Date()

    private let totalOfRides = 20
    private let rating = 5.0
    private let bio = "Professional and friendly driver focused on safety, punctuality, and customer satisfaction."
    private let reviews: [(String, String, Double, String)] = [
        ("John Dave Briones", "Passenger", 5.0, "The service was good and the driver arrived on time, Overall it was a good experience."),
        ("John Dave Briones", "Passenger", 5.0, "The service was good and the driver arrived on time, Overall it was a good experience.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Profile Image
                if let data = profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 6)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 110, height: 110)
                        .foregroundColor(.gray)
                }

                // Name & Status
                Text(fullName)
                    .font(.title)
                    .fontWeight(.bold)

                if status == "pending" {
                    Label("Verify Now", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                } else {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }

                // Stats
                HStack {
                    VStack {
                        Text("\(totalOfRides)")
                            .font(.headline)
                        Text("Total Rides")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack {
                        Text(String(format: "%.1f", rating))
                            .font(.headline)
                        Text("Rating")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack {
                        Text(DateFormatter.localizedString(from: createdAt, dateStyle: .medium, timeStyle: .none))
                            .font(.headline)
                        Text("Since")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.systemGray4), lineWidth: 1))

                // Bio
                VStack(alignment: .leading) {
                    Text("Bio")
                        .font(.headline)
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Reviews
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Reviews")
                        .font(.headline)
                    ForEach(reviews, id: \.0) { rev in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 34, height: 34)
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading) {
                                    Text(rev.0).fontWeight(.bold)
                                    Text(rev.1).font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                HStack(spacing: 2) {
                                    Text(String(format: "%.1f", rev.2))
                                    Image(systemName: "star.fill").foregroundColor(.yellow)
                                }
                            }
                            Text("\"\(rev.3)\"")
                                .font(.body)
                                .foregroundColor(.gray)
                                .padding(.leading, 38)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1))
                    }
                }

                // Sign Out
                Button(action: {
                    do {
                        try authVM.signOut()
                    } catch {
                        print("Sign-out failed: \(error.localizedDescription)")
                    }
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
        }
        .background(Color.white)
        .onAppear(perform: fetchProfileData)
    }

    func fetchProfileData() {
        guard let userId = authVM.userId else { return }
        let db = Firestore.firestore()
        db.collection("profiles").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                fullName = data?["fullName"] as? String ?? "Driver Name"
                status = data?["status"] as? String ?? "pending"
                if let timestamp = data?["createdAt"] as? Timestamp {
                    createdAt = timestamp.dateValue()
                }
            } else if let error = error {
                print("Error fetching profile: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthViewModel())
    }

}
