import SwiftUI
import CoreData

struct AssessmentView: View {
    @AppStorage("selectedCompany") private var selectedCompany: String = ""
    @State private var assessmentDate: Date = Date()

    @EnvironmentObject var coreDataManager: CoreDataManager

    @State private var showCompanySearch = false
    @State private var companySearchText = ""

    @FetchRequest(
        entity: CompanyEntity.entity(),
        sortDescriptors: []
    ) var allCompanies: FetchedResults<CompanyEntity>

    let subjectAreas = [
        ("EndPoints", "desktopcomputer"),
        ("Servers", "server.rack"),
        ("Network", "network"),
        ("Phone System", "phone"),
        ("Email", "envelope"),
        ("Security & Compliance", "lock.shield"),
        ("Directory Services", "person.3"),
        ("Infrastructure", "building.2"),
        ("Cloud Services", "icloud"),
        ("Backup", "externaldrive")
    ]

    let columns = Array(repeating: GridItem(.flexible(minimum: 0)), count: 5)

    var isValidCompanySelected: Bool {
        guard !selectedCompany.isEmpty, !companySearchText.isEmpty else { return false }
        let trimmedSelected = selectedCompany.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedSearch = companySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allCompanies.contains(where: {
            ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedSelected &&
            trimmedSelected == trimmedSearch
        })
    }

    private func updateAssessmentDate() {
        let request: NSFetchRequest<AssessmentEntity> = AssessmentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "companyName == %@", selectedCompany.trimmingCharacters(in: .whitespacesAndNewlines))

        if let existing = try? coreDataManager.context.fetch(request).first {
            assessmentDate = existing.date ?? Date()
        } else {
            assessmentDate = Date()
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 20) {
                    Text("Assessment")
                        .font(.largeTitle)
                        .bold()

                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Select Company", text: $companySearchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 8)
                            .onChange(of: companySearchText) {
                                showCompanySearch = companySearchText.count >= 2
                            }

                        if showCompanySearch {
                            let filtered = allCompanies.filter {
                                companySearchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(companySearchText) ?? false)
                            }.prefix(10)

                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filtered, id: \.self) { company in
                                    Button(action: {
                                        let name = company.name ?? ""
                                        selectedCompany = name
                                        companySearchText = name
                                        showCompanySearch = false
                                    }) {
                                        Text(company.name ?? "")
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.white)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .padding(.horizontal, 8)
                        }
                    }

                    DatePicker("Date", selection: $assessmentDate, displayedComponents: .date)
                        .padding(.horizontal, 8)

                    Text("Select Area to Assess:")
                        .font(.headline)
                        .padding(.horizontal, 8)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(subjectAreas, id: \.0) { area in
                                NavigationLink {
                                    switch area.0 {
                                    case "EndPoints":
                                        VStack {
                                            Image(systemName: "desktopcomputer")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 40)
                                                .padding(.top)
                                            EndpointAssessmentView().environmentObject(coreDataManager)
                                        }
                                    case "Servers":
                                        VStack {
                                            Image(systemName: "server.rack")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 40)
                                                .padding(.top)
                                            ServerAssessmentView().environmentObject(coreDataManager)
                                        }
                                    case "Network":
                                        NetworkAssessmentView().environmentObject(coreDataManager)
                                    case "Phone System":
                                        PhoneSystemAssessmentView().environmentObject(coreDataManager)
                                    case "Email":
                                        EmailAssessmentView().environmentObject(coreDataManager)
                                    case "Security & Compliance":
                                        ProspectSecurityAssessmentView().environmentObject(coreDataManager)
                                    case "Directory Services":
                                        DirectoryServicesAssessmentView(companyName: selectedCompany).environmentObject(coreDataManager)
                                    default:
                                        Text("Coming soon for \(area.0)")
                                    }
                                } label: {
                                    AssessmentGridItem(area: area, geometry: geometry)
                                }
                                .disabled(!isValidCompanySelected)
                            }
                        }
                        .padding(.bottom, 32)
                        .padding(.horizontal)
                    }
                }
                .padding()
                .onAppear {
                    if !isValidCompanySelected {
                        selectedCompany = ""
                        companySearchText = ""
                    }
                    updateAssessmentDate()
                }
            }
        }
    }
}

struct AssessmentGridItem: View {
    let area: (String, String)
    let geometry: GeometryProxy

    var body: some View {
        let safeWidth = max(geometry.size.width, 300)
        let totalSpacing: CGFloat = 20 * 4
        let itemWidth = (safeWidth - totalSpacing - 40) / 5
        let iconSize = itemWidth * 0.4
        let textSize = itemWidth * 0.12

        VStack(spacing: 8) {
            Image(systemName: area.1)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.blue)

            Text(area.0)
                .font(.system(size: textSize))
                .multilineTextAlignment(.center)
        }
        .frame(width: itemWidth, height: itemWidth)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(4)
    }
}
