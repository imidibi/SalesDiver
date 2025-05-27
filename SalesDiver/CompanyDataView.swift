//
//  CompanyDataView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//

import SwiftUI
import CoreData
import MapKit

struct CompanyDataView: View {
    @ObservedObject var viewModel: CompanyViewModel
    @State private var isShowingAddSheet = false
    @State private var selectedCompany: CompanyWrapper?
    @State private var searchText: String = ""  // ✅ Search state
    @State private var showAlert = false // Add state to trigger the alert

    // 🔍 Filtered Companies
    var filteredCompanies: [CompanyWrapper] {
        if searchText.isEmpty {
            return viewModel.companies
        } else {
            let searchQuery = searchText.lowercased()
            var filtered: [CompanyWrapper] = []
            
            for company in viewModel.companies {
                if company.name.lowercased().contains(searchQuery) {
                    filtered.append(company)
                }
            }
            
            return filtered
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
}
