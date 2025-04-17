//
//  AssessmentView.swift
//  SalesDiver
//
//  Created by Ian Miller on 4/16/25.
//

import SwiftUI
import CoreData

struct AssessmentView: View {
    @State private var selectedCompany: String = ""
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
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 20) {
                    Text("Assessment")
                        .font(.largeTitle)
                        .bold()
                    
                    Button(action: {
                        showCompanySearch = true
                    }) {
                        HStack {
                            Text(selectedCompany.isEmpty ? "Select Company" : selectedCompany)
                                .foregroundColor(selectedCompany.isEmpty ? .gray : .primary)
                            Spacer()
                            Image(systemName: "magnifyingglass")
                        }
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                    }
                    
                    DatePicker("Date", selection: $assessmentDate, displayedComponents: .date)
                        .padding(.trailing)
                    
                    Text("Select Area to Assess:")
                        .font(.headline)
                    
                    let columns = Array(repeating: GridItem(.flexible(minimum: 0)), count: 5)
                    
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
                    }

                    if showCompanySearch {
                        VStack(alignment: .leading) {
                            TextField("Search companies...", text: $companySearchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()

                            ScrollView {
                                let filteredCompanies = allCompanies.filter {
                                    companySearchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(companySearchText) ?? false)
                                }
                                ForEach(filteredCompanies, id: \.self) { company in
                                    Button(action: {
                                        selectedCompany = company.name ?? ""
                                        showCompanySearch = false
                                    }) {
                                        Text(company.name ?? "")
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .background(Color.white)
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding()
                        .shadow(radius: 5)
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
    
    struct AssessmentGridItem: View {
        let area: (String, String)
        let geometry: GeometryProxy
        
        var body: some View {
            let totalSpacing: CGFloat = 20 * 4  // 5 columns means 4 gaps
            let itemWidth = (geometry.size.width - totalSpacing - 40) / 5  // 40 is extra horizontal padding
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
        @State private var linuxCount: String = ""
        @State private var iphoneCount: String = ""
        @State private var ipadCount: String = ""
        @State private var chromebookCount: String = ""
        @State private var androidCount: String = ""
        
        @State private var managePCs: Bool = false
        @State private var manageMacs: Bool = false
        @State private var manageLinux: Bool = false
        @State private var manageiPhones: Bool = false
        @State private var manageiPads: Bool = false
        @State private var manageChromebooks: Bool = false
        @State private var manageAndroid: Bool = false
        
        var body: some View {
            Form {
                Section(header: Text("Endpoint Counts")) {
                    deviceRow(label: "PCs", systemImage: "desktopcomputer", count: $pcCount, managed: $managePCs)
                    deviceRow(label: "Macs", systemImage: "laptopcomputer", count: $macCount, managed: $manageMacs)
                    deviceRow(label: "Linux Devices", systemImage: "terminal", count: $linuxCount, managed: $manageLinux)
                    deviceRow(label: "iPhones", systemImage: "iphone", count: $iphoneCount, managed: $manageiPhones)
                    deviceRow(label: "iPads", systemImage: "ipad", count: $ipadCount, managed: $manageiPads)
                    deviceRow(label: "Chromebooks", systemImage: "display", count: $chromebookCount, managed: $manageChromebooks)
                    deviceRow(label: "Android Devices", systemImage: "phone", count: $androidCount, managed: $manageAndroid)
                }
            }
            .navigationTitle("Endpoint Assessment")
            .onAppear {
                coreDataManager.loadAssessmentFields(for: selectedCompany, into: &pcCount, &macCount, &linuxCount, &iphoneCount, &ipadCount, &chromebookCount, &androidCount, &managePCs, &manageMacs, &manageLinux, &manageiPhones, &manageiPads, &manageChromebooks, &manageAndroid)
            }
            .onDisappear {
                coreDataManager.saveAssessmentFields(for: selectedCompany, fields: [
                    ("PC Count", pcCount, nil),
                    ("Mac Count", macCount, nil),
                    ("Linux Count", linuxCount, nil),
                    ("iPhone Count", iphoneCount, nil),
                    ("iPad Count", ipadCount, nil),
                    ("Chromebook Count", chromebookCount, nil),
                    ("Android Count", androidCount, nil),
                    ("Manage PCs", nil, managePCs),
                    ("Manage Macs", nil, manageMacs),
                    ("Manage Linux", nil, manageLinux),
                    ("Manage iPhones", nil, manageiPhones),
                    ("Manage iPads", nil, manageiPads),
                    ("Manage Chromebooks", nil, manageChromebooks),
                    ("Manage Android", nil, manageAndroid)
                ])
            }
        }
        
        func deviceRow(label: String, systemImage: String, count: Binding<String>, managed: Binding<Bool>) -> some View {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.blue)
                
                Text(label)
                    .frame(width: 100, alignment: .leading)
                
                TextField("0", text: count)
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                
                Spacer()
                
                VStack {
                    Text("Managed")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Toggle("", isOn: managed)
                        .labelsHidden()
                }
            }
            .padding(.vertical, 4)
        }
    }
}
