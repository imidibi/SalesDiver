//
//  ContactsView.swift
//  SalesDiver
//
//  Created by Ian Miller on 3/9/25.
//
import SwiftUI
import CoreData

struct ContactsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ContactsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ContactsEntity.firstName, ascending: true), NSSortDescriptor(keyPath: \ContactsEntity.lastName, ascending: true)]
    ) var contacts: FetchedResults<ContactsEntity>
    
    @State private var searchText = ""
    @State private var showingAddContact = false
    
    var filteredContacts: [ContactsEntity] {
        contacts.filter { contact in
            searchText.isEmpty || contact.firstName?.localizedCaseInsensitiveContains(searchText) == true || contact.lastName?.localizedCaseInsensitiveContains(searchText) == true || contact.emailAddress?.localizedCaseInsensitiveContains(searchText) == true || contact.phone?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                
                List {
                    ForEach(filteredContacts, id: \.self) { contact in
                        Text("\(contact.firstName ?? "Unknown") \(contact.lastName ?? "")")
                    }
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                showingAddContact = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddContact) {
                AddContactView(viewContext: viewContext)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContactsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsView()
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        TextField("Search", text: $text)
            .padding(7)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
    }
}

struct AddContactView: View {
    let viewContext: NSManagedObjectContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var emailAddress: String = ""
    @State private var phone: String = ""
    @State private var title: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = ""
    @State private var selectedCompany: CompanyEntity? // Assuming CompanyEntity is the entity for companies
    @State private var companies: [CompanyEntity] = []
    
    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: CompanySelectorView(selectedCompany: $selectedCompany, companies: $companies)) {
                    Text("Company: \(selectedCompany?.name ?? "Select a company")")
                }
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Email Address", text: $emailAddress)
                TextField("Phone", text: $phone)
                TextField("Title", text: $title)
                TextField("Address 1", text: $address1)
                TextField("Address 2", text: $address2)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Postal Code", text: $postalCode)
                TextField("Country", text: $country)
            }
            .navigationTitle("Add Contact")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                guard !firstName.isEmpty, !lastName.isEmpty else {
                    print("Error: Required fields 'First Name' and 'Last Name' must not be empty.")
                    return
                }
                let newContact = ContactsEntity(context: viewContext)
                newContact.id = UUID() // Ensure id is initialized with a UUID
                newContact.firstName = firstName
                newContact.lastName = lastName
                newContact.emailAddress = emailAddress
                newContact.phone = phone
                newContact.title = title
                newContact.address1 = address1
                newContact.address2 = address2
                newContact.city = city
                newContact.state = state
                newContact.postalCode = postalCode
                newContact.country = country
                
                if let company = selectedCompany {
                    newContact.company = company
                }

                do {
                    try viewContext.save()
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Failed to save contact: \(error.localizedDescription)")
                }
            })
        }
        .onAppear {
            fetchCompanies()
        }
    }
    
    private func fetchCompanies() {
        companies = CoreDataManager.shared.fetchCompanies() // Updated the call to match the function definition
    }
}

struct CompanySelectorView: View {
    @Binding var selectedCompany: CompanyEntity?
    @Binding var companies: [CompanyEntity]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            List {
                ForEach(filteredCompanies, id: \.self) { company in
                    Button(action: {
                        selectedCompany = company
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(company.name ?? "Unknown")
                    }
                }
            }
        }
        .navigationTitle("Select Company")
    }
    
    private var filteredCompanies: [CompanyEntity] {
        companies.filter { company in
            searchText.isEmpty || company.name?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}
