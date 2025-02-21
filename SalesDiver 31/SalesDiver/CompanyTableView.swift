import SwiftUI
import CoreData

struct CompanyTableView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Company.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Company.name, ascending: true)]
    ) var companies: FetchedResults<Company>

    var body: some View {
        List(companies, id: \.self) { company in
            HStack {
                Text(company.name ?? "Unknown")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading) // Left-align text
                Spacer()
                if let address = company.addressLine1 {
                    Button(action: {
                        openAppleMaps(for: address)
                    }) {
                        Image(systemName: "map")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.vertical, 5)
        }
        .navigationTitle("Companies")
    }

    private func openAppleMaps(for address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
    }
}
