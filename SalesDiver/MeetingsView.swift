import SwiftUI

struct MeetingsView: View {
    var body: some View {
        ZStack {
            WaterBackgroundView() // Apply the WaterBackgroundView for the blue gradient and wave effect
            
            VStack {
                Text("Meetings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40) // Adjust padding for title
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
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
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80) // Exactly 80x80 icon size
                .foregroundColor(.blue) // Match icon color
            
            Text(label)
                .font(.headline) // Match text formatting
                .foregroundColor(.black) // Match text color
                .multilineTextAlignment(.center) // Center text inside the button
        }
        .frame(width: 180, height: 180) // Apply frame to the entire button
        .padding()
        .background(Color.white) // Use white background
        .cornerRadius(15) // Adjusted corner radius
        .shadow(radius: 5) // Adjusted shadow effect
    }
}

struct RecordMeetingView: View {
    var body: some View {
        Text("Record Meeting Screen")
    }
}
