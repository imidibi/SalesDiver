import SwiftUI
import CoreData

struct PlanMeetingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var meetingTitle: String = ""
    @State private var meetingDate: Date = Date()
    @FocusState private var isCompanySearchFocused: Bool
    private static func computeDefaultMeetingTime() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
    }

    @State private var meetingTime: Date = PlanMeetingView.computeDefaultMeetingTime()
    @State private var selectedCompany: CompanyEntity?
    @State private var selectedOpportunity: OpportunityEntity?
    @State private var selectedAttendees: Set<ContactsEntity> = []
    @State private var meetingObjective: String = ""
    @State private var companySearchText: String = ""
    @State private var opportunitySearchText: String = ""
    @State private var contactsSearchText: String = ""
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @State private var showCompanyPicker = false
    @State private var showOpportunityPicker = false

    @FetchRequest(entity: CompanyEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CompanyEntity.name, ascending: true)])
    private var companies: FetchedResults<CompanyEntity>
    
    var filteredOpportunities: [OpportunityEntity] {
        guard let company = selectedCompany else { return [] }
        guard let opportunities = company.opportunities as? Set<OpportunityEntity> else { return [] }
        let sorted = opportunities.sorted {
            let name1 = $0.name ?? ""
            let name2 = $1.name ?? ""
            return name1 < name2
        }
        return sorted
    }
    
    var visibleOpportunities: [OpportunityEntity] {
        var result: [OpportunityEntity] = []
        for opportunity in filteredOpportunities {
            let name = opportunity.name ?? ""
            if opportunitySearchText.isEmpty || name.localizedCaseInsensitiveContains(opportunitySearchText) {
                result.append(opportunity)
            }
        }
        return result
    }
    
    var filteredContacts: [ContactsEntity] {
        guard let company = selectedCompany else { return [] }
        guard let contacts = company.contacts as? Set<ContactsEntity> else { return [] }
        let sorted = contacts.sorted {
            let name1 = $0.firstName ?? ""
            let name2 = $1.firstName ?? ""
            return name1 < name2
        }
        return sorted
    }
    
    var visibleContacts: [ContactsEntity] {
        var result: [ContactsEntity] = []
        for contact in filteredContacts {
            let firstName = contact.firstName ?? ""
            let lastName = contact.lastName ?? ""
            let fullName = "\(firstName) \(lastName)"
            if contactsSearchText.isEmpty || fullName.localizedCaseInsensitiveContains(contactsSearchText) {
                result.append(contact)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    meetingHeaderSection
                    companySection
                    if selectedCompany != nil {
                        opportunitySection
                        attendeesSection
                    }
                    objectiveSection
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Plan Meeting")
        }
    }
    
    private var meetingHeaderSection: some View {
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
        .background {
            RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        }
    }

    private var companySection: some View {
        GroupBox(label: Text("Company").bold()) {
            VStack(alignment: .leading, spacing: 10) {
                Button(action: { showCompanyPicker = true }) {
                    HStack {
                        Text(selectedCompany?.name ?? "Select a Company")
                            .foregroundColor(selectedCompany == nil ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showCompanyPicker) {
            NavigationStack {
                List {
                    Section {
                        TextField("Search Companies", text: $companySearchText)
                            .textFieldStyle(.roundedBorder)
                    }

                    ForEach(companies.filter {
                        companySearchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(companySearchText) ?? false)
                    }, id: \.self) { company in
                        Button(action: {
                            selectedCompany = company
                            companySearchText = ""
                            showCompanyPicker = false
                        }) {
                            Text(company.name ?? "Unknown")
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Select Company")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showCompanyPicker = false
                        }
                    }
                }
            }
        }
    }

    private var opportunitySection: some View {
        GroupBox(label: Text("Opportunity").bold()) {
            VStack(alignment: .leading, spacing: 10) {
                Button(action: { showOpportunityPicker = true }) {
                    HStack {
                        Text(selectedOpportunity?.name ?? "Select an Opportunity")
                            .foregroundColor(selectedOpportunity == nil ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showOpportunityPicker) {
            NavigationStack {
                List {
                    Section {
                        TextField("Search Opportunities", text: $opportunitySearchText)
                            .textFieldStyle(.roundedBorder)
                    }

                    ForEach(visibleOpportunities, id: \.self) { opportunity in
                        Button(action: {
                            selectedOpportunity = opportunity
                            opportunitySearchText = ""
                            showOpportunityPicker = false
                        }) {
                            Text(opportunity.name ?? "Untitled")
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Select Opportunity")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showOpportunityPicker = false
                        }
                    }
                }
            }
        }
    }

    private var attendeesSection: some View {
        GroupBox(label: Text("Attendees").bold()) {
            VStack(alignment: .leading, spacing: 5) {
                TextField("Search Attendees", text: $contactsSearchText)
                    .textFieldStyle(.roundedBorder)

                ForEach(visibleContacts, id: \.self) { contact in
                    let fullName = "\((contact.firstName ?? "")) \((contact.lastName ?? ""))"
                    let isSelected = selectedAttendees.contains(contact)

                    MultipleSelectionRow(title: fullName, isSelected: isSelected) {
                        selectedAttendees.formSymmetricDifference([contact])
                    }
                }
            }
        }
    }

    private var objectiveSection: some View {
        GroupBox(label: Text("Meeting Objective").bold()) {
            TextField("Enter Objective", text: $meetingObjective)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var saveButton: some View {
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
