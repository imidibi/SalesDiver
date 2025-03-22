//
//  PlanMeetingView.swift
//  SalesDiver
//
//  Created by Ian Miller on 3/22/25.
//

import SwiftUI
import CoreData

struct PlanMeetingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var meetingTitle: String = ""
    @State private var meetingDate: Date = Date()
    @State private var selectedCompany: CompanyEntity?
    @State private var selectedOpportunity: OpportunityEntity?
    @State private var selectedAttendees: Set<ContactsEntity> = []
    @State private var meetingObjective: String = ""
    
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
            Form {
                Section(header: Text("Meeting Details")) {
                    TextField("Meeting Title", text: $meetingTitle)
                    
                    DatePicker("Meeting Date", selection: $meetingDate, displayedComponents: .date)
                }
                
                Section(header: Text("Company")) {
                    Picker("Select Company", selection: $selectedCompany) {
                        ForEach(companies, id: \.self) { company in
                            Text(company.name ?? "Unknown").tag(company as CompanyEntity?)
                        }
                    }
                }
                
                if selectedCompany != nil {
                    Section(header: Text("Opportunity")) {
                        Picker("Select Opportunity", selection: $selectedOpportunity) {
                            ForEach(filteredOpportunities, id: \.self) { opportunity in
                                Text(opportunity.name ?? "Untitled").tag(opportunity as OpportunityEntity?)
                            }
                        }
                    }
                    
                    Section(header: Text("Attendees")) {
                        ForEach(filteredContacts, id: \.self) { contact in
                            let firstName = contact.value(forKey: "firstName") as? String ?? ""
                            let lastName = contact.value(forKey: "lastName") as? String ?? ""
                            let fullName = "\(firstName) \(lastName)"
                            let isSelected = selectedAttendees.contains(contact)
                            
                            MultipleSelectionRow(title: fullName, isSelected: isSelected) {
                                selectedAttendees.formSymmetricDifference([contact])
                            }
                        }
                    }
                }
                
                Section(header: Text("Meeting Objective")) {
                    TextField("Enter Objective", text: $meetingObjective)
                }
            }
            .navigationTitle("Plan Meeting")
            .navigationBarItems(trailing: Button("Save") {
                saveMeeting()
            })
        }
    }
    
    func saveMeeting() {
        let newMeeting = MeetingsEntity(context: viewContext)
        
        // Assign properties
        newMeeting.title = meetingTitle
        newMeeting.date = meetingDate
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
