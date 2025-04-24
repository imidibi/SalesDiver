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
    @State private var dueDate: Date = .now
    @State private var completed: Bool = false
    @State private var searchText: String = ""

    @FetchRequest(entity: CompanyEntity.entity(), sortDescriptors: []) var companies: FetchedResults<CompanyEntity>

    var body: some View {
        NavigationView {
            Form {
                companySection
                opportunitySection
                detailsSection
                saveButtonSection
            }
            .navigationTitle("New Follow Up")
        }
    }

    private var companySection: some View {
        let filteredCompanies = companies.filter {
            searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false)
        }

        return Section(header: Text("Select Company")) {
            Picker("Company", selection: $selectedCompany) {
                ForEach(filteredCompanies, id: \.self) { company in
                    Text(company.name ?? "Unknown")
                }
            }
            TextField("Search", text: $searchText)
        }
    }

    @ViewBuilder
    private var opportunitySection: some View {
        if let company = selectedCompany {
            let opportunities = company.opportunities?.allObjects as? [OpportunityEntity] ?? []

            Section(header: Text("Select Opportunity")) {
                Button(action: {
                    showingOpportunitySheet = true
                }) {
                    HStack {
                        Text("Opportunity")
                        Spacer()
                        Text(selectedOpportunity?.name ?? "None")
                            .foregroundColor(.gray)
                    }
                }
                .sheet(isPresented: $showingOpportunitySheet) {
                    NavigationView {
                        List {
                            ForEach(opportunities, id: \.self) { opportunity in
                                Button(action: {
                                    selectedOpportunity = opportunity
                                    showingOpportunitySheet = false
                                }) {
                                    Text(opportunity.name ?? "Untitled")
                                }
                            }
                        }
                        .navigationTitle("Choose Opportunity")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showingOpportunitySheet = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        Section(header: Text("Follow Up Details")) {
            TextField("Name", text: $name)
            TextField("Assigned To", text: $assignedTo)
            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
            Toggle("Completed", isOn: $completed)
        }
    }

    private var saveButtonSection: some View {
        Section {
            Button("Save") {
                let newFollowUp = FollowUpsEntity(context: viewContext)
                newFollowUp.name = name
                newFollowUp.assignedTo = assignedTo
                newFollowUp.dueDate = dueDate
                newFollowUp.completed = completed
                newFollowUp.id = UUID()
                newFollowUp.opportunity = selectedOpportunity

                do {
                    try viewContext.save()
                    dismiss()
                } catch {
                    print("Save failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
