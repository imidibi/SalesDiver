import Foundation
import CoreData
import SwiftUI

class OpportunityViewModel: ObservableObject {
    @Published var opportunities: [OpportunityWrapper] = []
    
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .companyName
    
    enum SortOption {
        case companyName, opportunityName, closeDate
    }
    
    private let context = CoreDataManager.shared.context

    init() {
        fetchOpportunities()
    }

    func fetchOpportunities() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "OpportunityEntity")
        do {
            let fetchedOpportunities = try context.fetch(request)
            self.opportunities = fetchedOpportunities.map { OpportunityWrapper(managedObject: $0) }
        } catch {
            print("❌ Error fetching opportunities: \(error)")
        }
    }

    var filteredOpportunities: [OpportunityWrapper] {
        let filtered = opportunities.filter {
            $0.companyName.lowercased().contains(searchText.lowercased())
        }
        
        switch sortOption {
        case .companyName:
            return filtered.sorted { $0.companyName < $1.companyName }
        case .opportunityName:
            return filtered.sorted { $0.name < $1.name }
        case .closeDate:
            return filtered.sorted { $0.closeDate < $1.closeDate }
        }
    }
    
    func addOpportunity(name: String, closeDate: Date, company: CompanyWrapper, product: ProductWrapper, quantity: Int, customPrice: Double) {
        let entity = NSEntityDescription.entity(forEntityName: "OpportunityEntity", in: context)!
        let newOpportunity = NSManagedObject(entity: entity, insertInto: context)

        newOpportunity.setValue(name, forKey: "name")
        newOpportunity.setValue(closeDate, forKey: "closeDate")
        newOpportunity.setValue(company.managedObject, forKey: "company")
        newOpportunity.setValue(product.managedObject, forKey: "product")
        newOpportunity.setValue(quantity, forKey: "quantity")
        newOpportunity.setValue(customPrice, forKey: "customPrice")

        newOpportunity.setValue(0, forKey: "budgetStatus")
        newOpportunity.setValue(0, forKey: "authorityStatus")
        newOpportunity.setValue(0, forKey: "needStatus")
        newOpportunity.setValue(0, forKey: "timingStatus")
        
        newOpportunity.setValue("", forKey: "budgetCommentary")
        newOpportunity.setValue("", forKey: "authorityCommentary")
        newOpportunity.setValue("", forKey: "needCommentary")
        newOpportunity.setValue("", forKey: "timingCommentary")

        saveData()
    }
    
    func updateOpportunity(opportunity: OpportunityWrapper, name: String, closeDate: Date, quantity: Int, customPrice: Double) {
        opportunity.managedObject.setValue(name, forKey: "name")
        opportunity.managedObject.setValue(closeDate, forKey: "closeDate")
        opportunity.managedObject.setValue(quantity, forKey: "quantity")
        opportunity.managedObject.setValue(customPrice, forKey: "customPrice")

        saveData()
    }

    func updateBANT(opportunity: OpportunityWrapper, bantType: BANTIndicatorView.BANTType, status: Int, commentary: String) {
        switch bantType {
        case .budget:
            opportunity.managedObject.setValue(status, forKey: "budgetStatus")
            opportunity.managedObject.setValue(commentary, forKey: "budgetCommentary")
        case .authority:
            opportunity.managedObject.setValue(status, forKey: "authorityStatus")
            opportunity.managedObject.setValue(commentary, forKey: "authorityCommentary")
        case .need:
            opportunity.managedObject.setValue(status, forKey: "needStatus")
            opportunity.managedObject.setValue(commentary, forKey: "needCommentary")
        case .timing:
            opportunity.managedObject.setValue(status, forKey: "timingStatus")
            opportunity.managedObject.setValue(commentary, forKey: "timingCommentary")
        }

        saveData()
    }

    func deleteOpportunity(opportunity: OpportunityWrapper) {
        context.delete(opportunity.managedObject)
        saveData()
    }

    private func saveData() {
        do {
            try context.save()
            fetchOpportunities()
        } catch {
            print("❌ Error saving opportunity: \(error)")
        }
    }
}
