import SwiftUI

struct CompanyDetailView: View {
    let company: Company

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(company.name ?? "Unknown")
                .font(.largeTitle)
                .bold()

            if let address = company.addressLine1 {
                Text("📍 \(address)")
            }

            if let city = company.city, let state = company.state, let zip = company.zipCode {
                Text("\(city), \(state) \(zip)")
            }

            if let phone = company.telephone  {
                Text("📞 \(phone)")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Company Details")
    }
}
