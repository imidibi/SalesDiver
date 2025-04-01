import Foundation
import CoreData

class OpportunityWrapper: ObservableObject, Identifiable {
    @Published var managedObject: NSManagedObject

    init(managedObject: NSManagedObject) {
        self.managedObject = managedObject
    }

    var id: NSManagedObjectID { managedObject.objectID }

    // ✅ Use "name" for Opportunity
    var name: String {
        managedObject.value(forKey: "name") as? String ?? "Unnamed Opportunity"
    }

    var closeDate: Date {
        managedObject.value(forKey: "closeDate") as? Date ?? Date()
    }

    // ✅ Use "name" from associated CompanyEntity
    var companyName: String {
        (managedObject.value(forKey: "company") as? NSManagedObject)?
            .value(forKey: "name") as? String ?? "Unknown Company"
    }

    // ✅ Use "name" from associated ProductEntity
    var productName: String {
        (managedObject.value(forKey: "product") as? NSManagedObject)?
            .value(forKey: "name") as? String ?? "Unknown Product"
    }

    // ✅ Quantity & Price
    var quantity: Int {
        managedObject.value(forKey: "quantity") as? Int ?? 0
    }

    var customPrice: Double {
        managedObject.value(forKey: "customPrice") as? Double ?? 0.0
    }

    // ✅ BANT Qualification Status
    var budgetStatus: Int {
        managedObject.value(forKey: "budgetStatus") as? Int ?? 0
    }

    var authorityStatus: Int {
        managedObject.value(forKey: "authorityStatus") as? Int ?? 0
    }

    var needStatus: Int {
        managedObject.value(forKey: "needStatus") as? Int ?? 0
    }

    var timingStatus: Int {
        managedObject.value(forKey: "timingStatus") as? Int ?? 0
    }

    // ✅ BANT Qualification Commentary
    var budgetCommentary: String {
        managedObject.value(forKey: "budgetCommentary") as? String ?? ""
    }

    var authorityCommentary: String {
        managedObject.value(forKey: "authorityCommentary") as? String ?? ""
    }

    var needCommentary: String {
        managedObject.value(forKey: "needCommentary") as? String ?? ""
    }

    var timingCommentary: String {
        managedObject.value(forKey: "timingCommentary") as? String ?? ""
    }
}
