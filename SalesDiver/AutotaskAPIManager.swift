import Foundation

class AutotaskAPIManager {
    static let shared = AutotaskAPIManager()
    
    private init() {}
    
    func searchCompanies(query: String, completion: @escaping ([String]) -> Void) {
        guard UserDefaults.standard.bool(forKey: "autotaskEnabled") else {
            completion([])
            return
        }
        
        let apiUsername = UserDefaults.standard.string(forKey: "autotaskAPIUsername") ?? ""
        let apiSecret = UserDefaults.standard.string(forKey: "autotaskAPISecret") ?? ""
        let apiTrackingID = UserDefaults.standard.string(forKey: "autotaskAPITrackingID") ?? ""
        
        guard !apiUsername.isEmpty, !apiSecret.isEmpty, !apiTrackingID.isEmpty else {
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
            "MaxRecords": 5,
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
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let companies = jsonResponse?["items"] as? [[String: Any]] {
                    let companyNames = companies.compactMap { $0["companyName"] as? String }
                    completion(companyNames)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }
}
