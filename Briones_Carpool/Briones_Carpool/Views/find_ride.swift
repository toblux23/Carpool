import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SwiftData



struct FindRideView: View {
    @State private var userRideRequests: [String: (requestId: String, riderId: String)] = [:]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var authVM: AuthViewModel
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
                    ProgressView().padding()
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
                                let rideRequestInfo = userRideRequests[ride.id]
                                let requested = rideRequestInfo != nil
                                let riderId = rideRequestInfo?.riderId
                                let isOwnerRequest = riderId == Auth.auth().currentUser?.uid
                                let isCreator = ride.driverId == Auth.auth().currentUser?.uid

                                // Creator sees Delete button
                                if isCreator {
                                    RideCardView(ride: ride, requested: false, onRequest: {}, onCancel: {
                                        deleteRide(rideId: ride.id)
                                    }, deleteMode: true)
                                    .padding(.horizontal, 8)
                                } else {
                                    // Normal user sees Request or Cancel based on request status
                                    RideCardView(ride: ride, requested: requested, onRequest: {
                                        createRideRequest(for: ride)
                                    }, onCancel: {
                                        if isOwnerRequest, let requestId = rideRequestInfo?.requestId {
                                            cancelRideRequest(requestId: requestId)
                                        } else {
                                            alertMessage = "You can only cancel your own ride requests."
                                            showingAlert = true
                                        }
                                    }, deleteMode: false)
                                    .padding(.horizontal, 8)
                                }
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

    func loadUserPendingRequests(for userId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("rided_requests")
            .whereField("status", in: ["pending", "accepted"])
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    userRideRequests = Dictionary(uniqueKeysWithValues: docs.compactMap { doc in
                        guard let rideId = doc.data()["rideId"] as? String,
                              let riderId = doc.data()["rider_id"] as? String else { return nil }
                        return (rideId, (doc.documentID, riderId))
                    })
                }
                completion()
            }
    }

    func loadRides() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        loadUserPendingRequests(for: userId) {
            let db = Firestore.firestore()
            db.collection("rides").getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    alertMessage = "Failed to load rides: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                var fetchedRides: [Ride] = []
                let now = Date()
                for doc in snapshot?.documents ?? [] {
                    if var ride = Ride(document: doc.data(), id: doc.documentID) {

                        // filter out past rides
                        if let timestamp = doc.data()["departureDateTime"] as? Timestamp {
                            if timestamp.dateValue() < now {
                                continue
                            }
                        }

                        let driverId = ride.driverId
                        let request = FetchDescriptor<UserProfile>(
                            predicate: #Predicate { profile in
                                profile.userId == driverId
                            })
                        if let profile = try? context.fetch(request).first {
                            ride.driverImageData = profile.profileImageData
                        }
                        db.collection("profiles").document(driverId).getDocument { userDoc, _ in
                            if let userData = userDoc?.data() {
                                ride.driverName = userData["fullName"] as? String ?? "Unknown Driver"
                            } else {
                                ride.driverName = "Unknown Driver"
                            }
                            DispatchQueue.main.async {
                                fetchedRides.append(ride)
                                self.rides = fetchedRides
                            }
                        }
                    }
                }
            }
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
            "rider_id": user.uid,
            "rideId": ride.id,
            "driver_id": ride.driverId,
            "requestedAt": Timestamp(date: Date()),
            "status": "pending"
        ]
        db.collection("rided_requests").addDocument(data: requestData) { error in
            if let error = error {
                alertMessage = "Failed to send ride request: \(error.localizedDescription)"
            } else {
                alertMessage = "Successfully requested this ride!"
                createDriverNotification(driverId: ride.driverId, riderId: user.uid, rideId: ride.id)
            }
            showingAlert = true
        }
    }


    func cancelRideRequest(requestId: String) {
        let db = Firestore.firestore()
        db.collection("rided_requests").document(requestId).delete { error in
            if let error = error {
                alertMessage = "Failed to cancel request: \(error.localizedDescription)"
            } else {
                alertMessage = "Successfully cancelled your ride request."
                // reload after cancel
                if let userId = Auth.auth().currentUser?.uid {
                    loadUserPendingRequests(for: userId) {
                        loadRides()
                    }
                }
            }
            showingAlert = true
        }
    }

    func deleteRide(rideId: String) {
        let db = Firestore.firestore()
        db.collection("rides").document(rideId).delete { error in
            if let error = error {
                alertMessage = "Failed to delete ride: \(error.localizedDescription)"
            } else {
                alertMessage = "Ride deleted successfully."
                loadRides() // refresh rides list
            }
            showingAlert = true
        }
    }

    func createDriverNotification(driverId: String, riderId: String, rideId: String) {
        let db = Firestore.firestore()
        db.collection("profiles").document(riderId).getDocument { docSnapshot, _ in
            let riderFullName = docSnapshot?.data()?["fullName"] as? String ?? "Someone"
            let notificationData: [String: Any] = [
                "sender_id": riderId,
                "receiver_id": driverId,
                "ride_id": rideId,
                "context": "\(riderFullName) requested a ride with you",
                "created_At": Timestamp(date: Date()),
                "is_read": false,
                "type": "ride_request"
            ]
            db.collection("profiles").document(driverId)
                .collection("notifications")
                .addDocument(data: notificationData) { error in
                    if let error = error {
                        print("Error creating notification: \(error.localizedDescription)")
                    }
                }
        }
    }
}

extension Ride {
    init?(document: [String: Any], id: String) {
        guard
            let fromLocation = document["departureFrom"] as? String,
            let toLocation = document["departureTo"] as? String,
            let timestamp = document["departureDateTime"] as? Timestamp,
            let travelFee = document["price"] as? Int,
            let seatsAvailable = document["seatsAvailable"] as? Int,
            let driverId = document["driverId"] as? String
        else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short

        self.id = id
        self.fromLocation = fromLocation
        self.toLocation = toLocation
        self.departureTime = dateFormatter.string(from: timestamp.dateValue())
        self.arrivalTime = ""
        self.travelFee = travelFee
        self.seatsAvailable = seatsAvailable
        self.timeToTravel = ""
        self.driverId = driverId
        self.driverName = nil
        self.driverImageData = nil
    }
}

struct RideCardView: View {
    let ride: Ride
    let requested: Bool
    let onRequest: () -> Void
    let onCancel: () -> Void
    let deleteMode: Bool  // when true show Delete button instead of Request/Cancel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                if let data = ride.driverImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 2))
                } else {
                    Image(systemName: "car.fill")
                        .resizable()
                        .frame(width: 54, height: 54)
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 2))
                }
                VStack(alignment: .leading) {
                    Text(ride.driverName ?? "Loading...")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("\(ride.fromLocation) ➔ \(ride.toLocation)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                if deleteMode {
                    Button(action: onCancel) {
                        Text("Delete")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: requested ? onCancel : onRequest) {
                        Text(requested ? "Cancel" : "Request")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(Color(red: 128/255, green: 0, blue: 0))
                            .cornerRadius(8)
                    }
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
