import SwiftUI

struct SettingsView: View {
    @AppStorage("autotaskEnabled") private var autotaskEnabled = false
    @AppStorage("autotaskAPIUsername") private var apiUsername = ""
    @AppStorage("autotaskAPISecret") private var apiSecret = ""
    @AppStorage("autotaskAPITrackingID") private var apiTrackingID = ""
    
    @State private var testResult: String = ""
    @State private var isTesting = false
    @State private var companyName: String = ""
    @State private var searchResults: [String] = []
    @State private var selectedCompanies: Set<String> = []
    @State private var showAutotaskSettings = false
    
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
                
                if !testResult.isEmpty {
                    Section(header: Text("Autotask Sync Status")) {
                        Text(testResult)
                            .foregroundColor(testResult.contains("Failed") || testResult.contains("Error") || testResult.contains("No companies found") ? .red : .primary)
                    }
                }
                
                if autotaskEnabled {
                    Section(header: Text("Search Companies in Autotask")) {
                        TextField("Enter company name", text: $companyName, onCommit: {
                            searchCompanies()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        List(searchResults, id: \.self, selection: $selectedCompanies) { company in
                            Text(company)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .onTapGesture {
                                    if selectedCompanies.contains(company) {
                                        selectedCompanies.remove(company)
                                    } else {
                                        selectedCompanies.insert(company)
                                    }
                                }
                                .background(selectedCompanies.contains(company) ? Color.blue.opacity(0.3) : Color.clear)
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
            "MaxRecords": selectedCompanies.count,
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
    
}

