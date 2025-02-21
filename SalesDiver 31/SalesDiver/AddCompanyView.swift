import SwiftUI
import CoreData

struct AddCompanyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Company Details")) {
                    TextField("Company Name", text: $name)
                    TextField("Address Line 1", text: $addressLine1)
                    TextField("Address Line 2", text: $addressLine2)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Zip Code", text: $zipCode)
                }
            }
            .navigationTitle("New Company")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addCompany()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func addCompany() {
        let newCompany = Company(context: viewContext)
        newCompany.name = name
        newCompany.addressLine1 = addressLine1
        newCompany.addressLine2 = addressLine2
        newCompany.city = city
        newCompany.state = state
        newCompany.zipCode = zipCode
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving company: \(error)")
        }
    }
}
