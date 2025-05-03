//
//  OpportunityDataView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//

import SwiftUI
import CoreData

struct SelectedBANTItem: Identifiable {
    var id: NSManagedObjectID { opportunity.id }
    var opportunity: OpportunityWrapper
    var bantType: BANTIndicatorView.BANTType
}

enum OpportunitySortOption: String, CaseIterable {
    case companyName = "Company Name"
    case productName = "Product Name"
    case closeDate = "Close Date"
}

struct OpportunityDataView: View {
    @ObservedObject var viewModel = OpportunityViewModel()
    
    @State private var searchText: String = ""  // ✅ Search state
    @State private var sortOption: OpportunitySortOption = .companyName  // ✅ Default sorting

    @State private var selectedBANTItem: SelectedBANTItem? = nil  // Combined state for BANT Editing
    @State private var editingOpportunity: OpportunityWrapper?   // ✅ Used for Opportunity Editing
    @State private var isPresentingAddOpportunity = false  // ✅ Added state for modal
    @State private var isPresentingEditOpportunity = false // ✅ Added state for editing

    var filteredOpportunities: [OpportunityWrapper] {
        var opportunities = viewModel.opportunities

        // 🔍 Filter by search text
        if !searchText.isEmpty {
            opportunities = opportunities.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // 🔄 Apply sorting
        switch sortOption {
        case .companyName:
            opportunities.sort { $0.companyName < $1.companyName }
        case .productName:
            opportunities.sort { $0.productName < $1.productName }
        case .closeDate:
            opportunities.sort { $0.closeDate > $1.closeDate }  // Newest to Oldest
        }

        return opportunities
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 🔍 Search Bar
                HStack {
                    TextField("Search Opportunities", text: $searchText)
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

                // 🔄 Sorting Picker
                Picker("Sort by", selection: $sortOption) {
                    ForEach(OpportunitySortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // 📋 List of Opportunities
                List(filteredOpportunities, id: \.id) { opportunity in
                    HStack {
                        VStack(alignment: .leading) {
                            // ✅ Tap on Name to Open EditOpportunityView
                            Button(action: {
                                editingOpportunity = opportunity
                                isPresentingEditOpportunity = true
                            }) {
                                Text("Opportunity: \(opportunity.name)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }

                            Text("Company: \(opportunity.companyName)")
                                .foregroundColor(.gray)

                            Text("Close Date: \(opportunity.closeDate, style: .date)")

                            let trimmedProduct = opportunity.productName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedProduct.isEmpty && trimmedProduct.lowercased() != "unknown product" {
                                Text("Product: \(trimmedProduct)")
                                    .foregroundColor(.gray)
                            }

                            Text("Probability: \(opportunity.probability)%")
                            Text("Monthly Revenue: $\(opportunity.monthlyRevenue, specifier: "%.2f")")
                            Text("One-Time Revenue: $\(opportunity.onetimeRevenue, specifier: "%.2f")")
                            Text("Estimated Value: $\(opportunity.estimatedValue, specifier: "%.2f")")
                        }

                        Spacer()

                        // ✅ BANT Indicator remains intact
                        BANTIndicatorView(opportunity: opportunity) { bantType in
                            print("BANT icon pressed: \(bantType)")
                            selectedBANTItem = SelectedBANTItem(opportunity: opportunity, bantType: bantType)
                        }
                    }
                }
            }
            .navigationTitle("Opportunities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingAddOpportunity = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.fetchOpportunities()
            }
        
            .sheet(item: $selectedBANTItem) { item in
                BANTEditorView(viewModel: viewModel, opportunity: item.opportunity, bantType: item.bantType)
            }
            
            .sheet(isPresented: $isPresentingAddOpportunity) {
                AddOpportunityView(viewModel: viewModel)  // ✅ Opens Add Opportunity View
            }
            .sheet(item: $editingOpportunity) { opportunity in
                EditOpportunityView(viewModel: viewModel, opportunity: opportunity) // ✅ Opens Opportunity Edit View
            }
        }
    }
}
