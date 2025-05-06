import SwiftUI
import CoreData

struct ViewMeetingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var meetings: [MeetingsEntity] = []
    @State private var selectedMeeting: MeetingsEntity? = nil  // New state to track selected meeting
    @State private var isEditSheetPresented = false
    @State private var refreshID = UUID()  // New state for refresh ID
    @State private var isAddMeetingPresented = false

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

    var body:  some View {
        NavigationView {
            VStack {
                List {
                    ForEach(meetings, id: \.objectID) { meeting in
                        ZStack {
                            HStack {
                                MeetingRowView(meeting: meeting)

                                Spacer()

                                if let opportunity = meeting.opportunity {
                                    OpportunityDetailsView(opportunity: opportunity)
                                }
                            }
                            .padding()
                            .background(selectedMeeting == meeting ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedMeeting = meeting
                            }
                        }
                    }
                    .onDelete(perform: deleteMeeting)
                }
                .id(refreshID)  // Add ID to refresh the List
                .onAppear {
                    fetchMeetings()
                }
                .navigationTitle("View Meetings")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Edit Meeting") {
                            isEditSheetPresented = true
                        }
                        .disabled(selectedMeeting == nil)

                        if let meetingToStart = selectedMeeting {
                            NavigationLink(
                                destination: RecordMeetingView(meeting: meetingToStart)
                            ) {
                                Text("Record Meeting")
                            }
                        } else {
                            Text("Record Meeting")
                                .foregroundColor(.gray)
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isAddMeetingPresented = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $isEditSheetPresented, onDismiss: {
            fetchMeetings()
        }) {
            if let meeting = selectedMeeting {
                EditMeetingSheet(meeting: meeting, isPresented: $isEditSheetPresented)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onChange(of: isEditSheetPresented) {
            if !isEditSheetPresented {
                fetchMeetings()
                if let id = selectedMeeting?.objectID {
                    selectedMeeting = try? viewContext.existingObject(with: id) as? MeetingsEntity
                }
                refreshID = UUID()  // Update refresh ID
            }
        }
        .sheet(isPresented: $isAddMeetingPresented, onDismiss: {
            fetchMeetings()
            refreshID = UUID()
        }) {
            PlanMeetingView()
                .environment(\.managedObjectContext, viewContext)
        }
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

struct OpportunityDetailsView: View {
    let opportunity: OpportunityEntity

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Opportunity: \(opportunity.name ?? "Unknown")")
                .font(.subheadline)
                .foregroundColor(.blue)

            Text("Estimated Value: $\(opportunity.estimatedValue, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.gray)

            if let closeDate = opportunity.closeDate {
                Text("Expected Close: \(closeDate, formatter: shortDateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            let wrapper = OpportunityWrapper(managedObject: opportunity)
            BANTIndicatorView(opportunity: wrapper, onBANTSelected: { _ in })
                .scaleEffect(0.7)
                .padding(.top, 4)
        }
    }
}
