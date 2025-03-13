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
    
    func searchCompanies(query: String, completion: @escaping ([String]) -> Void) {
        guard UserDefaults.standard.bool(forKey: "autotaskEnabled") else {
            completion([])
            return
        }
        
        guard let (apiUsername, apiSecret, apiTrackingID) = getAutotaskCredentials() else {
            print("Authentication failed: API credentials missing")
            completion([])
            return
        }
        print("Using API Credentials: Username SET, Secret SET, Tracking ID SET")
        
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
            "IncludeFields": ["companyName"],
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
        } catch {
            completion([])
            return
        }
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
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

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("Raw API Response: \(jsonResponse ?? [:])")

                if let companies = jsonResponse?["items"] as? [[String: Any]] {
                    let companyNames = companies.compactMap { $0["companyName"] as? String }
                    completion(companyNames)
                } else {
                    completion([])
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
}
