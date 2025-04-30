import SwiftUI
import CoreData

struct AddFollowUpView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCompany: CompanyEntity?
    @State private var selectedOpportunity: OpportunityEntity?
    @State private var showingOpportunitySheet: Bool = false

    @State private var name: String = ""
    @State private var assignedTo: String = ""
    @State private var assignedEmail: String = ""
    @State private var dueDate: Date = .now
    @State private var completed: Bool = false
    @State private var searchText: String = ""
    @State private var isShowingContactPicker: Bool = false
    @State private var isShowingCompanyPicker: Bool = false
    @State private var isShowingOpportunityPicker: Bool = false

    @FetchRequest(entity: CompanyEntity.entity(), sortDescriptors: []) var companies: FetchedResults<CompanyEntity>
    @FetchRequest(entity: ContactsEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \ContactsEntity.lastName, ascending: true)]) var contacts: FetchedResults<ContactsEntity>

    var body: some View {
        NavigationStack {
            Form {
                companySection
                opportunitySection
                detailsSection
                saveButtonSection
            }
            .navigationTitle("New Follow Up")
        }
        .sheet(isPresented: $isShowingContactPicker) {
            ContactPickerView(assignedTo: $assignedTo, assignedEmail: $assignedEmail, isPresented: $isShowingContactPicker, contacts: contacts)
        }
        .sheet(isPresented: $isShowingCompanyPicker) {
            NavigationView {
                List {
                    ForEach(companies, id: \.self) { company in
                        Button(action: {
                            selectedCompany = company
                            selectedOpportunity = nil
                            isShowingCompanyPicker = false
                        }) {
                            Text(company.name ?? "Unknown")
                        }
                    }
                }
                .navigationTitle("Select Company")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingCompanyPicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingOpportunityPicker) {
            if let company = selectedCompany {
                let opportunities = company.opportunities?.allObjects as? [OpportunityEntity] ?? []
                NavigationView {
                    List {
                        ForEach(opportunities, id: \.self) { opportunity in
                            Button(action: {
                                selectedOpportunity = opportunity
                                isShowingOpportunityPicker = false
                            }) {
                                Text(opportunity.name ?? "Untitled")
                            }
                        }
                    }
                    .navigationTitle("Select Opportunity")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingOpportunityPicker = false
                            }
                        }
                    }
                }
            }
        }
    }

    private var companySection: some View {
        Section(header: Text("Select Company")) {
            Button(action: {
                isShowingCompanyPicker = true
            }) {
                HStack {
                    Text("Company")
                    Spacer()
                    Text(selectedCompany?.name ?? "None")
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    @ViewBuilder
    private var opportunitySection: some View {
        if selectedCompany != nil {
            Section(header: Text("Select Opportunity")) {
                Button(action: {
                    isShowingOpportunityPicker = true
                }) {
                    HStack {
                        Text("Opportunity")
                        Spacer()
                        Text(selectedOpportunity?.name ?? "None")
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var detailsSection: some View {
        Group {
            Section(header: Text("Follow Up Details")) {
                TextField("Name", text: $name)
            }
            Section {
                Button("TEST Picker Button") {
                    isShowingContactPicker = true
                }
            }
            // Explicitly use a Button row for "Assigned To" and force SwiftUI to treat as button, not TextField
            Section {
                Button(action: {
                    print("Tapped Assigned To")
                    isShowingContactPicker = true
                }) {
                    HStack {
                        Text("Assigned To")
                        Spacer()
                        Text(assignedTo.isEmpty ? "Select Contact" : assignedTo)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            Section {
                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                Toggle("Completed", isOn: $completed)
            }
        }
    }

    private var saveButtonSection: some View {
        Section {
            Button("Save") {
                saveFollowUp(dismissAfterSave: true)
            }
            Button("Save and Email") {
                // Only trigger if email exists (button will be disabled otherwise)
                saveFollowUp(dismissAfterSave: false)
                // After save, open email if assignedEmail is available
                if !assignedEmail.isEmpty {
                    if let emailUrl = createEmailUrl(to: assignedEmail, subject: "Follow Up: \(name)", body: "") {
                        UIApplication.shared.open(emailUrl)
                    }
                }
            }
            .disabled(assignedEmail.isEmpty)
        }
    }

    private func saveFollowUp(dismissAfterSave: Bool = true) {
        let newFollowUp = FollowUpsEntity(context: viewContext)
        newFollowUp.name = name
        newFollowUp.assignedTo = assignedTo
        newFollowUp.dueDate = dueDate
        newFollowUp.completed = completed
        newFollowUp.id = UUID()
        newFollowUp.opportunity = selectedOpportunity

        do {
            try viewContext.save()
            // Reset form fields after saving
            name = ""
            assignedTo = ""
            assignedEmail = ""
            dueDate = Date()
            completed = false
            selectedCompany = nil
            selectedOpportunity = nil
            if dismissAfterSave {
                dismiss()
            }
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }

    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let companyName = selectedCompany?.name ?? "your company"
        let opportunityName = selectedOpportunity?.name ?? "the opportunity"

        let fullBody = """
        Dear \(assignedTo),

        This is a follow-up regarding "\(name)" for \(companyName), specifically related to \(opportunityName).
        The due date for this follow-up is \(dueDate.formatted(date: .long, time: .omitted)).

        Please take the necessary actions and update the status accordingly.

        Best regards,
        """

        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = fullBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        return URL(string: urlString)
    }
}

private struct ContactPickerView: View {
    @Binding var assignedTo: String
    @Binding var assignedEmail: String
    @Binding var isPresented: Bool
    let contacts: FetchedResults<ContactsEntity>

    @State private var searchText: String = ""

    private var filteredContacts: [ContactsEntity] {
        if searchText.isEmpty {
            return Array(contacts)
        } else {
            return contacts.filter {
                ($0.firstName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.lastName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredContacts, id: \.objectID) { contact in
                    Button(action: {
                        assignedTo = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
                        assignedEmail = contact.emailAddress ?? ""
                        isPresented = false
                    }) {
                        contactRow(for: contact)
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func contactRow(for contact: ContactsEntity) -> some View {
        VStack(alignment: .leading) {
            Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
            Text(contact.emailAddress ?? "")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}
