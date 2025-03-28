import SwiftUI
import CoreData

struct PlanMeetingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var meetingTitle: String = ""
    @State private var meetingDate: Date = Date()
    @State private var meetingTime: Date = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: Date()), minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedCompany: CompanyEntity?
    @State private var selectedOpportunity: OpportunityEntity?
    @State private var selectedAttendees: Set<ContactsEntity> = []
    @State private var meetingObjective: String = ""
    @State private var companySearchText: String = ""
    @State private var opportunitySearchText: String = ""
    @State private var contactsSearchText: String = ""
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false

    @FetchRequest(entity: CompanyEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CompanyEntity.name, ascending: true)])
    private var companies: FetchedResults<CompanyEntity>
    
    var filteredOpportunities: [OpportunityEntity] {
        guard let company = selectedCompany, let opportunitiesSet = company.opportunities as? Set<OpportunityEntity> else { return [] }
        return Array(opportunitiesSet).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    var filteredContacts: [ContactsEntity] {
        guard let company = selectedCompany, let contactsSet = company.contacts as? Set<ContactsEntity> else { return [] }
        return Array(contactsSet).sorted { ($0.firstName ?? "") < ($1.firstName ?? "") }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Meeting Title")
                                .font(.headline)
                            TextField("Enter Meeting Title", text: $meetingTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .frame(width: 1)
                            .foregroundColor(.black)
                            .padding(.vertical)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Date & Time")
                                .font(.headline)

                            Button(action: { showingDatePicker = true }) {
                                Text(meetingDate, style: .date)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .sheet(isPresented: $showingDatePicker) {
                                VStack {
                                    DatePicker("Select Date", selection: $meetingDate, displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                    Button("Done") {
                                        showingDatePicker = false
                                    }
                                    .padding()
                                }
                            }

                            Button(action: { showingTimePicker = true }) {
                                Text(meetingTime, style: .time)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .sheet(isPresented: $showingTimePicker) {
                                VStack(spacing: 20) {
                                    Text("Select Time")
                                        .font(.headline)
                                        .padding(.top)
                                        .multilineTextAlignment(.center)

                                    DatePicker("", selection: $meetingTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()

                                    Button("Done") {
                                        showingTimePicker = false
                                    }
                                    .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemBackground))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    )

                    GroupBox(label: Text("Company").bold()) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Search Company", text: $companySearchText)
                                .textFieldStyle(.roundedBorder)

                            Menu {
                                ForEach(companies.filter {
                                    companySearchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(companySearchText) ?? false)
                                }, id: \.self) { company in
                                    Button(company.name ?? "Unknown") {
                                        selectedCompany = company
                                    }
                                }
                            } label: {
                                Label(
                                    title: { Text(selectedCompany?.name ?? "Select a Company") },
                                    icon: { Image(systemName: "building.2") }
                                )
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }

                    if selectedCompany != nil {
                        GroupBox(label: Text("Opportunity").bold()) {
                            VStack(alignment: .leading, spacing: 10) {
                                TextField("Search Opportunity", text: $opportunitySearchText)
                                    .textFieldStyle(.roundedBorder)

                                Menu {
                                    ForEach(filteredOpportunities.filter {
                                        opportunitySearchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(opportunitySearchText) ?? false)
                                    }, id: \.self) { opportunity in
                                        Button(opportunity.name ?? "Untitled") {
                                            selectedOpportunity = opportunity
                                        }
                                    }
                                } label: {
                                    Label(
                                        title: { Text(selectedOpportunity?.name ?? "Select an Opportunity") },
                                        icon: { Image(systemName: "briefcase.fill") }
                                    )
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }

                        GroupBox(label: Text("Attendees").bold()) {
                            VStack(alignment: .leading, spacing: 5) {
                                TextField("Search Attendees", text: $contactsSearchText)
                                    .textFieldStyle(.roundedBorder)

                                ForEach(filteredContacts.filter {
                                    contactsSearchText.isEmpty ||
                                    ("\(($0.firstName ?? "")) \(($0.lastName ?? ""))".localizedCaseInsensitiveContains(contactsSearchText))
                                }, id: \.self) { contact in
                                    let fullName = "\((contact.firstName ?? "")) \((contact.lastName ?? ""))"
                                    let isSelected = selectedAttendees.contains(contact)

                                    MultipleSelectionRow(title: fullName, isSelected: isSelected) {
                                        selectedAttendees.formSymmetricDifference([contact])
                                    }
                                }
                            }
                        }
                    }

                    GroupBox(label: Text("Meeting Objective").bold()) {
                        TextField("Enter Objective", text: $meetingObjective)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: saveMeeting) {
                        Text("Save Meeting")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Plan Meeting")
        }
    }
    
    func saveMeeting() {
        let newMeeting = MeetingsEntity(context: viewContext)
        
        // Assign properties
        newMeeting.title = meetingTitle
        let calendar = Calendar.current
        let combinedDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: meetingTime),
                                             minute: calendar.component(.minute, from: meetingTime),
                                             second: 0, of: meetingDate) ?? meetingDate
        newMeeting.date = combinedDateTime
        newMeeting.objective = meetingObjective
        
        // Safely assign company (ensure relationship exists in Core Data)
        if let company = selectedCompany {
            if newMeeting.entity.attributesByName.keys.contains("company") || newMeeting.entity.relationshipsByName.keys.contains("company") {
                newMeeting.company = company
            } else {
                print("Error: 'company' relationship does not exist in MeetingsEntity.")
            }
        }
        
        // Assign opportunity
        if let opportunity = selectedOpportunity {
            if newMeeting.entity.relationshipsByName.keys.contains("opportunity") {
                newMeeting.opportunity = opportunity
            } else {
                print("Error: 'opportunity' relationship does not exist in MeetingsEntity.")
            }
        }
        
        // Assign contacts
        if let contactsRelationship = newMeeting.entity.relationshipsByName["contacts"], contactsRelationship.isToMany {
            newMeeting.setValue(selectedAttendees, forKey: "contacts")
        } else {
            print("Error: 'contacts' relationship does not support multiple values.")
        }
        
        // Save Core Data with error handling
        do {
            try viewContext.save()
            print("Meeting successfully saved!")
            presentationMode.wrappedValue.dismiss() // Dismiss view after saving
        } catch {
            print("Failed to save meeting: \(error.localizedDescription)")
        }
    }
    
    struct MultipleSelectionRow: View {
        var title: String
        var isSelected: Bool
        var action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}
