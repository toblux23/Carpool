import SwiftUI

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
                    if selectedTab == 0 {
                        RideCard(
                            driverName: "Driver 1",
                            driverType: "Driver",
                            profileImage: "profile1",
                            fromLocation: "SM Lucena",
                            toLocation: "Manuel S. Enverga University Foundation",
                            departureTime: "08:15 AM",
                            arrivalTime: "08:30 AM",
                            travelFee: 20,
                            timeToTravel: "15 mins",
                            showRate: false
                        )
                        RideCard(
                            driverName: "Driver 2",
                            driverType: "Driver",
                            profileImage: "profile1",
                            fromLocation: "SM Lucena",
                            toLocation: "Manuel S. Enverga University Foundation",
                            departureTime: "08:15 AM",
                            arrivalTime: "08:30 AM",
                            travelFee: 20,
                            timeToTravel: "15 mins",
                            showRate: true
                        )
                    } else if selectedTab == 1 {
                        RequestCard(requesterName: "Voltaire Parraba", profileImage: "profile1", dateString: "Aug 19, 10:30 AM")
                        RequestCard(requesterName: "Voltaire Parraba", profileImage: "profile1", dateString: "Aug 19, 10:30 AM")
                    } else {
                        ReviewTab()
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
