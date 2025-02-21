import SwiftUI
import CoreData

struct CompanyListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Company.name, ascending: true)],
        animation: .default
    )
    private var companies: FetchedResults<Company>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(companies) { company in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(company.name ?? "Unknown")
                                .font(.headline)
                                .onTapGesture {
                                    editCompany(company)
                                }
                            if let address = company.addressLine1 {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            if let phone = company.phoneNumber {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                        Button(action: {
                            openInMaps(company)
                        }) {
                            Image(systemName: "map")
                                .foregroundColor(.blue)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteCompany(company)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Companies")
        }
    }
    
    private func editCompany(_ company: Company) {
        // Navigate to EditCompanyView with selected company
    }
    
    private func openInMaps(_ company: Company) {
        if let address = company.addressLine1 {
            let urlString = "http://maps.apple.com/?q=\(address)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if let url = URL(string: urlString ?? "") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func deleteCompany(_ company: Company) {
        withAnimation {
            viewContext.delete(company)
            try? viewContext.save()
        }
    }
}
