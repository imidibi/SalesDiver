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
                                .onChange(of: companySearchText) { _, newValue in
                                    showCompanySearch = newValue.count >= 2
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
                                if area.0 == "EndPoints" {
                                    NavigationLink(destination: EndpointAssessmentView(selectedCompany: selectedCompany).environmentObject(coreDataManager)) {
                                        AssessmentGridItem(area: area, geometry: geometry)
                                    }
                                } else {
                                    AssessmentGridItem(area: area, geometry: geometry)
                                }
                            }
                        }
                        .padding(.bottom, 32) // Prevent content from being clipped at bottom
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
        var selectedCompany: String
        
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
                }
                .padding()
            }
            .navigationTitle("Endpoint Assessment")
            .onAppear {
                if !selectedCompany.isEmpty {
                    let allFields: [AssessmentFieldEntity] = coreDataManager.loadAllAssessmentFields(for: selectedCompany, category: "EndPoints")
                    for field in allFields {
                        switch field.fieldName {
                        case "Windows 11 PCs":
                            runsWindows11 = field.valueString == "true" || field.valueNumber == 1
                        case "Other Windows Version":
                            windowsVersion = field.valueString ?? ""
                        case "Devices MDM Managed":
                            hasMDM = field.valueString == "true" || field.valueNumber == 1
                        case "MDM Provider":
                            mdmProvider = field.valueString ?? ""
                        case "Acceptable Use Policy":
                            hasAUP = field.valueString == "true" || field.valueNumber == 1
                        case "Allows BYOD":
                            allowsBYOD = field.valueString == "true" || field.valueNumber == 1
                        case "Encrypted Computers":
                            areEncrypted = field.valueString == "true" || field.valueNumber == 1
                        case "PC Count":
                            pcCount = field.valueString ?? String(Int(field.valueNumber))
                        case "Mac Count":
                            macCount = field.valueString ?? String(Int(field.valueNumber))
                        case "iPhone Count":
                            iphoneCount = field.valueString ?? String(Int(field.valueNumber))
                        case "iPad Count":
                            ipadCount = field.valueString ?? String(Int(field.valueNumber))
                        case "Chromebook Count":
                            chromebookCount = field.valueString ?? String(Int(field.valueNumber))
                        case "Android Count":
                            androidCount = field.valueString ?? String(Int(field.valueNumber))
                        case "Other Count":
                            otherCount = field.valueString ?? String(Int(field.valueNumber))
                        case "Manage PCs":
                            managePCs = field.valueString == "true" || field.valueNumber == 1
                        case "Manage Macs":
                            manageMacs = field.valueString == "true" || field.valueNumber == 1
                        case "Manage iPhones":
                            manageiPhones = field.valueString == "true" || field.valueNumber == 1
                        case "Manage iPads":
                            manageiPads = field.valueString == "true" || field.valueNumber == 1
                        case "Manage Chromebooks":
                            manageChromebooks = field.valueString == "true" || field.valueNumber == 1
                        case "Manage Android":
                            manageAndroid = field.valueString == "true" || field.valueNumber == 1
                        case "Manage Other":
                            manageOther = field.valueString == "true" || field.valueNumber == 1
                        default:
                            break
                        }
                    }
                } else {
                    print("❗️Skipping load — selectedCompany is empty")
                }
            }
            .onDisappear {
                let assessmentFieldData: [(String, String?, Bool?)] = [
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
                    ("MDM Provider", mdmProvider, nil),
                    ("Acceptable Use Policy", nil, hasAUP),
                    ("Allows BYOD", nil, allowsBYOD),
                    ("Encrypted Computers", nil, areEncrypted)
                ]

                print("💾 Attempting to save assessment for: \(selectedCompany)")
                for field in assessmentFieldData {
                    print("   - Field: \(field.0), ValueNumber: \(field.1 ?? "nil"), Managed: \(String(describing: field.2))")
                }
                coreDataManager.saveAssessmentFields(for: selectedCompany, category: "EndPoints", fields: assessmentFieldData)
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
