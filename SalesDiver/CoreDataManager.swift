import CoreData

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "CompanyDataModel")
        persistentContainer.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                print("❌ Failed to load Core Data: \(error), \(error.userInfo)")
            }
        }
        fetchEntityDescriptions()
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Unresolved error \(error)")
            }
        }
    }
    
    func syncCompaniesFromAutotask(companies: [(name: String, address1: String?, address2: String?, city: String?, state: String?, zipCode: String?)]) {
        let context = persistentContainer.viewContext
        
        for company in companies {
            let fetchRequest: NSFetchRequest<CompanyEntity> = CompanyEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", company.name)
            
            do {
                let results = try context.fetch(fetchRequest)
                let companyEntity = results.first ?? CompanyEntity(context: context)
                
                companyEntity.name = company.name
                companyEntity.address = company.address1
                companyEntity.address2 = company.address2
                companyEntity.city = company.city
                companyEntity.state = company.state
                companyEntity.zipCode = company.zipCode
                
            } catch {
                print("Error fetching company: \(error)")
            }
        }
        
        saveContext()
    }
    
    func fetchCompanies() -> [CompanyEntity] {
        let request: NSFetchRequest<CompanyEntity> = CompanyEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch companies: \(error)")
            return []
        }
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
            try context.save()
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
            _ = try context.fetch(request)
        } catch {
            print("❌ Fetch All Assessments Error: \(error.localizedDescription)")
        }
    }
    
    func importContacts(contacts: [String], company: CompanyEntity) {
        let context = persistentContainer.viewContext
        for contactName in contacts {
            let nameComponents = contactName.split(separator: " ", maxSplits: 1).map { String($0) }
            let firstName = nameComponents.first ?? ""
            let lastName = nameComponents.count > 1 ? nameComponents[1] : ""
            
            let fetchRequest: NSFetchRequest<ContactsEntity> = ContactsEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "firstName ==[c] %@ AND lastName ==[c] %@", firstName.trimmingCharacters(in: .whitespacesAndNewlines), lastName.trimmingCharacters(in: .whitespacesAndNewlines))
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.isEmpty {
                    let newContact = ContactsEntity(context: context)
                    newContact.id = UUID()
                    newContact.firstName = firstName
                    newContact.lastName = lastName
                    newContact.company = company  // Link the contact to the existing company
                }
            } catch {
                print("Error fetching contact: \(error)")
            }
        }
        saveContext()
    }
    
    func fetchOrCreateCompany(companyID: Int, companyName: String? = nil, completion: @escaping (CompanyEntity) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<CompanyEntity> = CompanyEntity.fetchRequest()

        // Search by name only
        if let companyName = companyName {
            fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", companyName)
        }
        
        do {
            if let existingCompany = try context.fetch(fetchRequest).first {
                // ✅ Update the Autotask CompanyID if it's missing or different
                if existingCompany.id == 0 {
                    existingCompany.id = Int64(companyID)
                    try context.save()
                }
                completion(existingCompany)
            } else {
                // No existing company found, create a new one
                let newCompany = CompanyEntity(context: context)
                newCompany.id = Int64(companyID)  // Store the Autotask CompanyID
                newCompany.name = companyName
                try context.save()
                completion(newCompany)
            }
        } catch {
            print("❌ Failed to fetch or create company: \(error)")
        }
    }

    func fetchEntityDescriptions() {
        let context = persistentContainer.viewContext
        let model = context.persistentStoreCoordinator?.managedObjectModel

        if let entities = model?.entities {
            for entity in entities {
                print("✅ Loaded entity: \(entity.name ?? "Unnamed Entity")")
            }
        } else {
            print("❌ No entities found in the Core Data model.")
        }
    }

    func fetchOpportunities(for company: CompanyEntity) -> [OpportunityEntity] {
        let request: NSFetchRequest<OpportunityEntity> = OpportunityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "company == %@", company)
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching opportunities: \(error)")
            return []
        }
    }

    func fetchContacts(for company: CompanyEntity) -> [ContactsEntity] {
        let request: NSFetchRequest<ContactsEntity> = ContactsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "company == %@", company)
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching contacts: \(error)")
            return []
        }
    }

    func fetchMeetings(for company: CompanyEntity) -> [MeetingsEntity] {
        let request: NSFetchRequest<MeetingsEntity> = MeetingsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "company == %@", company)
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching meetings: \(error)")
            return []
        }
    }

    func deleteCompany(company: CompanyEntity) {
        let opportunities = fetchOpportunities(for: company)
        let meetings = fetchMeetings(for: company)
        let contacts = fetchContacts(for: company)

        if !opportunities.isEmpty || !meetings.isEmpty || !contacts.isEmpty {
            print("❌ Linked data - cannot delete company")
            return
        }
        
        context.delete(company)
        saveContext()
        print("✅ Company deleted successfully.")
    }

    func saveMeeting(meeting: MeetingsEntity) {
        do {
            try context.save()
            print("✅ Meeting successfully saved!")
        } catch {
            print("❌ Failed to save meeting: \(error)")
        }
    }

    func saveAssessmentFields(for company: String, category: String, fields: [(String, String?, Bool?)]) {
        let normalizedCompanyName = company.trimmingCharacters(in: .whitespacesAndNewlines)
        let request: NSFetchRequest<AssessmentEntity> = AssessmentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "companyName == %@", normalizedCompanyName)

        let assessment: AssessmentEntity
        if let existing = try? context.fetch(request).first {
            assessment = existing
        } else {
            assessment = AssessmentEntity(context: context)
            assessment.id = UUID()
            assessment.date = Date()
            assessment.companyName = normalizedCompanyName
        }
        print("💾 Attempting to save assessment for: \(company)")
 
        // Only delete existing fields in the matching category
        if let existingFields = assessment.fields as? Set<AssessmentFieldEntity> {
            for field in existingFields {
                if field.category == category {
                    print("🗑 Deleting old field in category '\(category)': \(field.fieldName ?? "Unnamed")")
                    context.delete(field)
                }
            }
        }
 
        for field in fields {
            let newField = AssessmentFieldEntity(context: context)
            newField.id = UUID()
            newField.assessment = assessment
            newField.fieldName = field.0
            newField.category = category // Ensure this is always set

            if let stringValue = field.1, !stringValue.isEmpty {
                newField.valueString = stringValue
            }
            if let boolValue = field.2 {
                newField.valueString = boolValue ? "true" : "false"
            }
            if let numericValue = field.1, let doubleValue = Double(numericValue) {
                newField.valueNumber = doubleValue
            } else {
                newField.valueNumber = 0.0
            }
 
            print("   - Field: \(newField.fieldName ?? "(unnamed)"), ValueNumber: \(newField.valueNumber), Managed: \(newField.valueString ?? "nil")")
        }
 
        saveContext()
        context.refresh(assessment, mergeChanges: true)
        print("✅ Assessment fields saved successfully for company: \(company)")
    }

    func loadAssessmentFields(for company: String, category: String) -> [AssessmentFieldEntity] {
        let request: NSFetchRequest<AssessmentEntity> = AssessmentEntity.fetchRequest()
        let normalizedCompanyName = company.trimmingCharacters(in: .whitespacesAndNewlines)
        request.predicate = NSPredicate(format: "companyName == %@", normalizedCompanyName)

        guard let assessment = try? context.fetch(request).first,
              let fieldSet = assessment.fields as? Set<AssessmentFieldEntity> else {
            return []
        }

        print("📥 Loading saved \(category) assessment for: \(company)")
        print("✅ Loaded assessment for company: \(company)")
        print("🧠 Loaded assessment: \(company) with \(fieldSet.count) total fields")

        for field in fieldSet {
            print("🔍 Inspecting field: \(field.fieldName ?? "(unknown)"), valueNumber: \(field.valueNumber), valueString: \(field.valueString ?? "nil")")
        }

        let filteredFields = fieldSet.filter { $0.category == category }
        return Array(filteredFields)
    }
    
    func loadAllAssessmentFields(for company: String, category: String? = nil) -> [AssessmentFieldEntity] {
        let request: NSFetchRequest<AssessmentEntity> = AssessmentEntity.fetchRequest()
        let normalizedCompanyName = company.trimmingCharacters(in: .whitespacesAndNewlines)
        request.predicate = NSPredicate(format: "companyName == %@", normalizedCompanyName)

        guard let assessment = try? context.fetch(request).first,
              let fieldSet = assessment.fields as? Set<AssessmentFieldEntity> else {
            return []
        }

        if let category = category {
            return Array(fieldSet.filter { $0.category == category })
        } else {
            return Array(fieldSet)
        }
    }
}
