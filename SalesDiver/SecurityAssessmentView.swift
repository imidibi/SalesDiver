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
    @State private var selectedStatus: [String: Status] = [:]
    @State private var showStatusSelection: Bool = false
    @State private var statusToUpdate: String? = nil
    @State private var showErrorMessage: Bool = false

    enum Status: CaseIterable {
        case protected, inProgress, atRisk
        
        var color: Color {
            switch self {
            case .protected: return .green
            case .inProgress: return .yellow
            case .atRisk: return .red
            }
        }
        
        var description: String {
            switch self {
            case .protected: return "Protected"
            case .inProgress: return "In Progress"
            case .atRisk: return "At Risk"
            }
        }
    }

    let securityOptions: [(name: String, icon: String)] = [
        ("Security Assessment", "shield.fill"), ("Security Awareness", "person.2.fill"), ("Dark Web Research", "eye.fill"), ("Backup", "arrow.triangle.2.circlepath"),
        ("Email Protection", "envelope.fill"), ("Advanced EDR", "video.fill"), ("Mobile Device Security", "iphone"), ("Physical Security", "hand.raised.fill"),
        ("Passwords", "lock.fill"), ("SIEM & SOC", "exclamationmark.triangle.fill"), ("Firewall", "firewall.fill"), ("DNS Protection", "server.rack"),
        ("Multi-Factor Authentication", "phone.fill"), ("Computer Updates", "icloud.and.arrow.down.fill"), ("Encryption", "sdcard.fill"), ("Cyber Insurance", "creditcard.fill")
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
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
                        .padding(.bottom, geometry.size.width > geometry.size.height ? 20 : 0) // Adjust padding based on orientation
                    }

                    // Display selected customer name in large bold text
                    if let customer = selectedCustomer {
                        Text("\(customer) - Security Assessment")
                            .font(.title)
                            .bold()
                            .padding(.bottom, 10)
                    }

                    // Security Assessment Grid
                    let columns = Array(repeating: GridItem(.flexible(minimum: 0)), count: 4) // Enforce 4 columns
                    ScrollView { // Make grid vertically scrollable
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(securityOptions, id: \.name) { option in
                                let itemWidth = (geometry.size.width / 4) - 30 // Calculate dynamic width for each item
                                let iconSize = itemWidth * 0.25 // Scale icon size relative to item width
                                let textSize = itemWidth * 0.1 // Scale text size relative to item width

                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: option.icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: iconSize, height: iconSize)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                    .padding(.top, 10)

                                    Text(option.name)
                                        .font(.system(size: textSize)) // Scale size for text
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: itemWidth, height: itemWidth)
                                .background(selectedStatus[option.name]?.color.opacity(0.3) ?? Color(.systemGray6))
                                .cornerRadius(10)
                                .onTapGesture {
                                    if selectedCustomer == nil {
                                        showErrorMessage = true
                                    } else {
                                        statusToUpdate = option.name
                                        showStatusSelection = true
                                    }
                                }
                                .sheet(isPresented: $showStatusSelection) {
                                    StatusSelectionView(selectedStatus: Binding(
                                        get: { selectedStatus[statusToUpdate ?? ""] },
                                        set: { selectedStatus[statusToUpdate ?? ""] = $0 }
                                    ), statusName: option.name)
                                }
                                .alert(isPresented: $showErrorMessage) {
                                    Alert(title: Text("Error"), message: Text("Please select a company before beginning the assessment."), dismissButton: .default(Text("OK")))
                                }
                            }
                        }
                        .padding()
                    }
                }
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

// Status selection view
struct StatusSelectionView: View {
    @Binding var selectedStatus: SecurityAssessmentView.Status?
    var statusName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text("\(statusName) Status")
                .font(.headline)
                .padding()

            ForEach(SecurityAssessmentView.Status.allCases, id: \.self) { status in
                Button(action: {
                    selectedStatus = status
                }) {
                    HStack {
                        Text(status.description)
                            .font(selectedStatus == status ? .headline.bold() : .body)
                        Spacer()
                    }
                    .padding()
                    .background(selectedStatus == status ? status.color : Color.clear)
                    .foregroundColor(selectedStatus == status ? .white : .black)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedStatus == status ? Color.clear : Color.gray))
                }
                .padding(.bottom, 10)
            }

            Text("Why is this important?")
                .font(.headline)
                .padding(.top)

            Text("They are all important!")
                .padding()

            Spacer()

            Button("Done") {
                // Dismiss the modal
                dismiss()
            }
            .padding()
        }
        .padding()
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
