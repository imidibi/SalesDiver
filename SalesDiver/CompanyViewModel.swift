//
//  CompanyViewModel.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//
import Foundation
import CoreData

class CompanyViewModel: ObservableObject {
    @Published var companies: [CompanyWrapper] = [] // ✅ Uses a wrapper instead of NSManagedObject

    private let context = CoreDataManager.shared.context

    init() {
        fetchCompanies()
    }

    func fetchCompanies() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CompanyEntity")
        do {
            let fetchedCompanies = try context.fetch(request)
            self.companies = fetchedCompanies.map { CompanyWrapper(managedObject: $0) }
        } catch {
            print("Error fetching companies: \(error)")
        }
    }

    func addCompany(name: String, address: String, address2: String, city: String, state: String, zipCode: String, mainContact: String) {
        let entity = NSEntityDescription.entity(forEntityName: "CompanyEntity", in: context)!
        let newCompany = NSManagedObject(entity: entity, insertInto: context)

        newCompany.setValue(name, forKey: "name")
        newCompany.setValue(address, forKey: "address")
        newCompany.setValue(address2, forKey: "address2")
        newCompany.setValue(city, forKey: "city")
        newCompany.setValue(state, forKey: "state")
        newCompany.setValue(zipCode, forKey: "zipCode")
        newCompany.setValue(mainContact, forKey: "mainContact")

        saveData()
    }

    func updateCompany(company: CompanyWrapper, name: String, address: String, address2: String, city: String, state: String, zipCode: String, mainContact: String) {
        company.managedObject.setValue(name, forKey: "name")
        company.managedObject.setValue(address, forKey: "address")
        company.managedObject.setValue(address2, forKey: "address2")
        company.managedObject.setValue(city, forKey: "city")
        company.managedObject.setValue(state, forKey: "state")
        company.managedObject.setValue(zipCode, forKey: "zipCode")
        company.managedObject.setValue(mainContact, forKey: "mainContact")

        saveData()
    }

    func deleteCompany(company: CompanyWrapper) {
        context.delete(company.managedObject) // ✅ Delete the actual NSManagedObject inside CompanyWrapper
        saveData()
    }

    private func saveData() {
        do {
            try context.save()
            fetchCompanies()
        } catch {
            print("Error saving company data: \(error)")
        }
    }
}

// MARK: - Wrapper for Identifiable Compliance
struct CompanyWrapper: Identifiable, Hashable {
    let managedObject: NSManagedObject

    var id: NSManagedObjectID { managedObject.objectID }

    var name: String {
        managedObject.value(forKey: "name") as? String ?? ""
    }

    var address: String {
        managedObject.value(forKey: "address") as? String ?? ""
    }
    var address2: String {
        managedObject.value(forKey: "address2") as? String ?? ""
    }
    
    var city: String {
        managedObject.value(forKey: "city") as? String ?? ""
    }
    var state: String {
        managedObject.value(forKey: "state") as? String ?? ""
    }
    var zipCode: String {
        managedObject.value(forKey: "zipCode") as? String ?? ""
    }

    var mainContact: String {
        managedObject.value(forKey: "mainContact") as? String ?? ""
    }

    // ✅ Conform to Hashable
    static func == (lhs: CompanyWrapper, rhs: CompanyWrapper) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

