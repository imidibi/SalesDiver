import Foundation

class AutotaskAPIManager {
    static let shared = AutotaskAPIManager()
    
    private init() {}
    
    private func getAutotaskCredentials() -> (String, String, String)? {
        let apiUsername = UserDefaults.standard.string(forKey: "autotaskAPIUsername") ?? ""
        let apiSecret = UserDefaults.standard.string(forKey: "autotaskAPISecret") ?? ""
        let apiTrackingID = UserDefaults.standard.string(forKey: "autotaskAPITrackingID") ?? ""
        
        guard !apiUsername.isEmpty, !apiSecret.isEmpty, !apiTrackingID.isEmpty else {
            return nil
        }
        return (apiUsername, apiSecret, apiTrackingID)
    }
    
    func searchCompanies(query: String, completion: @escaping ([(Int, String)]) -> Void) {
        guard UserDefaults.standard.bool(forKey: "autotaskEnabled") else {
            print("🔴 Autotask integration is disabled.")
            completion([])
            return
        }
        
        guard let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            print("🔴 Authentication failed: API credentials missing")
            completion([])
            return
        }
        
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
            "IncludeFields": ["id", "companyName"],
            "Filter": [[
                "op": "like",
                "field": "companyName",
                "value": "\(query)%",
                "udf": false,
                "items": []
            ]]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
            print("📤 Sending Company Search Request: \(apiBaseURL)")
            print("📄 Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
        } catch {
            print("🔴 Failed to encode request body: \(error.localizedDescription)")
            completion([])
            return
        }
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🔴 API Request Error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API Response Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("🔴 No data received from API")
                completion([])
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("📥 Raw API Response: \(jsonResponse ?? [:])")
                
                if let companies = jsonResponse?["items"] as? [[String: Any]] {
                    let companyData = companies.compactMap { company -> (Int, String)? in
                        if let id = company["id"] as? Int,
                           let name = company["companyName"] as? String {
                            return (id, name)
                        }
                        return nil
                    }
                    print("✅ Parsed Companies: \(companyData)")
                    completion(companyData)
                } else {
                    print("⚠️ No companies found in response")
                    completion([])
                }
            } catch {
                print("🔴 JSON Parsing Error: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    func searchContacts(companyID: Int, contactName: String, completion: @escaping ([(Int, String)]) -> Void) {
        guard UserDefaults.standard.bool(forKey: "autotaskEnabled") else {
            print("🔴 Autotask integration is disabled.")
            completion([])
            return
        }
        
        guard let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            print("🔴 Authentication failed: API credentials missing")
            completion([])
            return
        }
        
        let apiBaseURL = "https://webservices24.autotask.net/ATServicesRest/V1.0/Contacts/query"
        var request = URLRequest(url: URL(string: apiBaseURL)!)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(apiUsername, forHTTPHeaderField: "UserName")
        request.setValue(apiSecret, forHTTPHeaderField: "Secret")
        request.setValue(apiTrackingID, forHTTPHeaderField: "ApiIntegrationCode")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("📌 Preparing Contact Search Request")
        print("🔍 Company ID: \(companyID) (Type: \(type(of: companyID)))")
        print("🔍 Contact Name: \(contactName)")
        print("🔍 Using `companyID` for filtering")
        print("🔍 Company ID Type Before API Call: \(type(of: companyID)) - Value: \(companyID)")
        print("🔍 Ensuring `companyID` is passed as an integer: \(companyID) (Type: \(type(of: companyID)))")
        if companyID <= 0 {
            print("⚠️ Warning: Invalid `companyID` detected (\(companyID)). Check how the ID is being passed.")
        }

        let requestBody: [String: Any] = [
            "MaxRecords": 50,
            "IncludeFields": ["id", "firstName", "lastName", "companyID"],
            "Filter": [
                [
                    "op": "equals",
                    "field": "companyID",
                    "value": companyID,
                    "udf": false,
                    "items": []
                ],
                [
                    "op": "like",
                    "field": "firstName",
                    "value": "\(contactName)%",
                    "udf": false,
                    "items": []
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
            print("📤 Sending Contact Search Request for Contact Name: \(contactName) in Company ID: \(companyID)")
            print("📄 Formatted Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
        } catch {
            print("🔴 Failed to encode request body: \(error.localizedDescription)")
            completion([])
            return
        }
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🔴 API Request Error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API Response Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("🔴 No data received from API")
                completion([])
                return
            }
            
            print("📥 Full Raw Contact API Response: \(String(data: data, encoding: .utf8) ?? "Invalid JSON")") // Log the full raw API response
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("📥 Raw Contact API Response: \(jsonResponse ?? [:])")
                
                if let contacts = jsonResponse?["items"] as? [[String: Any]] {
                    let contactData = contacts.compactMap { contact -> (Int, String)? in
                        guard let id = contact["id"] as? Int,
                              let firstName = contact["firstName"] as? String,
                              let lastName = contact["lastName"] as? String,
                              let returnedCompanyID = contact["companyID"] as? Int else {
                            return nil
                        }

                        // Ensure we only keep contacts that match the requested companyID
                        if returnedCompanyID != companyID {
                            print("⚠️ Filtering out contact \(firstName) \(lastName) (ID: \(id)) from companyID \(returnedCompanyID) - does not match requested companyID \(companyID).")
                            return nil
                        }

                        return (id, "\(firstName) \(lastName)")
                    }
                    print("✅ Filtered Contacts for Company ID \(companyID): \(contactData)")
                    completion(contactData)
                } else {
                    print("⚠️ No contacts found in response")
                    completion([])
                }
            } catch {
                print("🔴 JSON Parsing Error: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
}
