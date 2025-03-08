import SwiftUI

struct MeetingsView: View {
    var body: some View {
        VStack {
            Text("Meetings")
                .font(.largeTitle)
                .bold()
                .padding()

            Spacer()
        }
        .navigationTitle("Meetings")
    }
}

struct MeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingsView()
    }
}
