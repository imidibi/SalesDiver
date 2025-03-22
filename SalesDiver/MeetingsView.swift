import SwiftUI

struct MeetingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Meetings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    NavigationLink(destination: PlanMeetingView()) {
                        MenuButton(icon: "calendar.badge.plus", label: "Plan Meeting")
                    }

                    NavigationLink(destination: RecordMeetingView()) {
                        MenuButton(icon: "pencil.and.outline", label: "Record Meeting")
                    }

                    NavigationLink(destination: ViewMeetingsView()) {
                        MenuButton(icon: "doc.text.magnifyingglass", label: "View Meetings")
                    }
                }
                .padding()
            }
        }
    }
}

struct MenuButton: View {
    var icon: String
    var label: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.blue)
                .padding()

            Text(label)
                .font(.title2)
                .foregroundColor(.primary)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct RecordMeetingView: View {
    var body: some View {
        Text("Record Meeting Screen")
    }
}

struct ViewMeetingsView: View {
    var body: some View {
        Text("View Meetings Screen")
    }
}
