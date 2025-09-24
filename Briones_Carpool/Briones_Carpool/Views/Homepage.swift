import SwiftUI
import FirebaseAuth
import SwiftData

struct HomeView: View {
    @State private var showingFindRide = false
    @State private var showingCreateRide = false

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var context
    
    @State private var profileImageData: Data? = nil
    // Helper to convert Data to UIImage
    func dataToImage(_ data: Data?) -> Image {
        guard let data = data, let uiImage = UIImage(data: data) else {
            return Image(systemName: "person.crop.circle")
        }
        return Image(uiImage: uiImage)
    }

    var body: some View {
        VStack {
            Spacer().frame(height: 12)

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("GOOD DAY,")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.black)
                        .padding(.top, 20)

                    Text(authVM.userProfile?["fullName"] as? String ?? "User")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 20)
                .padding(.trailing, 20)
                
                if let profileData = profileImageData {
                    dataToImage(profileData)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.top, 16)
                        .padding(.horizontal, 8)
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.top, 16)
                        .padding(.horizontal, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.vertical, 30)

            Spacer().frame(height: 12)

            Image("homepage_image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 240)
                .padding(.horizontal, 8)

            Spacer().frame(height: 24)
            
            Button("Sign Out") {
                do {
                    try authVM.signOut()
                    profileImageData = nil
                } catch {
                    print("Failed to sign out: \(error.localizedDescription)")
                }
            }

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
        .onAppear {
            fetchProfileImage()
        }
    }
    
    private func fetchProfileImage() {
        guard let userId = authVM.userId else { return }
        
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        do {
            if let found = try context.fetch(descriptor).first {
                self.profileImageData = found.profileImageData
            }
        } catch {
            print("Failed to fetch profile image: \(error)")
        }
    }
}

#Preview {
    HomeView()
}
