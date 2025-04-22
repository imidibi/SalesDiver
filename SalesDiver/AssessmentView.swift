import SwiftUI
import CoreData
import PDFKit

struct AssessmentView: View {
    @AppStorage("selectedCompany") private var selectedCompany: String = ""
    @State private var assessmentDate: Date = Date()
    @State private var currentAssessmentID: String = ""

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
        let trimmedName = selectedCompany.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let matchedCompany = allCompanies.first(where: { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedName }) else {
            assessmentDate = Date()
            currentAssessmentID = ""
            return
        }
        
        let request: NSFetchRequest<AssessmentEntity> = AssessmentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "company == %@", matchedCompany)
        
        if let existing = try? coreDataManager.context.fetch(request).first {
            assessmentDate = existing.date ?? Date()
            currentAssessmentID = existing.id?.uuidString ?? ""
        } else {
            assessmentDate = Date()
            currentAssessmentID = ""
        }
    }

    @ViewBuilder
    func destinationView(for area: String) -> some View {
        switch area {
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
        case "Infrastructure":
            InfrastructureAssessmentView(companyName: selectedCompany).environmentObject(coreDataManager)
        case "Cloud Services":
            CloudServicesAssessmentView(companyName: selectedCompany).environmentObject(coreDataManager)
        case "Backup":
            BackupAssessmentWrapperView(companyName: selectedCompany)
                .environmentObject(coreDataManager)
        default:
            Text("Coming soon for \(area)")
        }
    }


    func exportAssessmentAsPDF() {
        let pdfMetaData = [
            kCGPDFContextCreator: "SalesDiver25",
            kCGPDFContextAuthor: "CMIT Solutions",
            kCGPDFContextTitle: "Assessment Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 612.0
        let pageHeight = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let categories: [(String, String)] = [
            ("🖥️ Endpoint", "Endpoint"),
            ("🗄️ Servers", "Servers"),
            ("🌐 Network", "Network"),
            ("📞 Phone System", "Phone System"),
            ("📧 Email", "Email"),
            ("🛡️ Security & Compliance", "Security & Compliance"),
            ("📂 Directory Services", "Directory Services"),
            ("☁️ Infrastructure", "Infrastructure"),
            ("🧩 Cloud Services", "Cloud Services"),
            ("💾 Backup", "Backup")
        ]

        let data = renderer.pdfData { context in
            for (sectionTitle, categoryKey) in categories {
                context.beginPage()

                let titleFont = UIFont.boldSystemFont(ofSize: 20)
                let contentFont = UIFont.systemFont(ofSize: 14)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .paragraphStyle: paragraphStyle
                ]

                let contentAttributes: [NSAttributedString.Key: Any] = [
                    .font: contentFont,
                    .paragraphStyle: paragraphStyle
                ]

                sectionTitle.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)

                let fields = coreDataManager
                    .loadAllAssessmentFields(for: selectedCompany, category: categoryKey)
                    .sorted { ($0.fieldName ?? "").localizedCaseInsensitiveCompare($1.fieldName ?? "") == .orderedAscending }
                print("Loaded \(fields.count) fields for \(categoryKey)")

                for (index, field) in fields.enumerated() {
                    let yPosition = CGFloat(100 + (index * 30))
                    guard yPosition.isFinite else { continue }
                    let fieldName = (field.fieldName ?? "Unknown").trimmingCharacters(in: .whitespacesAndNewlines)
                    let valueRaw = field.valueString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let label = "Q: \(fieldName)"
                    let answer: String

                    if valueRaw == "true" {
                        answer = "✅ Yes"
                    } else if valueRaw == "false" {
                        answer = "❌ No"
                    } else if valueRaw.isEmpty {
                        answer = "—"
                    } else {
                        answer = valueRaw
                    }

                    label.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
                    answer.draw(at: CGPoint(x: 300, y: yPosition), withAttributes: contentAttributes)
                }
            }
        }
        print("PDF generated with \(data.count) bytes.")

        let safeCompany = selectedCompany.replacingOccurrences(of: " ", with: "_")
        let fileName = "\(safeCompany)-Assessment.pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        print("Saving PDF to:", tempURL.path)
        do {
            try data.write(to: tempURL)
            print("PDF successfully saved.")
            presentShareSheet(url: tempURL)
        } catch {
            print("Failed to write PDF: \(error.localizedDescription)")
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = []

            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }

    var body: some View  {
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
                                let trimmedSearch = companySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                let matched = allCompanies.contains { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedSearch }
                                showCompanySearch = companySearchText.count >= 2 && !matched
                            }

                        if showCompanySearch {
                            let filtered = allCompanies.filter {
                                companySearchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(companySearchText) ?? false)
                            }.prefix(10)

                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filtered, id: \.self) { company in
                                    Button(action: {
                                        DispatchQueue.main.async {
                                            showCompanySearch = false
                                            let name = company.name ?? ""
                                            selectedCompany = name
                                            companySearchText = name
                                        }
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
                                    destinationView(for: area.0)
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
                    if isValidCompanySelected {
                        updateAssessmentDate()
                    } else {
                        selectedCompany = ""
                        companySearchText = ""
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            exportAssessmentAsPDF()
                        }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    }
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


struct BackupAssessmentWrapperView: View {
    @EnvironmentObject var coreDataManager: CoreDataManager
    let companyName: String

    var body: some View {
        BackupAssessmentView(companyName: companyName)
            .environmentObject(coreDataManager)
    }
}
