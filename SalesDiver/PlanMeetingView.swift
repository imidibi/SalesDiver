import SwiftUI
import CoreData


struct PlanMeetingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State var editingMeeting: MeetingsEntity?
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
    @State private var showAttendeePicker = false

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
        guard let company = selectedCompany else { return [] }
        guard let contacts = company.contacts as? Set<ContactsEntity> else { return [] }
        
        let sortedContacts = contacts.sorted {
            let name1 = "\($0.firstName ?? "") \($0.lastName ?? "")"
            let name2 = "\($1.firstName ?? "") \($1.lastName ?? "")"
            return name1 < name2
        }
        
        if contactsSearchText.isEmpty {
            return sortedContacts
        } else {
            return sortedContacts.filter { contact in
                let fullName = "\((contact.firstName ?? "")) \((contact.lastName ?? ""))"
                return fullName.localizedCaseInsensitiveContains(contactsSearchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    meetingHeaderSection
                    companyAndOpportunitySection
                    if selectedCompany != nil {
                        attendeesAndObjectiveSection
                    }
                    
                }
                .padding()
            }
            .navigationTitle("Plan Meeting")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeeting()
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

    private var companyAndOpportunitySection: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Company")
                    .font(.headline)
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
            .frame(maxWidth: .infinity)

            Rectangle()
                .frame(width: 1)
                .foregroundColor(.black)
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Opportunity")
                        .font(.headline)
                    bantIcons
                }
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


    
    func saveMeeting() {
        let calendar = Calendar.current
        let combinedDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: meetingTime),
                                             minute: calendar.component(.minute, from: meetingTime),
                                             second: 0, of: meetingDate) ?? meetingDate
        
        if let editingMeeting = editingMeeting {
            editingMeeting.title = meetingTitle
            editingMeeting.date = combinedDateTime
            editingMeeting.objective = meetingObjective
            editingMeeting.company = selectedCompany
            editingMeeting.opportunity = selectedOpportunity
            editingMeeting.contacts = NSSet(set: selectedAttendees)
        } else {
            let newMeeting = MeetingsEntity(context: viewContext)
            newMeeting.title = meetingTitle
            newMeeting.date = combinedDateTime
            newMeeting.objective = meetingObjective
            newMeeting.company = selectedCompany
            newMeeting.opportunity = selectedOpportunity
            newMeeting.contacts = NSSet(set: selectedAttendees)
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
                .padding(.vertical, 5)
            }
        }
    }

    @ViewBuilder
    private var bantIcons: some View {
        if let opportunity = selectedOpportunity {
            let wrapper = OpportunityWrapper(managedObject: opportunity)
            BANTIndicatorView(opportunity: wrapper, onBANTSelected: { _ in })
                .frame(height: 14)
        } else {
            EmptyView()
        }
    }
    
    init(editingMeeting: MeetingsEntity? = nil) {
        self.editingMeeting = editingMeeting
        _meetingTitle = State(initialValue: editingMeeting?.title ?? "")
        _meetingDate = State(initialValue: editingMeeting?.date ?? Date())
        _meetingTime = State(initialValue: editingMeeting?.date ?? PlanMeetingView.computeDefaultMeetingTime())
        _selectedCompany = State(initialValue: editingMeeting?.company)
        _selectedOpportunity = State(initialValue: editingMeeting?.opportunity)
        _selectedAttendees = State(initialValue: (editingMeeting?.contacts as? Set<ContactsEntity>) ?? [])
        _meetingObjective = State(initialValue: editingMeeting?.objective ?? "")
    }
    private var attendeesAndObjectiveSection: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Attendees")
                    .font(.headline)
                Button(action: { showAttendeePicker = true }) {
                    HStack {
                        Text(selectedAttendees.isEmpty ? "Select Attendees" : selectedAttendees.map { "\($0.firstName ?? "") \($0.lastName ?? "")" }.joined(separator: ", "))
                            .foregroundColor(selectedAttendees.isEmpty ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showAttendeePicker) {
                NavigationStack {
                    List {
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
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("Select Attendees")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showAttendeePicker = false
                            }
                        }
                    }
                }
            }
            
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.black)
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Meeting Objective")
                    .font(.headline)
                TextField("Enter Objective", text: $meetingObjective)
                    .textFieldStyle(.roundedBorder)
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
}

    
