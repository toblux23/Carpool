import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CreateRideView: View {
    @State private var departureFrom = "SM Lucena City"
    @State private var departureTo = "MSEUF College"
    @State private var date = Date()
    @State private var time = Date()
    @State private var seats = 4
    @State private var price = 20
    @State private var paymentMethod = "Cash"
    @Environment(\.dismiss) var dismiss

    let paymentMethods = [
        ("Cash", "banknote.fill"),
        ("Card", "creditcard.fill")
    ]
    
    func createRide(completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()


        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "CreateRide", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }

        let calendar = Calendar.current
        let combinedDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: time),
            minute: calendar.component(.minute, from: time),
            second: 0,
            of: date
        ) ?? Date()

        let rideData: [String: Any] = [
            "driverId": currentUserId,
            "departureFrom": departureFrom,
            "departureTo": departureTo,
            "departureDateTime": Timestamp(date: combinedDate),
            "seatsAvailable": seats,
            "price": price,
            "paymentMethod": paymentMethod,
            "passengers": [],
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("rides").addDocument(data: rideData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                            .imageScale(.large)
                    }
                    Spacer()
                }
                .padding(.top, 10)

                Text("Create Ride")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 18) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                        TextField("", text: $departureFrom)
                            .disabled(true) // keep hardcoded for now
                            .padding(.horizontal, 6)
                            .frame(height: 38)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                        TextField("", text: $departureTo)
                            .disabled(true)
                            .padding(.horizontal, 6)
                            .frame(height: 38)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Departure")
                            .bold()
                        HStack(spacing: 16) {
                            HStack {
                                Image(systemName: "calendar")
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            HStack {
                                Image(systemName: "clock")
                                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }

                    // Seats
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Seats Available")
                            .bold()
                        HStack(spacing: 12) {
                            Text("\(seats)")
                                .frame(width: 60)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            Button(action: { if seats > 1 { seats -= 1 } }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                            Button(action: { if seats < 12 { seats += 1 } }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Price
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Price")
                            .bold()
                        HStack(spacing: 8) {
                            TextField("Price", value: $price, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            HStack(spacing: 4) {
                                Image("php")
                                    .resizable()
                                    .frame(width: 25, height: 17)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text("PHP")
                                    .font(.body)
                            }
                            .padding(.horizontal, 6)
                            .frame(height: 38)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Payment
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferred Payment Method")
                            .bold()
                        HStack(spacing: 16) {
                            ForEach(paymentMethods, id: \.0) { method, systemName in
                                Button(action: {
                                    paymentMethod = method
                                }) {
                                    HStack {
                                        Image(systemName: systemName)
                                            .imageScale(.large)
                                        Text(method)
                                            .font(.body)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(paymentMethod == method ? Color(.systemGray5) : Color(.white))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(paymentMethod == method ? Color(red: 128/255, green: 0, blue: 0) : Color(.systemGray4), lineWidth: 2)
                                    )
                                }
                                .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                        .background(Color.white)
                )
                .padding(.horizontal)

                // Create button
                Button(action: {
                    createRide { result in
                        switch result {
                        case .success():
                            dismiss()
                        case .failure(let error):
                            print("Error creating ride: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Create Ride")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 128/255, green: 0, blue: 0))
                        .cornerRadius(24)
                }
                .padding(.horizontal)
                .padding(.top, 36)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    CreateRideView()
}
