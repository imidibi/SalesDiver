import SwiftUI
import CoreData

struct ViewMeetingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var meetings: [MeetingsEntity] = []

    private func fetchMeetings() {
        let request: NSFetchRequest<MeetingsEntity> = MeetingsEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MeetingsEntity.date, ascending: false)]

        do {
            meetings = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch meetings: \(error.localizedDescription)")
        }
    }

    private func deleteMeeting(at offsets: IndexSet) {
        offsets.forEach { index in
            let meetingToDelete = meetings[index]
            viewContext.delete(meetingToDelete)
            meetings.remove(at: index)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete meeting: \(error.localizedDescription)")
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(meetings, id: \.objectID) { meeting in
                    HStack {
                        NavigationLink(destination: PlanMeetingView(editingMeeting: meeting)) {
                            MeetingRowView(meeting: meeting)
                        }
                        
                        Spacer()
                        
                        if let opportunity = meeting.opportunity {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Opportunity: \(opportunity.name ?? "Unknown")")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)

                                Text("Expected Value: $\(opportunity.customPrice, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                if let closeDate = opportunity.closeDate {
                                    Text("Expected Close: \(closeDate, formatter: shortDateFormatter)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                if let opportunityEntity = meeting.opportunity {
                                    let wrapper = OpportunityWrapper(managedObject: opportunityEntity)
                                    BANTIndicatorView(opportunity: wrapper, onBANTSelected: { _ in })
                                        .scaleEffect(0.7)
                                        .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
                .onDelete(perform: deleteMeeting) // Enables swipe-to-delete
            }
            .onAppear {
                fetchMeetings()
            }
            .navigationTitle("Meetings")
            .toolbar {
                EditButton() // Allows toggling edit mode to enable deletion
            }
        }
        .navigationViewStyle(.stack)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

private let shortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

struct MeetingRowView: View {
    let meeting: MeetingsEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meeting.title ?? "Untitled Meeting")
                .font(.headline)

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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
