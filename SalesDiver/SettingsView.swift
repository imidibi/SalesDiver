import SwiftUI

struct Contact: Hashable {
    let firstName: String
    let lastName: String
}

struct SettingsView: View {
    @AppStorage("autotaskEnabled") private var autotaskEnabled = false
    @AppStorage("autotaskAPIUsername") private var apiUsername = ""
    @AppStorage("autotaskAPISecret") private var apiSecret = ""
    @AppStorage("autotaskAPITrackingID") private var apiTrackingID = ""
    
    @State private var testResult: String = ""
    @State private var isTesting = false
    @State private var companyName: String = ""
    @State private var searchResults: [(Int, String)] = []
    @State private var selectedCompanies: Set<String> = []
    @State private var selectedContacts: Set<Contact> = []
    @State private var showAutotaskSettings = false
    @State private var selectedCategory: String = "Company"
    @State private var showContactSearch = false
    @State private var contactName: String = ""
    @State private var selectedCompanyID: Int? = nil
    
    private var searchHeaderText: String {
        switch selectedCategory {
        case "Contact":
            return "Search Contacts in Autotask"
        case "Opportunity":
            return "Search Opportunities in Autotask"
        case "Product":
            return "Search Products in Autotask"
        default:
            return "Search Companies in Autotask"
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    }
    
    private var autotaskIntegrationSection: some View {
        Section(header: Text("Autotask Integration")) {
            Toggle("Enable Autotask API", isOn: $autotaskEnabled)
                .onChange(of: autotaskEnabled) { oldValue, newValue in
                    if newValue {
                        showAutotaskSettings = true  // Show settings when enabling API
                    }
                }

            if autotaskEnabled {
                Toggle("Show Settings", isOn: $showAutotaskSettings)

                if showAutotaskSettings {
                    TextField("API Username", text: $apiUsername)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("API Secret", text: $apiSecret)
                        .textContentType(.password)
                    
                    TextField("Tracking Identifier", text: $apiTrackingID)
                        .autocapitalization(.none)
                }
            }
        }
    }
    
   var body: some View {
        NavigationStack {
            Form {
                autotaskIntegrationSection

                if autotaskEnabled {
                    selectDataTypeSection
                }

                additionalSettingsSections
            }
            .navigationTitle("Settings")
        }
    }

    // Extracted Select Data Type Section
    private var selectDataTypeSection: some View {
        Section(header: Text("Select Data Type")) {
            dataTypeButtonsGrid
                .padding()
        }
    }

    // Extracted LazyVGrid of buttons
    private var dataTypeButtonsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(["Company", "Contact", "Opportunity", "Product"], id: \.self) { category in
                dataTypeButton(for: category)
            }
        }
    }

    // Extracted button view
    private func dataTypeButton(for category: String) -> some View {
        Button(action: {
            handleCategorySelection(category)
        }) {
            Text(category)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedCategory == category ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Extracted button action logic
    private func handleCategorySelection(_ category: String) {
        if selectedCategory != category {
            companyName = ""
            searchResults = []
            selectedCompanies.removeAll()
            showContactSearch = false
        }
        selectedCategory = category
    }

    // Extracted additional settings below main grid
    private var additionalSettingsSections: some View {
        Group {
            if !testResult.isEmpty {
                Section(header: Text("Autotask Sync Status")) {
                    Text(testResult)
                        .foregroundColor(testResult.contains("Failed") || testResult.contains("Error") || testResult.contains("No companies found") ? .red : .primary)
                }
            }

            if autotaskEnabled {
                searchAndResultsSection
            }
        }
    }

    // Extracted search and results section
    private var searchAndResultsSection: some View {
        Section(header: Text(searchHeaderText)) {
            TextField("Enter company name", text: $companyName, onCommit: handleSearchCommit)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if selectedCategory == "Contact", selectedCompanyID != nil {
                contactSearchField
            }

            resultsScrollView

            syncOrImportButton
        }
    }

    // Extracted commit handler
    private func handleSearchCommit() {
        if selectedCategory == "Contact" {
            if !companyName.trimmingCharacters(in: .whitespaces).isEmpty {
                searchCompanyForContacts()
            }
        } else {
            searchCompaniesForSelection()
        }
    }

    // Extracted contact search TextField
    private var contactSearchField: some View {
        TextField("Enter contact name", text: $contactName, onCommit: {
            searchContactsForCompany()
        })
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding(.top, 10)
    }

    // Extracted ScrollView for results
    private var resultsScrollView: some View {
        ScrollView {
            LazyVStack {
                ForEach(searchResults, id: \.0) { company in
                    Text(company.1)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .onTapGesture {
                            handleTap(for: company)
                        }
                        .background(backgroundColor(for: company.1))
                }
            }
        }
        .frame(maxHeight: 300)
    }

    // Extracted Button for sync/import actions
    @ViewBuilder
    private var syncOrImportButton: some View {
        if selectedCategory == "Company", !selectedCompanies.isEmpty {
            Button("Sync with Autotask now") {
                syncWithAutotask()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        } else if selectedCategory == "Contact", selectedCompanyID != nil {
            Button("Import All Contacts") {
                contactName = ""
                AutotaskAPIManager.shared.searchContactsGET(companyID: selectedCompanyID!) { results in
                    DispatchQueue.main.async {
                        searchResults = results
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    private func syncWithAutotask() {
        guard !apiUsername.isEmpty, !apiSecret.isEmpty, !apiTrackingID.isEmpty else {
            testResult = "Please enter API credentials and Tracking ID."
            return
        }
        
        isTesting = true
        testResult = "Syncing with Autotask..."
        
        let apiBaseURL = "https://webservices24.autotask.net/ATServicesRest/V1.0/Companies/query"
        var request = URLRequest(url: URL(string: apiBaseURL)!)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(apiUsername, forHTTPHeaderField: "UserName")
        request.setValue(apiSecret, forHTTPHeaderField: "Secret")
        request.setValue(apiTrackingID, forHTTPHeaderField: "ApiIntegrationCode")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let companyFilters = selectedCompanies.map { company in
            return [
                "op": "contains",
                "field": "companyName",
                "value": company.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            ]
        }
        
        let requestBody: [String: Any] = [
            "MaxRecords": 50,
            "IncludeFields": ["id", "companyName", "address1", "address2", "city", "state", "postalCode", "phone"],
            "Filter": [
                [
                    "op": "or",
                    "items": companyFilters
                ]
            ]
        ]
        
        print("API Request Payload: \(requestBody)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            testResult = "Failed to encode query."
            isTesting = false
            return
        }
        
        print("Sending API Request for Companies: \(selectedCompanies)")
        print("Formatted API Request Body: \(requestBody)")
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTesting = false
                if let error = error {
                    testResult = "Sync Failed: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Full API Response: \(dataString)")
                    }
                    processFetchedCompanies(data)
                } else {
                    testResult = "Failed to authenticate (Unknown status)"
                }
            }
        }.resume()
    }
    
    private func processFetchedCompanies(_ data: Data) {
        do {
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            print("Selected Companies for Sync: \(selectedCompanies)")

            if let companies = jsonResponse?["items"] as? [[String: Any]] {
                print("Fetched Companies from API: \(companies.compactMap { $0["companyName"] as? String })")
                
                var companiesToSync: [(name: String, address1: String?, address2: String?, city: String?, state: String?)] = []
                
                for company in companies {
                    if let name = company["companyName"] as? String {
                        let normalizedFetchedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        let selectedNormalized = selectedCompanies.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

                        if selectedNormalized.contains(normalizedFetchedName) {
                            let address1 = company["address1"] as? String
                            let address2 = company["address2"] as? String
                            let city = company["city"] as? String
                            let state = company["state"] as? String

                            companiesToSync.append((name, address1, address2, city, state))
                        }
                    }
                }
                
                if !companiesToSync.isEmpty {
                    CoreDataManager.shared.syncCompaniesFromAutotask(companies: companiesToSync)
                    testResult = "Synced \(companiesToSync.count) companies successfully."
                } else {
                    testResult = "No companies found matching selection."
                }
                selectedCompanies.removeAll()
            } else {
                testResult = "No companies found."
            }
        } catch {
            testResult = "Error parsing data."
        }
    }
    
    private func searchCompaniesForSelection() {
    let trimmedQuery = companyName.trimmingCharacters(in: .whitespaces)
    guard !trimmedQuery.isEmpty else { return }

    if trimmedQuery == "SyncAllCompanyData" {
        AutotaskAPIManager.shared.getAllCompanies { results in
            DispatchQueue.main.async {
                searchResults = results
                print("Imported all companies: \(results)")
            }
        }
    } else {
        AutotaskAPIManager.shared.searchCompanies(query: trimmedQuery.lowercased()) { results in
            DispatchQueue.main.async {
                searchResults = results.filter { $0.1.lowercased().hasPrefix(trimmedQuery.lowercased()) }
            }
        }
    }
    }

    private func searchCompanyForContacts() {
        let trimmedQuery = companyName.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return }

        AutotaskAPIManager.shared.searchCompanies(query: trimmedQuery) { results in
            DispatchQueue.main.async {
                searchResults = results
            }
        }
    }

    private func searchContactsForCompany() {
        guard let companyID = selectedCompanyID else {
            print("❌ No company selected for contact search.")
            return
        }
        
        print("🔍 Searching contacts for Company ID \(companyID)")

        AutotaskAPIManager.shared.searchContacts(companyID: companyID) { results in
            DispatchQueue.main.async {
                if results.isEmpty {
                    print("⚠️ No contacts found for company ID: \(companyID)")
                } else {
                    print("✅ Found \(results.count) contacts for company ID: \(companyID)")
                }
                searchResults = results.map { ($0.0, "\($0.1) \($0.2)") }
            }
        }
    }

    private func importSelectedContacts() {
        let context = CoreDataManager.shared.persistentContainer.viewContext
        for contact in selectedContacts {
            let newContact = ContactsEntity(context: context)
            newContact.id = UUID()
            newContact.firstName = contact.firstName
            newContact.lastName = contact.lastName
            newContact.companyID = Int64(selectedCompanyID ?? 0)
        }
        CoreDataManager.shared.saveContext()
        print("✅ Successfully imported \(selectedContacts.count) contacts.")
        selectedContacts.removeAll()
    }
    private func filterForCompany(_ company: String) -> [String: String] {
        let trimmed = normalizeCompanyName(company)
        return ["op": "contains", "field": "companyName", "value": trimmed]
    }
    
    private func normalizeCompanyName(_ name: String) -> String {
        return name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
private func handleTap(for company: (Int, String)) {
    if selectedCategory == "Company" {
        let companyNameValue = company.1
        if selectedCompanies.contains(companyNameValue) {
            selectedCompanies.remove(companyNameValue)
        } else {
            selectedCompanies.insert(companyNameValue)
        }
    } else if selectedCategory == "Contact" {
        selectedCompanyID = company.0
        companyName = company.1
        showContactSearch = true
        searchContactsForCompany()
    }
}
    
    private func contactFromString(_ string: String) -> Contact {
        let nameComponents = string.split(separator: " ").map(String.init)
        return Contact(firstName: nameComponents.first ?? "", lastName: nameComponents.last ?? "")
    }
    
    private func backgroundColor(for companyName: String) -> Color {
        let baseColor = Color.blue.opacity(0.3)
        if showContactSearch {
            return selectedContacts.contains(contactFromString(companyName)) ? baseColor : Color.clear
        } else {
            return selectedCompanies.contains(companyName) ? baseColor : Color.clear
        }
    }

}

