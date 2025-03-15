import SwiftUI

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
    
    var body: some View {
        NavigationStack {
            Form {
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

                        Button(action: syncWithAutotask) {
                            if isTesting {
                                ProgressView()
                            } else {
                                Text("Sync with Autotask now")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(isTesting)
                        .padding()
                    }
                }
                
                if autotaskEnabled {
                    Section(header: Text("Select Data Type")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(["Company", "Contact", "Opportunity", "Product"], id: \.self) { category in
                                Button(action: {
                                    if selectedCategory != category {
                                        companyName = ""  // Clear search field
                                        searchResults = [] // Reset search results
                                        selectedCompanies.removeAll() // Clear selection
                                        showContactSearch = false // Reset contact search visibility
                                    }
                                    
                                    selectedCategory = category
                                    // Removed automatic search for Contacts when button is selected
                                }) {
                                    Text(category)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(selectedCategory == category ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // Ensures correct behavior on selection
                            }
                        }
                        .padding()
                    }
                }
                
                if !testResult.isEmpty {
                    Section(header: Text("Autotask Sync Status")) {
                        Text(testResult)
                            .foregroundColor(testResult.contains("Failed") || testResult.contains("Error") || testResult.contains("No companies found") ? .red : .primary)
                    }
                }
                
                if autotaskEnabled {
                    Section(header: Text(searchHeaderText)) {
                        TextField("Enter company name", text: $companyName, onCommit: {
                            if selectedCategory == "Contact" {
                                if !companyName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    searchCompaniesForContacts() // Trigger search only when user submits with input
                                }
                            } else {
                                searchCompanies()
                            }
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        ScrollView {
                            LazyVStack {
                        ForEach(searchResults, id: \.0) { company in
                                    Text(company.1)
                                        .font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                        .onTapGesture {
                                            if selectedCategory == "Contact" {
                                                companyName = company.1  // Store company name in text field
                                                selectedCompanyID = company.0  // Store selected company ID
                                                selectedCompanies = [company.1] // Ensure only one company is selected
                                                searchResults = [] // Clear search results after selecting a company
                                                showContactSearch = true // Show contact search field after selecting a company
                                                print("✅ Selected Company: ID = \(company.0), Name = \(company.1)")
                                            } else {
                                                if selectedCompanies.contains(company.1) {
                                                    selectedCompanies.remove(company.1)
                                                } else {
                                                    selectedCompanies.insert(company.1)
                                                }
                                            }
                                        }
                                        .background(selectedCompanies.contains(company.1) ? Color.blue.opacity(0.3) : Color.clear)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        
                        if showContactSearch {
                            TextField("Enter contact name", text: $contactName, onCommit: {
                                let trimmedQuery = contactName.trimmingCharacters(in: .whitespaces)
                                guard !trimmedQuery.isEmpty, let companyID = selectedCompanyID else {
                                    print("❌ Contact search not triggered: Query empty or no company selected.")
                                    return
                                }
                                
                                print("🔍 Triggering contact search for Contact Name: \(trimmedQuery) in Company ID: \(companyID)")
                                
                                AutotaskAPIManager.shared.searchContacts(companyID: companyID, contactName: trimmedQuery) { results in
                                    DispatchQueue.main.async {
                                        print("✅ Contact search completed. Results: \(results)")
                                        searchResults = results
                                    }
                                }
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.top, 10)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
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
        
        let requestBody: [String: Any] = [
            "MaxRecords": 50,
            "IncludeFields": ["id", "companyName", "address1", "address2", "city", "state", "postalCode", "phone"],
            "Filter": [
                [
                    "op": "or",
                    "items": selectedCompanies.map { company in
                        [
                            "op": "contains",
                            "field": "companyName",
                            "value": company.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        ]
                    }
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
    
    private func searchCompanies() {
        AutotaskAPIManager.shared.searchCompanies(query: companyName) { results in
            DispatchQueue.main.async {
                searchResults = results
            }
        }
    }

    private func searchCompaniesForContacts() {
        let trimmedQuery = companyName.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return } // Prevent search if input is empty

        AutotaskAPIManager.shared.searchCompanies(query: trimmedQuery) { results in
            DispatchQueue.main.async {
                searchResults = results
            }
        }
    }
    
}
