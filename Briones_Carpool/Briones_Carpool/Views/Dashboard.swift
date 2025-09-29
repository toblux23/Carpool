import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SwiftData

// MARK: - RideRequest Model
struct RideRequest: Identifiable {
    let id: String
    let riderId: String
    let requesterName: String
    let requesterImageData: Data?
    let requestedAt: Date
    let rideId: String
    let status: String
}

// Assume Ride model is imported from your existing file

// MARK: - RequestsView
struct RequestsView: View {
    @Environment(\.modelContext) private var context
    @State private var requests: [RideRequest] = []
    @State private var isLoading = true
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if requests.isEmpty {
                Text("No ride requests.")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(requests) { request in
                            RideRequestCard(request: request,
                                            onAccept: { acceptRequest(request) },
                                            onReject: { rejectRequest(request) })
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear(perform: loadRequests)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Request Response"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func loadRequests() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("rided_requests")
            .whereField("driver_id", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    alertMessage = "Failed to load requests: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                var tempRequests: [RideRequest] = []
                let group = DispatchGroup()

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    let requesterId = data["rider_id"] as? String ?? ""
                    let rideId = data["rideId"] as? String ?? ""
                    let status = data["status"] as? String ?? ""
                    let ts = data["requestedAt"] as? Timestamp ?? Timestamp(date: Date())
                    let requestedAt = ts.dateValue()


                    var fullName = "Unknown"

                    group.enter()
                    db.collection("profiles").document(requesterId).getDocument { userDoc, _ in
                        if let userData = userDoc?.data() {
                            fullName = userData["fullName"] as? String ?? "Unknown"
                        }
                        group.leave()
                    }

                    group.notify(queue: .main) {
                        let request = FetchDescriptor<UserProfile>(predicate: #Predicate { profile in profile.userId == requesterId })
                        let profile = try? context.fetch(request).first
                        let imageData = profile?.profileImageData

                        let rideRequest = RideRequest(id: doc.documentID,
                                                     riderId: requesterId,
                                                     requesterName: fullName,
                                                     requesterImageData: imageData,
                                                     requestedAt: requestedAt,
                                                     rideId: rideId,
                                                     status: status)
                        tempRequests.append(rideRequest)

                        if tempRequests.count == snapshot?.documents.count {
                            requests = tempRequests
                        }
                    }
                }
                if snapshot?.documents.isEmpty ?? true {
                    requests = []
                }
            }
    }

    func acceptRequest(_ request: RideRequest) {
        let db = Firestore.firestore()
        db.collection("rided_requests").document(request.id)
            .updateData(["status": "accepted"]) { error in
                if let error = error {
                    alertMessage = "Failed to update status: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                let rideRef = db.collection("rides").document(request.rideId)
                rideRef.updateData([
                    "passengers": FieldValue.arrayUnion([request.riderId]),
                    "seatsAvailable": FieldValue.increment(Int64(-1))
                ]) { error in
                    if let error = error {
                        alertMessage = "Failed to update ride: \(error.localizedDescription)"
                        showingAlert = true
                        return
                    }
                    notifyRider(riderId: request.riderId, rideId: request.rideId, accepted: true)
                    alertMessage = "Request Accepted."
                    showingAlert = true
                    loadRequests()
                }
            }
    }

    func rejectRequest(_ request: RideRequest) {
        let db = Firestore.firestore()
        db.collection("rided_requests").document(request.id)
            .updateData(["status": "rejected"]) { error in
                if let error = error {
                    alertMessage = "Failed to update status: \(error.localizedDescription)"
                    showingAlert = true
                } else {
                    notifyRider(riderId: request.riderId, rideId: request.rideId, accepted: false)
                    alertMessage = "Request Rejected."
                    showingAlert = true
                    loadRequests()
                }
            }
    }

    func notifyRider(riderId: String, rideId: String, accepted: Bool) {
        let db = Firestore.firestore()
        let contextText = accepted ? "Your ride request was accepted." : "Your ride request was rejected."
        let notificationData: [String: Any] = [
            "type": "ride_request_status",
            "ride_id": rideId,
            "context": contextText,
            "created_At": Timestamp(date: Date()),
            "is_read": false
        ]
        db.collection("profiles").document(riderId)
            .collection("notifications")
            .addDocument(data: notificationData)
    }
}

struct RidesView: View {
    @Environment(\.modelContext) private var context
    @State private var rides: [Ride] = []
    @State private var isLoading = true
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading rides...")
                    .padding()
            } else if rides.isEmpty {
                Text("No rides found.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(rides) { ride in
                            RideCard(
                                driverName: ride.driverName ?? "Loading...",
                                driverType: "Driver",
                                profileImage: "",
                                fromLocation: ride.fromLocation,
                                toLocation: ride.toLocation,
                                departureTime: ride.departureTime,
                                arrivalTime: ride.arrivalTime,
                                travelFee: ride.travelFee,
                                timeToTravel: ride.timeToTravel,
                                showRate: false
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear(perform: loadRides)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Helper: Date Formatter
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Load Rides
    func loadRides() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        var fetchedRides: [Ride] = []
        let group = DispatchGroup()

        group.enter()
        db.collection("rides")
            .whereField("driverId", isEqualTo: userId)
            .getDocuments { snapshot, _ in
                if let snapshot = snapshot {
                    for doc in snapshot.documents {
                        let ride = createRide(from: doc)
                        fetchedRides.append(ride)
                    }
                }
                group.leave()
            }

        group.enter()
        db.collection("rides")
            .whereField("passengers", arrayContains: userId)
            .getDocuments { snapshot, _ in
                if let snapshot = snapshot {
                    for doc in snapshot.documents {
                        let ride = createRide(from: doc)
                        if !fetchedRides.contains(where: { $0.id == ride.id }) {
                            fetchedRides.append(ride)
                        }
                    }
                }
                group.leave()
            }

        group.notify(queue: .main) {
            fetchDriverNames(for: fetchedRides)
        }
    }

    func fetchDriverNames(for rides: [Ride]) {
        @EnvironmentObject var authVM: AuthViewModel
        let db = Firestore.firestore()
        var updatedRides = rides
        let group = DispatchGroup()

        for (index, ride) in rides.enumerated() {
            group.enter()
            db.collection("profiles").document(ride.driverId).getDocument { snapshot, error in
                if let data = snapshot?.data(), let name = data["fullName"] as? String {
                    updatedRides[index].driverName = name
                } else {
                    updatedRides[index].driverName = "Unknown"
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.rides = updatedRides
            self.isLoading = false
        }
    }

    // MARK: - Create Ride from Firestore Document
    func createRide(from doc: DocumentSnapshot) -> Ride {
        let data = doc.data() ?? [:]
        let rideId = doc.documentID
        let driverId = data["driverId"] as? String ?? ""
        let fromLocation = data["departureFrom"] as? String ?? ""
        let toLocation = data["departureTo"] as? String ?? ""
        let departureTimestamp = data["departureDateTime"] as? Timestamp ?? Timestamp(date: Date())
        let arrivalTimestamp = data["arrivalDateTime"] as? Timestamp
        let travelFee = data["price"] as? Int ?? 0
        let seatsAvailable = data["seatsAvailable"] as? Int ?? 0
        let timeToTravel = data["timeToTravel"] as? String ?? ""

        // format timestamps to String
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let departureTimeString = formatter.string(from: departureTimestamp.dateValue())
        let arrivalTimeString: String? = {
            guard let at = arrivalTimestamp else { return nil }
            return formatter.string(from: at.dateValue())
        }()

        return Ride(
            id: rideId,
            fromLocation: fromLocation,
            toLocation: toLocation,
            departureTime: departureTimeString,
            arrivalTime: arrivalTimeString ?? "",
            travelFee: travelFee,
            seatsAvailable: seatsAvailable,
            timeToTravel: timeToTravel,
            driverId: driverId,
            driverName: nil,
            driverImageData: nil
        )
    }


}



struct RideRequestCard: View {
    let request: RideRequest
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack {
            HStack {
                if let data = request.requesterImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.gray)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.requesterName)
                        .font(.headline)
                    Text(DateFormatter.localizedString(from: request.requestedAt, dateStyle: .medium, timeStyle: .short))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            HStack(spacing: 16) {
                Button("Accept", action: onAccept)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color(red: 128/255, green: 0, blue: 0))
                    .cornerRadius(8)

                Button("Reject", action: onReject)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 128/255, green: 0, blue: 0), lineWidth: 2)
                    )
            }
            .padding(.top, 8)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
    }
}

// MARK: - Your existing views with static sample data -

struct Review: Identifiable {
    let id = UUID()
    let reviewerName: String
    let comment: String
    let rating: Int
}

struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.reviewerName)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
            }
            Text("“\(review.comment)”")
                .font(.body)
                .italic()
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct RideCard: View {
    let driverName: String
    let driverType: String
    let profileImage: String
    let fromLocation: String
    let toLocation: String
    let departureTime: String
    let arrivalTime: String
    let travelFee: Int
    let timeToTravel: String
    let showRate: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(profileImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(driverName)
                        .font(.headline)
                    Text(driverType)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                if showRate {
                    Button("Rate") {}
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(8)
                } else {
                    Button("Details") {}
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(8)

                    Button(action: {}) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                        .font(.system(size: 10))
                        .padding(.top, 3)
                    Text(fromLocation)
                        .font(.body)
                    Spacer()
                    Text(departureTime)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                        .font(.system(size: 12))
                        .padding(.top, 3)
                    Text(toLocation)
                        .font(.body)
                    Spacer()
                    Text(arrivalTime)
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            Divider()

            HStack {
                Text("₱\(travelFee)")
                    .font(.headline)
                Spacer()
                Text(timeToTravel)
                    .font(.headline)
            }
            .padding(.vertical, 2)

            HStack {
                Text("Travel Fee")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("Time to Travel")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: 320, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.vertical, 6)
    }
}

struct RequestCard: View {
    let requesterName: String
    let profileImage: String
    let dateString: String

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(profileImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 2))
                VStack(alignment: .leading, spacing: 2) {
                    Text(requesterName)
                        .font(.headline)
                    Text("Wants to Ride with You")
                        .font(.subheadline)
                    Text(dateString)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            HStack(spacing: 16) {
                Button("Accept") {}
                    .buttonStyle(PlainButtonStyle())
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color(red: 128/255, green: 0, blue: 0))
                    .cornerRadius(8)
                Button("Reject") {}
                    .buttonStyle(PlainButtonStyle())
                    .font(.subheadline)
                    .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 128/255, green: 0, blue: 0), lineWidth: 2)
                    )
            }
        }
        .frame(maxWidth: 320, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).stroke(Color(.systemGray4), lineWidth: 1))
        .padding(.vertical, 6)
    }
}

struct ReviewTab: View {
    let receivedReviews = [
        Review(reviewerName: "Alice", comment: "Very safe and courteous driver!", rating: 5),
        Review(reviewerName: "Bob", comment: "Smooth ride and pleasant experience.", rating: 4),
        Review(reviewerName: "You", comment: "The driver arrived late but trip was comfortable.", rating: 3),
        Review(reviewerName: "You", comment: "Great ride, friendly driver.", rating: 5)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Reviews")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .foregroundColor(Color(red: 128/255, green: 0, blue: 0))

                VStack(spacing: 12) {
                    ForEach(receivedReviews) { review in
                        ReviewCard(review: review)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Main dashboard view including RequestsView integration with tabs

struct DashboardView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                Spacer()
                Text(selectedTab == 0 ? "Your Rides" : selectedTab == 1 ? "Ride Requests" : "Review")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)

            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    Text("Rides")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTab == 0 ? Color(red: 128/255, green: 0, blue: 0) : Color(.white))
                        .foregroundColor(selectedTab == 0 ? .white : Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(12)
                }
                Button(action: { selectedTab = 1 }) {
                    Text("Requests")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTab == 1 ? Color(red: 128/255, green: 0, blue: 0) : Color(.white))
                        .foregroundColor(selectedTab == 1 ? .white : Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(12)
                }
                Button(action: { selectedTab = 2 }) {
                    Text("Review")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTab == 2 ? Color(red: 128/255, green: 0, blue: 0) : Color(.white))
                        .foregroundColor(selectedTab == 2 ? .white : Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)

            ScrollView {
                VStack {
                    switch selectedTab {
                    case 0:
                        RidesView()
                    case 1:
                        RequestsView()
                    case 2:
                        ReviewTab()
                    default:
                        EmptyView()
                    }

                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    DashboardView()
}
