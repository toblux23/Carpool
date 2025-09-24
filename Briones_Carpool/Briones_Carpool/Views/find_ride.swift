import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Ride: Identifiable {
    var id: String
    let fromLocation: String
    let toLocation: String
    let departureTime: String
    let arrivalTime: String
    let travelFee: Int
    let seatsAvailable: Int
    let timeToTravel: String

    init?(document: [String: Any], id: String) {
        guard
            let fromLocation = document["departureFrom"] as? String,
            let toLocation = document["departureTo"] as? String,
            let timestamp = document["departureDateTime"] as? Timestamp,
            let travelFee = document["price"] as? Int,
            let seatsAvailable = document["seatsAvailable"] as? Int
        else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short

        self.id = id
        self.fromLocation = fromLocation
        self.toLocation = toLocation
        self.departureTime = dateFormatter.string(from: timestamp.dateValue())
        self.arrivalTime = "" // Add if available
        self.travelFee = travelFee
        self.seatsAvailable = seatsAvailable
        self.timeToTravel = "" // Calculate or add if available
    }
}

struct FindRideView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var rides: [Ride] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                            .imageScale(.large)
                    }
                    Spacer()
                    Text("Find Ride")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)

                TextField("Where are you off to ?", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .padding()
                } else if rides.isEmpty {
                    Text("No rides found.")
                        .padding()
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            Text("Nearby Rides")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .padding(.leading, 16)

                            ForEach(rides.filter { searchText.isEmpty ? true : $0.toLocation.localizedCaseInsensitiveContains(searchText) }) { ride in
                                RideCardView(ride: ride) {
                                    createRideRequest(for: ride)
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGray6))
            .navigationBarBackButtonHidden(true)
            .onAppear(perform: loadRides)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Ride Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func loadRides() {
        let db = Firestore.firestore()
        db.collection("rides").getDocuments { snapshot, error in
            isLoading = false
            if let error = error {
                alertMessage = "Failed to load rides: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            rides = snapshot?.documents.compactMap {
                Ride(document: $0.data(), id: $0.documentID)
            } ?? []
        }
    }
    
    func createRideRequest(for ride: Ride) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "You must be signed in to request a ride."
            showingAlert = true
            return
        }
        let db = Firestore.firestore()
        let requestData: [String: Any] = [
            "userId": user.uid,
            "rideId": ride.id,
            "requestedAt": Timestamp(date: Date()),
            "status": "pending"
        ]
        db.collection("ride_request").addDocument(data: requestData) { error in
            if let error = error {
                alertMessage = "Failed to send ride request: \(error.localizedDescription)"
            } else {
                alertMessage = "Successfully requested this ride!"
            }
            showingAlert = true
        }
    }
}

struct RideCardView: View {
    let ride: Ride
    let onRequest: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Image(systemName: "car.fill") // Default icon for rides
                    .resizable()
                    .frame(width: 54, height: 54)
                    .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 2))
                VStack(alignment: .leading) {
                    Text("Ride")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("\(ride.fromLocation) ➔ \(ride.toLocation)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: onRequest) {
                    Text("Request")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 8)

            HStack {
                Text("₱\(ride.travelFee)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                Text("\(ride.seatsAvailable) seat(s)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                Text(ride.departureTime)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 30)
            .padding(.horizontal, 8)
            .foregroundColor(.black)

            HStack {
                Text("Price")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                Text("Seats Available")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                Text("Departure Time")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 18)
            .padding(.horizontal, 8)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.33), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    FindRideView()
}
