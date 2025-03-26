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
    
    func searchContacts(companyID: Int, completion: @escaping ([(Int, String, String)]) -> Void) {
        guard UserDefaults.standard.bool(forKey: "autotaskEnabled"),
              let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            completion([])
            return
        }
        
        let apiBaseURL = "https://webservices24.autotask.net/ATServicesRest/V1.0/Contacts/query"
        var request = URLRequest(url: URL(string: apiBaseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiUsername, forHTTPHeaderField: "UserName")
        request.setValue(apiSecret, forHTTPHeaderField: "Secret")
        request.setValue(apiTrackingID, forHTTPHeaderField: "ApiIntegrationCode")
        
        let requestBody: [String: Any] = [
            "MaxRecords": 500,
            "IncludeFields": ["id", "firstName", "lastName"],
            "Filter": [
                ["op": "eq", "field": "CompanyID", "value": companyID],
                ["op": "gt", "field": "id", "value": 0]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            print("JSON encoding error: \(error.localizedDescription)")
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received from API")
                completion([])
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let contactsArray = jsonResponse?["items"] as? [[String: Any]] else {
                    print("No 'items' in response")
                    completion([])
                    return
                }
                
                let contacts = contactsArray.compactMap { contact -> (Int, String, String)? in
                    guard let id = contact["id"] as? Int,
                          let firstName = contact["firstName"] as? String,
                          let lastName = contact["lastName"] as? String else {
                        return nil
                    }
                    return (id, firstName, lastName)
                }
                
                completion(contacts)
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    func searchContactsGET(companyID: Int, completion: @escaping ([(Int, String)]) -> Void) {
        guard UserDefaults.standard.bool(forKey: "autotaskEnabled") else {
            print("Autotask integration is disabled.")
            completion([])
            return
        }
        
        guard let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            print("Authentication failed: API credentials missing")
            completion([])
            return
        }
        
        // Build the query JSON as per Autotask support recommendations.
        let queryJson: [String: Any] = [
            "filter": [
                ["op": "eq", "field": "CompanyID", "value": companyID],
                ["op": "gt", "field": "id", "value": 0]
            ]
        ]
        
        // Convert the query JSON to a string and URL-encode it.
        guard let jsonData = try? JSONSerialization.data(withJSONObject: queryJson, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8),
              let encodedQuery = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Error encoding query JSON")
            completion([])
            return
        }
        
        let urlString = "https://webservices24.autotask.net/atservicesrest/v1.0/Contacts/query?search=\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(apiUsername, forHTTPHeaderField: "UserName")
        request.setValue(apiSecret, forHTTPHeaderField: "Secret")
        request.setValue(apiTrackingID, forHTTPHeaderField: "ApiIntegrationCode")
        
        print("Performing GET request: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Request Error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("API Response Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received from API")
                completion([])
                return
            }
            
            let fallback = "Invalid JSON"
            print("Full Raw Response: \(String(data: data, encoding: .utf8) ?? fallback)")
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let contacts = jsonResponse["items"] as? [[String: Any]] {
                    let contactData = contacts.compactMap { contact -> (Int, String)? in
                        guard let id = contact["id"] as? Int,
                              let firstName = contact["firstName"] as? String,
                              let lastName = contact["lastName"] as? String,
                              let returnedCompanyID = contact["companyID"] as? Int else {
                            return nil
                        }
                        if returnedCompanyID != companyID {
                            return nil
                        }
                        return (id, "\(firstName) \(lastName)")
                    }
                    print("Filtered Contacts: \(contactData)")
                    completion(contactData)
                } else {
                    print("No contacts found in response")
                    completion([])
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    func getAllCompanies(completion: @escaping ([(Int, String)]) -> Void) {
        guard UserDefaults.standard.bool(forKey: "autotaskEnabled") else {
            print("Autotask integration is disabled.")
            completion([])
            return
        }
        
        guard let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            print("Authentication failed: API credentials missing")
            completion([])
            return
        }
        
        let urlString = "https://webservices24.autotask.net/atservicesrest/v1.0/Companies/query?search=%7B%22filter%22:[%7B%22op%22:%22exist%22,%22field%22:%22id%22%7D]%7D"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(apiUsername, forHTTPHeaderField: "UserName")
        request.setValue(apiSecret, forHTTPHeaderField: "Secret")
        request.setValue(apiTrackingID, forHTTPHeaderField: "ApiIntegrationCode")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Request Error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received from API")
                completion([])
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = jsonResponse["items"] as? [[String: Any]] {
                    let companies = items.compactMap { item -> (Int, String)? in
                        if let id = item["id"] as? Int,
                           let name = item["companyName"] as? String {
                            return (id, name)
                        }
                        return nil
                    }
                    completion(companies)
                } else {
                    completion([])
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    func searchContactsFromBody(_ requestBody: [String: Any], completion: @escaping ([(Int, String, String)]) -> Void) {
        guard let url = URL(string: "https://webservices24.autotask.net/ATServicesRest/V1.0/Contacts/query") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        guard let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            print("❌ Missing Autotask credentials")
            completion([])
            return
        }
        request.setValue(apiUsername, forHTTPHeaderField: "UserName")
        request.setValue(apiSecret, forHTTPHeaderField: "Secret")
        request.setValue(apiTrackingID, forHTTPHeaderField: "ApiIntegrationCode")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion([])
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                print("❌ Failed to parse contact response")
                completion([])
                return
            }
            
            let contacts: [(Int, String, String)] = items.compactMap {
                guard let id = $0["id"] as? Int,
                      let firstName = $0["firstName"] as? String,
                      let lastName = $0["lastName"] as? String else { return nil }
                return (id, firstName, lastName)
            }
            
            completion(contacts)
        }.resume()
    }
    func searchFullContactDetail(_ requestBody: [String: Any], completion: @escaping ([(firstName: String, lastName: String, email: String, phone: String, title: String)]) -> Void) {
        guard let url = URL(string: "https://webservices24.autotask.net/ATServicesRest/V1.0/Contacts/query"),
              let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            print("❌ Invalid URL or missing credentials")
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(apiUsername, forHTTPHeaderField: "UserName")
        request.setValue(apiSecret, forHTTPHeaderField: "Secret")
        request.setValue(apiTrackingID, forHTTPHeaderField: "ApiIntegrationCode")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("❌ Failed to encode request body: \(error)")
            completion([])
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                print("❌ Failed to fetch or decode contact details")
                completion([])
                return
            }

            let contacts = items.compactMap { item -> (firstName: String, lastName: String, email: String, phone: String, title: String)? in
                guard let firstName = item["firstName"] as? String,
                      let lastName = item["lastName"] as? String else {
                    return nil
                }
                let email = item["emailAddress"] as? String ?? ""
                let phone = item["phone"] as? String ?? ""
                let title = item["title"] as? String ?? ""
                return (firstName, lastName, email, phone, title)
            }

            completion(contacts)
        }.resume()
    }
}
