import SwiftUI
import CoreData

struct ViewMeetingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MeetingsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MeetingsEntity.date, ascending: false)]
    ) private var meetings: FetchedResults<MeetingsEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(meetings, id: \.self) { meeting in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meeting.title ?? "Untitled Meeting")
                            .font(.headline)

                        Text("Date: \(meeting.date ?? Date(), formatter: dateFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if let company = meeting.company {
                            Text("Company: \(company.name ?? "Unknown Company")")
                                .font(.subheadline)
                        }

                        if let opportunity = meeting.opportunity {
                            Text("Opportunity: \(opportunity.name ?? "Unknown Opportunity")")
                                .font(.subheadline)
                        }

                        if let contacts = meeting.contacts as? Set<ContactsEntity>, !contacts.isEmpty {
                            Text("Attendees: \(contacts.map { $0.firstName ?? "" + " " + ($0.lastName ?? "") }.joined(separator: ", "))")
                                .font(.subheadline)
                        }

                        Text("Objective: \(meeting.objective ?? "No objective specified.")")
                            .font(.subheadline)
                            .italic()
                    }
                    .padding()
                }
            }
            .navigationTitle("Meetings")
        }
        .navigationViewStyle(.stack) // Ensures full-screen mode on iPad
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
