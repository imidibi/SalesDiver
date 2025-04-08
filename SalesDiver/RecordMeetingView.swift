import SwiftUI
import CoreData

struct RecordMeetingView: View {
    let meeting: MeetingsEntity
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(meeting.title ?? "Untitled Meeting")
                .font(.largeTitle)
                .padding(.bottom, 8)

            if let date = meeting.date {
                Text("Date: \(date, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let company = meeting.company {
                Text("Company: \(company.name ?? "Unknown Company")")
                    .font(.subheadline)
            }

            if let contacts = meeting.contacts as? Set<ContactsEntity>, !contacts.isEmpty {
                let attendeeNames = contacts.map { "\($0.firstName ?? "") \($0.lastName ?? "")" }.joined(separator: ", ")
                Text("Attendees: \(attendeeNames)")
                    .font(.subheadline)
            }

            if let objective = meeting.objective {
                Text("Objective: \(objective)")
                    .font(.subheadline)
                    .italic()
            }

            if let opportunityEntity = meeting.opportunity {
                let wrapper = OpportunityWrapper(managedObject: opportunityEntity)
                BANTIndicatorView(opportunity: wrapper, onBANTSelected: { _ in })
                    .scaleEffect(0.8)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Record Meeting")
        .navigationBarBackButtonHidden(false)  // Correct placement
    }
}

// Helper DateFormatter for displaying date
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

