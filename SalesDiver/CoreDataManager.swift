import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "CompanyDataModel")
        persistentContainer.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Unresolved error \(error)")
            }
        }
    }
    
    func syncCompaniesFromAutotask(companies: [(name: String, address1: String?, address2: String?, city: String?, state: String?)]) {
        let context = persistentContainer.viewContext
        
        for company in companies {
            let fetchRequest: NSFetchRequest<CompanyEntity> = CompanyEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", company.name)
            
            do {
                let results = try context.fetch(fetchRequest)
                let companyEntity = results.first ?? CompanyEntity(context: context)
                
                companyEntity.name = company.name
                companyEntity.address = company.address1
                companyEntity.address2 = company.address2
                companyEntity.city = company.city
                companyEntity.state = company.state
                
            } catch {
                print("Error fetching company: \(error)")
            }
        }
        
        saveContext()
    }
    
    func fetchSecurityAssessments(for company: CompanyEntity) -> [SecAssessEntity] {
        let request: NSFetchRequest<SecAssessEntity> = SecAssessEntity.fetchRequest()

        guard let companyName = company.name, !companyName.isEmpty else {
            print("❌ Error: Company Name is nil or invalid")
            return []
        }
        
        request.predicate = NSPredicate(format: "company.name == %@", companyName)
        request.sortDescriptors = [NSSortDescriptor(key: "assessDate", ascending: false)]

        do {
            let assessments = try context.fetch(request)
        // print("🔍 Fetch Attempt: Looking for assessments for \(companyName)")
        // print("✅ Fetch Success: Found \(assessments.count) assessments for \(companyName)")

            for assessment in assessments {
                // print("📌 Assessment Retrieved - Date: \(assessment.assessDate ?? Date()) | MFA: \(assessment.mfa) | Encryption: \(assessment.encryption) | Backup: \(assessment.backup)")
            }

            return assessments
        } catch {
            print("❌ Fetch Error: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveSecurityAssessment(for company: CompanyEntity, assessmentData: [SecurityAssessmentView.Status]) {
        let newAssessment = SecAssessEntity(context: context)
        newAssessment.id = UUID()
        newAssessment.assessDate = Date()
        
        newAssessment.company = company
        // print("✅ Linking assessment to company \(company.name ?? "Unknown")")
        
        newAssessment.secAssess = assessmentData[0].rawValue
        newAssessment.secAware = assessmentData[1].rawValue
        newAssessment.darkWeb = assessmentData[2].rawValue
        newAssessment.backup = assessmentData[3].rawValue
        newAssessment.emailProtect = assessmentData[4].rawValue
        newAssessment.advancedEDR = assessmentData[5].rawValue
        newAssessment.mobDevice = assessmentData[6].rawValue
        newAssessment.phySec = assessmentData[7].rawValue
        newAssessment.passwords = assessmentData[8].rawValue
        newAssessment.siemSoc = assessmentData[9].rawValue
        newAssessment.firewall = assessmentData[10].rawValue
        newAssessment.dnsProtect = assessmentData[11].rawValue
        newAssessment.mfa = assessmentData[12].rawValue
        newAssessment.compUpdates = assessmentData[13].rawValue
        newAssessment.encryption = assessmentData[14].rawValue
        newAssessment.cyberInsurance = assessmentData[15].rawValue
        
        do {
            let companyName = company.name ?? "Unknown"
            try context.save()
            // print("✅ Security assessment saved successfully for company: \(companyName)")
            // print("📅 Date: \(newAssessment.assessDate ?? Date())")
            // print("🔍 Status Values:")
            // print(" - Security Assessment: \(newAssessment.secAssess)")
            // print(" - Security Awareness: \(newAssessment.secAware)")
            // print(" - Dark Web Research: \(newAssessment.darkWeb)")
            // print(" - Backup: \(newAssessment.backup)")
            // print(" - Email Protection: \(newAssessment.emailProtect)")
            // print(" - Advanced EDR: \(newAssessment.advancedEDR)")
            // print(" - Mobile Device Security: \(newAssessment.mobDevice)")
            // print(" - Physical Security: \(newAssessment.phySec)")
            // print(" - Passwords: \(newAssessment.passwords)")
            // print(" - SIEM & SOC: \(newAssessment.siemSoc)")
            // print(" - Firewall: \(newAssessment.firewall)")
            // print(" - DNS Protection: \(newAssessment.dnsProtect)")
            // print(" - Multi-Factor Authentication: \(newAssessment.mfa)")
            // print(" - Computer Updates: \(newAssessment.compUpdates)")
            // print(" - Encryption: \(newAssessment.encryption)")
            // print(" - Cyber Insurance: \(newAssessment.cyberInsurance)")
        } catch {
            print("❌ Failed to save security assessment: \(error.localizedDescription)")
        }
    }
    
    func deleteSecurityAssessment(_ assessment: SecAssessEntity) {
        context.delete(assessment)
        do {
            try context.save()
            print("Security assessment deleted successfully.")
        } catch {
            print("Failed to delete security assessment: \(error)")
        }
    }
    
    func fetchCompanyByName(name: String) -> CompanyEntity? {
        let request: NSFetchRequest<CompanyEntity> = CompanyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", name.trimmingCharacters(in: .whitespacesAndNewlines))
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch company: \(error)")
            return nil
        }
    }
    
    func debugFetchAllAssessments() {
        let request: NSFetchRequest<SecAssessEntity> = SecAssessEntity.fetchRequest()
        
        do {
            let assessments = try context.fetch(request)
            // print("🔍 Total Security Assessments in Core Data: \(assessments.count)")
            for assessment in assessments {
                let companyName = assessment.company?.name ?? "Unknown"
                // print("✅ Assessment for Company: \(companyName) | Date: \(assessment.assessDate ?? Date())")
                // print("🔹 MFA: \(assessment.mfa) | Encryption: \(assessment.encryption) | Backup: \(assessment.backup)")
            }
        } catch {
            print("❌ Fetch All Assessments Error: \(error.localizedDescription)")
        }
    }
}
