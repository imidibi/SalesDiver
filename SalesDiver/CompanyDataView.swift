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
    @StateObject private var viewModel = CompanyViewModel()
    @State private var isShowingAddSheet = false
    @State private var selectedCompany: CompanyWrapper?
    @State private var searchText: String = ""  // ✅ Search state

    // 🔍 Filtered Companies
    var filteredCompanies: [CompanyWrapper] {
        if searchText.isEmpty {
            return viewModel.companies
        } else {
            return viewModel.companies.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                    ForEach(filteredCompanies) { company in
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
                            .buttonStyle(PlainButtonStyle()) // ✅ Ensures only the icon is tappable
                        }
                    }
                    .onDelete(perform: deleteCompany)
                }
            }
            .navigationTitle("Company Data")
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
            .sheet(isPresented: $isShowingAddSheet) {
                AddCompanyView(viewModel: viewModel)
            }
        }
    }

    private func deleteCompany(at offsets: IndexSet) {
        offsets.forEach { index in
            let company = viewModel.companies[index]
            viewModel.deleteCompany(company: company)
        }
        viewModel.companies.remove(atOffsets: offsets)
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
