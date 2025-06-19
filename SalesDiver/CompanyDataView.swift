//
//  CompanyDataView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//


import SwiftUI
import CoreData
import MapKit

// Codable wrapper for AI profile cache
struct CodableAIProfileCacheItem: Codable {
    let text: String
    let date: Date
}


struct CompanyDataView: View {
    @ObservedObject var viewModel: CompanyViewModel
    @State private var isShowingAddSheet = false
    @State private var selectedCompany: CompanyWrapper?
    @State private var searchText: String = ""  // ✅ Search state
    @State private var showAlert = false // Add state to trigger the alert
    @State private var isShowingAIProfile = false
    @State private var aiProfileText: String = ""
    @AppStorage("aiProfileCache") private var aiProfileCacheData: Data = Data()
    @State private var aiProfileCache: [String: (text: String, date: Date)] = [:]

    // 🔍 Filtered Companies
    var filteredCompanies: [CompanyWrapper] {
        let query = searchText.lowercased()
        return viewModel.companies.filter { company in
            query.isEmpty || company.name.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 🔍 Search Bar
                HStack {
                    TextField("Search Companies", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing)
                    .opacity(searchText.isEmpty ? 0 : 1)  // Hide if no search text
                }
                .padding(.top)

                List {
                    ForEach(filteredCompanies.indices, id: \.self) { index in
                        let company = filteredCompanies[index]
                        
                        HStack {
                            VStack(alignment: .leading) {
                                // ✅ Tap on Name to Open EditCompanyView
                                Button(action: {
                                    selectedCompany = company
                                }) {
                                    Text(company.name)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }

                                Text(company.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                if !company.address2.isEmpty { // ✅ Skip address2 if blank
                                    Text(company.address2)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

                                Text("\(company.city), \(company.state) \(company.zipCode)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                if !company.mainContact.isEmpty {
                                    Text("Contact: \(company.mainContact)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Type: \(company.companyTypeDescription)")
                                    .font(.subheadline)
                                    .foregroundColor(colorForCompanyType(company.companyType))
                            }
                            .padding()

                            Spacer()

                            // 📍 Apple Maps Button
                            Button(action: {
                                openInAppleMaps(company: company)
                            }) {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if !company.webAddress.isEmpty, let url = URL(string: (company.webAddress.starts(with: "http") ? company.webAddress : "https://\(company.webAddress)")) {
                                Button(action: {
                                    UIApplication.shared.open(url)
                                }) {
                                    Image(systemName: "globe")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // 🧠 AI Company Profile Button
                            Button(action: {
                                fetchAIProfile(for: company)
                            }) {
                                Image(systemName: "person.crop.rectangle")
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteCompany(at: IndexSet(integer: index))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteCompany)
                }
            }
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
            }
            .sheet(item: $selectedCompany) { company in
                EditCompanyView(viewModel: viewModel, company: company) // ✅ Opens EditCompanyView
            }
            .sheet(isPresented: $isShowingAddSheet, onDismiss: {
                viewModel.fetchCompanies()
            }) {
                AddCompanyView(viewModel: viewModel)
            }
            .alert(isPresented: $showAlert) { // Display alert if there's an error message
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.deletionErrorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK")) {
                        viewModel.deletionErrorMessage = nil // Clear the message after showing
                    }
                )
            }
            .onChange(of: viewModel.deletionErrorMessage) {
                if viewModel.deletionErrorMessage != nil {
                    showAlert = true
                }
            }
            .sheet(isPresented: $isShowingAIProfile) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Company Profile")
                            .font(.title)
                            .bold()
                        if let cached = aiProfileCache.first(where: { $0.value.text == aiProfileText }) {
                            Button("Update Profile") {
                                if let company = filteredCompanies.first(where: { $0.name == cached.key }) {
                                    aiProfileText = "Loading..."
                                    AIRecommendationManager.generateCompanyProfile(for: company) { result in
                                        Task {
                                            await MainActor.run {
                                                aiProfileCache[company.name] = (result, Date())
                                                let codableCache = aiProfileCache.mapValues { CodableAIProfileCacheItem(text: $0.text, date: $0.date) }
                                                if let encoded = try? JSONEncoder().encode(codableCache) {
                                                    aiProfileCacheData = encoded
                                                }
                                                aiProfileText = result
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()

                            let date = cached.value.date
                            Text("Last updated: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.bottom, 4)
                        }
                        Text(aiProfileText)
                            .font(.body)
                            .padding()
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                if let decoded = try? JSONDecoder().decode([String: CodableAIProfileCacheItem].self, from: aiProfileCacheData) {
                    aiProfileCache = decoded.mapValues { ($0.text, $0.date) }
                }
            }
        }
    }

    private func deleteCompany(at offsets: IndexSet) {
        offsets.forEach { index in
            let company = viewModel.companies[index]
            viewModel.deleteCompany(company: company)
            if viewModel.deletionErrorMessage == nil {
                viewModel.companies.remove(atOffsets: offsets)
            }
        }
    }

    private func colorForCompanyType(_ type: Int) -> Color {
        switch type {
        case 1:
            return .green // Customer
        case 2:
            return .yellow // Lead
        case 3:
            return .blue // Prospect
        default:
            return .gray
        }
    }

    // ✅ Function to Open in Apple Maps
    private func openInAppleMaps(company: CompanyWrapper) {
        let addressString = "\(company.address) \(company.city), \(company.state) \(company.zipCode)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "http://maps.apple.com/?q=\(addressString)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func fetchAIProfile(for company: CompanyWrapper) {
        let cacheKey = company.name
        if let cached = aiProfileCache[cacheKey] {
            aiProfileText = cached.text
            isShowingAIProfile = true
            return
        }

        aiProfileText = "Loading..."
        isShowingAIProfile = true

        AIRecommendationManager.generateCompanyProfile(for: company) { result in
            Task {
                await MainActor.run {
                    aiProfileCache[cacheKey] = (result, Date())
                    let codableCache = aiProfileCache.mapValues { CodableAIProfileCacheItem(text: $0.text, date: $0.date) }
                    if let encoded = try? JSONEncoder().encode(codableCache) {
                        aiProfileCacheData = encoded
                    }
                    aiProfileText = result
                }
            }
        }
    }
}
