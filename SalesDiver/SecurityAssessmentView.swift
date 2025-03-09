import SwiftUI
import CoreData

struct SecurityAssessmentView: View {
    @State private var searchText: String = ""
    @State private var selectedCustomer: String? = nil
    @State private var showClientSelection: Bool = false
    @State private var selections: [String: Bool] = [
        "Security Assessment": false, "Security Awareness": false, "Dark Web Research": false, "Backup": false,
        "Email Protection": false, "Advanced EDR": false, "Mobile Device Security": false, "Physical Security": false,
        "Passwords": false, "SIEM & SOC": false, "Firewall": false, "DNS Protection": false,
        "Multi-Factor Authentication": false, "Computer Updates": false, "Encryption": false, "Cyber Insurance": false
    ]

    let securityOptions: [(name: String, icon: String)] = [
        ("Security Assessment", "shield.fill"), ("Security Awareness", "person.2.fill"), ("Dark Web Research", "eye.fill"), ("Backup", "arrow.triangle.2.circlepath"),
        ("Email Protection", "envelope.fill"), ("Advanced EDR", "video.fill"), ("Mobile Device Security", "iphone"), ("Physical Security", "hand.raised.fill"),
        ("Passwords", "lock.fill"), ("SIEM & SOC", "exclamationmark.triangle.fill"), ("Firewall", "firewall.fill"), ("DNS Protection", "server.rack"),
        ("Multi-Factor Authentication", "phone.fill"), ("Computer Updates", "icloud.and.arrow.down.fill"), ("Encryption", "sdcard.fill"), ("Cyber Insurance", "creditcard.fill")
    ]

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack {
                // Show Search Field Only If No Customer Selected
                if selectedCustomer == nil {
                    HStack {
                        TextField("Enter Company Name", text: $searchText, onCommit: {
                            showClientSelection = true
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                        Button(action: {
                            showClientSelection = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .padding()
                        }
                    }
                    .popover(isPresented: $showClientSelection) {
                        ClientSelectionPopover(viewModel: CompanyViewModel(), selectedCustomer: $selectedCustomer, searchText: searchText)
                            .frame(width: 300, height: 400) // Adjust as needed
                    }
                }

                // Display selected customer name in large bold text
                if let customer = selectedCustomer {
                    Text("\(customer) - Security Assessment")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 10)
                }

                // Security Assessment Grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(securityOptions, id: \.name) { option in
                        Toggle(isOn: Binding(
                            get: { selections[option.name] ?? false },
                            set: { selections[option.name] = $0 }
                        )) {
                            VStack {
                                HStack {
                                    Image(systemName: option.icon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 56, height: 56)
                                        .foregroundColor(.blue)

                                    Spacer()

                                    Image(systemName: selections[option.name] ?? false ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selections[option.name] ?? false ? .blue : .gray)
                                        .font(.system(size: 60)) // Increased size for checkboxes
                                }
                                .padding(.top, 10)

                                Text(option.name)
                                    .font(.system(size: 19)) // Increased size by 60%
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .toggleStyle(CustomCheckboxToggleStyle())
                        .frame(width: 210, height: 210)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Security Assessment")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save functionality to be added later
                    }
                }
            }
        }
    }
}

// Custom Checkbox Toggle Style
struct CustomCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                configuration.label
                Spacer()
            }
            .padding()
        }
    }
}

// Client selection popover for filtering customers
struct ClientSelectionPopover: View {
    @ObservedObject var viewModel: CompanyViewModel
    @Binding var selectedCustomer: String?
    @Environment(\.dismiss) var dismiss

    var searchText: String

    var filteredCustomers: [CompanyWrapper] {
        viewModel.companies.filter { $0.name.lowercased().hasPrefix(searchText.lowercased()) }
    }

    var body: some View {
        VStack {
            Text("Select Client")
                .font(.headline)
                .padding(.top)

            if filteredCustomers.isEmpty {
                Text("No matching customers")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(filteredCustomers, id: \.id) { customer in
                        Button(action: {
                            selectedCustomer = customer.name
                            dismiss()
                        }) {
                            Text(customer.name)
                                .padding()
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.fetchCompanies() // Ensure data is up to date
        }
    }
}

struct SecurityAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityAssessmentView()
            .environment(\.managedObjectContext, CoreDataManager.shared.context)
    }
}
