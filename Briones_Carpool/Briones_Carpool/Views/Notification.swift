import SwiftUI

struct NotificationItem: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let message: String
    let dateString: String
    let isSystem: Bool
}

let todayNotifications = [
    NotificationItem(imageName: "system_icon", title: "Automatic Notification", message: "Your Password was changed", dateString: "Aug 29, 12:30 PM", isSystem: true),
    NotificationItem(imageName: "driver_profile", title: "Voltaire Parraba", message: "Accepted your request.", dateString: "Aug 19, 10:30 AM", isSystem: false)
]

let pastWeekNotifications = [
    NotificationItem(imageName: "driver_profile", title: "Voltaire Parraba", message: "5 minutes till ride arrive", dateString: "Aug 19, 10:30 AM", isSystem: false),
    NotificationItem(imageName: "driver_profile", title: "Voltaire Parraba", message: "Requested to ride with you", dateString: "Jun 19, 10:30 AM", isSystem: false),
    NotificationItem(imageName: "driver_profile", title: "Voltaire Parraba", message: "Requested to ride with you", dateString: "Jun 19, 10:30 AM", isSystem: false),
    NotificationItem(imageName: "driver_profile", title: "Voltaire Parraba", message: "Requested to ride with you", dateString: "Jun 19, 10:30 AM", isSystem: false)
]

struct NotificationView: View {
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Notification")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                .padding(.top, 40) // reduced top padding for consistency
                .padding(.leading, 18)

            Text("Today")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                .padding(.leading, 22)
                .padding(.top, 10)
            
            ForEach(todayNotifications) { item in
                NotificationCell(item: item)
            }
            
            Text("Last 7 days")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                .padding(.leading, 22)
                .padding(.top, 10)
            
            ForEach(pastWeekNotifications) { item in
                NotificationCell(item: item)
            }

            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom) // ignore bottom area only for tab bar
        .navigationBarBackButtonHidden(true)
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
            } else {
                Image("driver_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Text(item.message)
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                Text(item.dateString)
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

#Preview {
    NotificationView()
}
