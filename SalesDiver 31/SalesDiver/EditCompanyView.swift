//
//  EditCompanyView.swift
//  SalesDiver
//
//  Created by Ian Miller on 2/19/25.
//
import SwiftUI

struct EditCompanyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var company: Company
    
    @State private var name: String
    @State private var addressLine1: String
    @State private var addressLine2: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String

    init(company: Company) {
        self.company = company
        _name = State(initialValue: company.name ?? "")
        _addressLine1 = State(initialValue: company.addressLine1 ?? "")
        _addressLine2 = State(initialValue: company.addressLine2 ?? "")
        _city = State(initialValue: company.city ?? "")
        _state = State(initialValue: company.state ?? "")
        _zipCode = State(initialValue: company.zipCode ?? "")
    }

    var body: some View {
        Form {
            Section(header: Text("Company Details")) {
                TextField("Company Name", text: $name)
            }

            Section(header: Text("Address")) {
                TextField("Address Line 1", text: $addressLine1)
                TextField("Address Line 2", text: $addressLine2)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip Code", text: $zipCode)
            }

            Section {
                Button(action: saveCompany) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Edit Company")
    }

    private func saveCompany() {
        company.name = name
        company.addressLine1 = addressLine1
        company.addressLine2 = addressLine2
        company.city = city
        company.state = state
        company.zipCode = zipCode

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving company: \(error)")
        }
    }
}
