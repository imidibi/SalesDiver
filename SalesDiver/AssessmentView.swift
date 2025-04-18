//
//  AssessmentView.swift
//  SalesDiver
//
//  Created by Ian Miller on 4/16/25.
//

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
        return allCompanies.contains(where: { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedSelected && trimmedSelected == trimmedSearch })
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Assessment")
                        .font(.largeTitle)
                        .bold()
                    
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 0) {
                            TextField("Select Company", text: $companySearchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(8)
                                .onChange(of: companySearchText) {
                                    showCompanySearch = companySearchText.count >= 2
                                }

                            if showCompanySearch {
                                VStack(alignment: .leading, spacing: 0) {
                                    let filteredCompanies = allCompanies.filter {
                                        companySearchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(companySearchText) ?? false)
                                    }.prefix(10)

                                    ForEach(filteredCompanies, id: \.self) { company in
                                    Button(action: {
                                        let name = company.name ?? ""
                                        selectedCompany = name
                                        companySearchText = name
                                        DispatchQueue.main.async {
                                            showCompanySearch = false
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
                                .zIndex(1)
                            }
                        }
                    }
                    
                    DatePicker("Date", selection: $assessmentDate, displayedComponents: .date)
                        .padding(.trailing)
                    
                    Text("Select Area to Assess:")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(subjectAreas, id: \.0) { area in
                                NavigationLink {
                                switch area.0 {
                                    case "EndPoints":
                                        EndpointAssessmentView().environmentObject(coreDataManager)
                                    case "Servers":
                                        ServerAssessmentView().environmentObject(coreDataManager)
                                    case "Network":
                                        NetworkAssessmentView().environmentObject(coreDataManager)
                                    default:
                                        Text("Coming soon for \(area.0)")
                                }
                                } label: {
                                    AssessmentGridItem(area: area, geometry: geometry)
                                }
                                .disabled(!isValidCompanySelected)
                            }
                        }
                        .padding(.bottom, 32) // Prevent content from being clipped at bottom
                    }
                }
                .onAppear {
                    if !isValidCompanySelected {
                        selectedCompany = ""
                        companySearchText = ""
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
            .padding(4) // Adds spacing between icons
        }
    }
    
    struct AssessmentView_Previews: PreviewProvider {
        static var previews: some View {
            AssessmentView()
        }
    }
    
    struct EndpointAssessmentView: View {
        @AppStorage("selectedCompany") private var selectedCompany: String = ""
        
        @EnvironmentObject var coreDataManager: CoreDataManager
        
        @State private var pcCount: String = ""
        @State private var macCount: String = ""
        @State private var iphoneCount: String = ""
        @State private var ipadCount: String = ""
        @State private var chromebookCount: String = ""
        @State private var androidCount: String = ""
        @State private var otherCount: String = ""
        
        @State private var managePCs: Bool = false
        @State private var manageMacs: Bool = false
        @State private var manageiPhones: Bool = false
        @State private var manageiPads: Bool = false
        @State private var manageChromebooks: Bool = false
        @State private var manageAndroid: Bool = false
        @State private var manageOther: Bool = false
        
        @State private var runsWindows11 = false
        @State private var windowsVersion = ""
        @State private var hasMDM = false
        @State private var mdmProvider = ""
        @State private var hasAUP = false
        @State private var allowsBYOD = false
        @State private var areEncrypted = false
        @State private var isSaving = false
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Endpoint Assessment")
                        .font(.title)
                        .bold()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 24) {
                        deviceEntryView(label: "PCs", icon: "desktopcomputer", count: $pcCount, managed: $managePCs)
                        deviceEntryView(label: "Macs", icon: "laptopcomputer", count: $macCount, managed: $manageMacs)
                        deviceEntryView(label: "iPhones", icon: "iphone", count: $iphoneCount, managed: $manageiPhones)
                        deviceEntryView(label: "iPads", icon: "ipad", count: $ipadCount, managed: $manageiPads)
                        deviceEntryView(label: "Chromebooks", icon: "display", count: $chromebookCount, managed: $manageChromebooks)
                        deviceEntryView(label: "Android", icon: "phone", count: $androidCount, managed: $manageAndroid)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Toggle("Do your PCs all run Windows 11?", isOn: $runsWindows11)
                        
                        VStack(alignment: .leading) {
                            Text("If not, which Windows version do they run?")
                            TextField("e.g. Windows 10", text: $windowsVersion)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Toggle("Are any of your devices managed by an MDM solution?", isOn: $hasMDM)
                        
                        VStack(alignment: .leading) {
                            Text("If so, which one?")
                            TextField("e.g. Intune, Jamf", text: $mdmProvider)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Toggle("Does your company have an Acceptable Use Policy?", isOn: $hasAUP)
                        Toggle("Do you allow personal devices to access company data or email?", isOn: $allowsBYOD)
                        Toggle("Are your computers encrypted?", isOn: $areEncrypted)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        guard !selectedCompany.isEmpty, !isSaving else { return }
                        isSaving = true
                        let fields: [(String, String?, Bool?)] = [
                            ("PC Count", pcCount, nil),
                            ("Mac Count", macCount, nil),
                            ("iPhone Count", iphoneCount, nil),
                            ("iPad Count", ipadCount, nil),
                            ("Chromebook Count", chromebookCount, nil),
                            ("Android Count", androidCount, nil),
                            ("Other Count", otherCount, nil),
                            ("Manage PCs", nil, managePCs),
                            ("Manage Macs", nil, manageMacs),
                            ("Manage iPhones", nil, manageiPhones),
                            ("Manage iPads", nil, manageiPads),
                            ("Manage Chromebooks", nil, manageChromebooks),
                            ("Manage Android", nil, manageAndroid),
                            ("Manage Other", nil, manageOther),
                            ("Windows 11 PCs", nil, runsWindows11),
                            ("Other Windows Version", windowsVersion.isEmpty ? nil : windowsVersion, nil),
                            ("MDM Provider", mdmProvider.isEmpty ? nil : mdmProvider, nil),
                            ("Acceptable Use Policy", nil, hasAUP),
                            ("Allows BYOD", nil, allowsBYOD),
                            ("Encrypted Computers", nil, areEncrypted)
                        ]
                        coreDataManager.saveAssessmentFields(for: selectedCompany, category: "EndPoints", fields: fields)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isSaving = false
                        }
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedCompany.isEmpty || isSaving)
                }
                .padding()
            }
            .navigationTitle("Endpoint Assessment")
            .onAppear {
                // print("📥 Loading saved endpoint assessment for: \(selectedCompany)")
                guard !selectedCompany.isEmpty else {
                    // print("❗️Skipping load — selectedCompany is empty")
                    return
                }
 
                let allFields: [AssessmentFieldEntity] = coreDataManager.loadAllAssessmentFields(for: selectedCompany, category: "EndPoints")
                // print("✅ Loaded assessment for company: \(selectedCompany)")
                // print("🧠 Loaded assessment: \(selectedCompany) with \(allFields.count) fields")
                // print("   → All loaded fields: \(allFields.map { $0.fieldName ?? "nil" })")
 
                for field in allFields {
                    // print("🔍 Inspecting field: \(field.fieldName ?? "nil"), valueNumber: \(field.valueNumber), valueString: \(field.valueString ?? "nil")")
 
                    switch field.fieldName {
                    case "Windows 11 PCs": runsWindows11 = field.valueString == "true"
                    case "Other Windows Version": windowsVersion = field.valueString ?? ""
                    case "MDM Provider": mdmProvider = field.valueString ?? ""
                    case "Acceptable Use Policy": hasAUP = field.valueString == "true"
                    case "Allows BYOD": allowsBYOD = field.valueString == "true"
                    case "Encrypted Computers": areEncrypted = field.valueString == "true"
                    case "PC Count": pcCount = field.valueString ?? String(Int(field.valueNumber))
                    case "Mac Count": macCount = field.valueString ?? String(Int(field.valueNumber))
                    case "iPhone Count": iphoneCount = field.valueString ?? String(Int(field.valueNumber))
                    case "iPad Count": ipadCount = field.valueString ?? String(Int(field.valueNumber))
                    case "Chromebook Count": chromebookCount = field.valueString ?? String(Int(field.valueNumber))
                    case "Android Count": androidCount = field.valueString ?? String(Int(field.valueNumber))
                    case "Other Count": otherCount = field.valueString ?? String(Int(field.valueNumber))
                    case "Manage PCs": managePCs = field.valueString == "true"
                    case "Manage Macs": manageMacs = field.valueString == "true"
                    case "Manage iPhones": manageiPhones = field.valueString == "true"
                    case "Manage iPads": manageiPads = field.valueString == "true"
                    case "Manage Chromebooks": manageChromebooks = field.valueString == "true"
                    case "Manage Android": manageAndroid = field.valueString == "true"
                    case "Manage Other": manageOther = field.valueString == "true"
                    default: break
                    }
                }
 
                // print("   → After load: PC Count = \(pcCount), Manage PCs = \(managePCs)")
            }
        }
        
        @ViewBuilder
        func deviceEntryView(label: String, icon: String, count: Binding<String>, managed: Binding<Bool>) -> some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .foregroundColor(.blue)

                Text(label)
                    .font(.subheadline)

                TextField("0", text: count)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                Toggle("Managed", isOn: managed)
                    .labelsHidden()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
}
struct ServerAssessmentView: View {
    @EnvironmentObject var coreDataManager: CoreDataManager
    @AppStorage("selectedCompany") private var selectedCompany: String = ""
    

    @State private var physicalCount = ""
    @State private var vmCount = ""
    @State private var hypervisorCount = ""

    @State private var managePhysical = false
    @State private var manageVM = false
    @State private var manageHypervisor = false

    @State private var serverOS = ""
    @State private var hypervisorOS = ""
    @State private var serverApps = ""
    @State private var migrateToCloud = false
    @State private var migrationTimeframe = ""
    @State private var hadOutage = false
    @State private var recoveryTime = ""
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                HStack(spacing: 20) {
                    IconCounterView(label: "Physical", icon: "internaldrive", count: $physicalCount, isManaged: $managePhysical)
                    IconCounterView(label: "VMs", icon: "macpro.gen3", count: $vmCount, isManaged: $manageVM)
                    IconCounterView(label: "Hypervisors", icon: "cpu", count: $hypervisorCount, isManaged: $manageHypervisor)
                }

                GroupBox(label: Text("Server Questions")) {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("What operating systems are on your servers?", text: $serverOS)
                        TextField("What Hypervisor OS do you use?", text: $hypervisorOS)
                        TextField("What are the main apps or services run on your servers?", text: $serverApps)
                        Toggle("Do you plan to migrate your servers to the cloud?", isOn: $migrateToCloud)
                        TextField("Timeframe for migration?", text: $migrationTimeframe)
                        Toggle("Experienced a major server outage?", isOn: $hadOutage)
                        TextField("How long did it take to recover?", text: $recoveryTime)
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding()
                }
                
                Button(action: {
                    guard !selectedCompany.isEmpty, !isSaving else { return }
                    isSaving = true
                    let fields: [(String, String?, Bool?)] = [
                        ("Physical Server Count", physicalCount, nil),
                        ("VM Count", vmCount, nil),
                        ("Hypervisor Count", hypervisorCount, nil),
                        ("Manage Physical", nil, managePhysical),
                        ("Manage VM", nil, manageVM),
                        ("Manage Hypervisor", nil, manageHypervisor),
                        ("Server OS", serverOS.isEmpty ? nil : serverOS, nil),
                        ("Hypervisor OS", hypervisorOS.isEmpty ? nil : hypervisorOS, nil),
                        ("Server Apps", serverApps.isEmpty ? nil : serverApps, nil),
                        ("Cloud Migration", nil, migrateToCloud),
                        ("Migration Timeframe", migrationTimeframe.isEmpty ? nil : migrationTimeframe, nil),
                        ("Outage Experienced", nil, hadOutage),
                        ("Recovery Time", recoveryTime.isEmpty ? nil : recoveryTime, nil)
                    ]
                    coreDataManager.saveAssessmentFields(for: selectedCompany, category: "Servers", fields: fields)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isSaving = false
                    }
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedCompany.isEmpty || isSaving)
            }
            .padding()
        }
        .onAppear {
            // print("📥 Loading saved server assessment for: \(selectedCompany)")
            let fields = coreDataManager.loadAllAssessmentFields(for: selectedCompany, category: "Servers")
            for field in fields {
                switch field.fieldName {
                case "Physical Server Count": physicalCount = field.valueString ?? String(Int(field.valueNumber))
                case "VM Count": vmCount = field.valueString ?? String(Int(field.valueNumber))
                case "Hypervisor Count": hypervisorCount = field.valueString ?? String(Int(field.valueNumber))
                case "Manage Physical": managePhysical = field.valueString == "true"
                case "Manage VM": manageVM = field.valueString == "true"
                case "Manage Hypervisor": manageHypervisor = field.valueString == "true"
                case "Server OS": serverOS = field.valueString ?? ""
                case "Hypervisor OS": hypervisorOS = field.valueString ?? ""
                case "Server Apps": serverApps = field.valueString ?? ""
                case "Cloud Migration": migrateToCloud = field.valueString == "true"
                case "Migration Timeframe": migrationTimeframe = field.valueString ?? ""
                case "Outage Experienced": hadOutage = field.valueString == "true"
                case "Recovery Time": recoveryTime = field.valueString ?? ""
                default: break
                }
            }
        }
    }
    }

struct NetworkAssessmentView: View {
    @AppStorage("selectedCompany") private var selectedCompany: String = ""
    @EnvironmentObject var coreDataManager: CoreDataManager

    @State private var hasFirewall = false
    @State private var firewallBrand = ""
    @State private var firewallLicensed = false
    @State private var hasSwitches = false
    @State private var switchBrand = ""
    @State private var hasWiFi = false
    @State private var wifiBrand = ""
    @State private var wiredOrWifi = ""
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Network Assessment")
                    .font(.title)
                    .bold()

                Toggle("Do you have a Firewall?", isOn: $hasFirewall)
                TextField("What Brand is it?", text: $firewallBrand)
                    .textFieldStyle(.roundedBorder)
                Toggle("Is the software licensed and current?", isOn: $firewallLicensed)

                Toggle("Do you have any network switches?", isOn: $hasSwitches)
                TextField("If so, what brand?", text: $switchBrand)
                    .textFieldStyle(.roundedBorder)

                Toggle("Do you have a WiFi Network?", isOn: $hasWiFi)
                TextField("What brand are the Access Points?", text: $wifiBrand)
                    .textFieldStyle(.roundedBorder)
                TextField("Are most users wired or on WiFi?", text: $wiredOrWifi)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    guard !selectedCompany.isEmpty, !isSaving else { return }
                    isSaving = true
                    let fields: [(String, String?, Bool?)] = [
                        ("Has Firewall", nil, hasFirewall),
                        ("Firewall Brand", firewallBrand.isEmpty ? nil : firewallBrand, nil),
                        ("Firewall Licensed", nil, firewallLicensed),
                        ("Has Switches", nil, hasSwitches),
                        ("Switch Brand", switchBrand.isEmpty ? nil : switchBrand, nil),
                        ("Has WiFi", nil, hasWiFi),
                        ("WiFi Brand", wifiBrand.isEmpty ? nil : wifiBrand, nil),
                        ("Wired or WiFi", wiredOrWifi.isEmpty ? nil : wiredOrWifi, nil)
                    ]
                    coreDataManager.saveAssessmentFields(for: selectedCompany, category: "Network", fields: fields)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isSaving = false
                    }
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedCompany.isEmpty || isSaving)
            }
            .padding()
        }
        .onAppear {
            guard !selectedCompany.isEmpty else { return }
            let fields = coreDataManager.loadAllAssessmentFields(for: selectedCompany, category: "Network")
            for field in fields {
                switch field.fieldName {
                case "Has Firewall": hasFirewall = field.valueString == "true"
                case "Firewall Brand": firewallBrand = field.valueString ?? ""
                case "Firewall Licensed": firewallLicensed = field.valueString == "true"
                case "Has Switches": hasSwitches = field.valueString == "true"
                case "Switch Brand": switchBrand = field.valueString ?? ""
                case "Has WiFi": hasWiFi = field.valueString == "true"
                case "WiFi Brand": wifiBrand = field.valueString ?? ""
                case "Wired or WiFi": wiredOrWifi = field.valueString ?? ""
                default: break
                }
            }
        }
    }
}

struct IconCounterView: View {
        var label: String
        var icon: String
        @Binding var count: String
        @Binding var isManaged: Bool

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .foregroundColor(.blue)

                Text(label)
                    .font(.subheadline)

                TextField("0", text: $count)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                Toggle("Managed", isOn: $isManaged)
                    .labelsHidden()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
