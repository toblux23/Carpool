import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SwiftData

struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let context: String
    let createdAt: Date
    let isSystem: Bool
    var senderId: String? = nil
    var senderImageData: Data? = nil

    init?(document: [String: Any], id: String) {
        guard let type = document["type"] as? String,
              let context = document["context"] as? String,
              let timestamp = document["created_At"] as? Timestamp else {
            return nil
        }
        self.id = id
        self.title = type
        self.context = context
        self.createdAt = timestamp.dateValue()
        self.isSystem = (type == "system")
        self.senderId = document["sender_id"] as? String
        self.senderImageData = nil
    }
}

struct NotificationView: View {
    @Environment(\.modelContext) private var context
    @State private var todayNotifications: [NotificationItem] = []
    @State private var pastWeekNotifications: [NotificationItem] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading) {
            Text("Notification")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                .padding(.top, 40)
                .padding(.leading, 18)

            Text("Today")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                .padding(.leading, 22)
                .padding(.top, 10)

            if isLoading {
                ProgressView().padding()
            } else if todayNotifications.isEmpty {
                Text("No notifications today.")
                    .padding()
                    .foregroundColor(.gray)
            } else {
                ForEach(todayNotifications) { item in
                    NotificationCell(item: item)
                }
            }

            Text("Last 7 days")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                .padding(.leading, 22)
                .padding(.top, 10)

            if !isLoading && pastWeekNotifications.isEmpty {
                Text("No notifications in the last 7 days.")
                    .padding()
                    .foregroundColor(.gray)
            } else {
                ForEach(pastWeekNotifications) { item in
                    NotificationCell(item: item)
                }
            }
            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: loadNotifications)
    }

    func loadNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        db.collection("profiles").document(userId)
            .collection("notifications")
            .order(by: "created_At", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch notifications: \(error)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                let calendar = Calendar.current
                let now = Date()
                
                var notifications = documents.compactMap { NotificationItem(document: $0.data(), id: $0.documentID) }
                
                // Fetch sender profile images from SwiftData
                for i in notifications.indices {
                    if let senderId = notifications[i].senderId {
                        let request = FetchDescriptor<UserProfile>(
                            predicate: #Predicate { profile in profile.userId == senderId }
                        )
                        if let profile = try? context.fetch(request).first {
                            notifications[i].senderImageData = profile.profileImageData
                        }
                    }
                }
                
                todayNotifications = notifications.filter {
                    calendar.isDateInToday($0.createdAt)
                }
                pastWeekNotifications = notifications.filter {
                    let diff = calendar.dateComponents([.day], from: $0.createdAt, to: now).day ?? 0
                    return diff <= 7 && !calendar.isDateInToday($0.createdAt)
                }
                
                isLoading = false
            }
    }
}

struct NotificationCell: View {
    let item: NotificationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if item.isSystem {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text("?")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else if let data = item.senderImageData,
                      let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 54, height: 54)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.capitalized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Text(item.context)
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                Text(DateFormatter.localizedString(from: item.createdAt, dateStyle: .medium, timeStyle: .short))
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .bold))
            }
            Spacer()
            Image(systemName: "ellipsis")
                .foregroundColor(.black)
                .font(.system(size: 24))
                .padding(.top, 8)
        }
        .padding(.horizontal, 16)
    }
}
