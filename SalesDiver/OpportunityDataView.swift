//
//  OpportunityDataView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//

import SwiftUI

enum OpportunitySortOption: String, CaseIterable {
    case companyName = "Company Name"
    case productName = "Product Name"
    case closeDate = "Close Date"
}

struct OpportunityDataView: View {
    @ObservedObject var viewModel = OpportunityViewModel()
    
    @State private var searchText: String = ""  // ✅ Search state
    @State private var sortOption: OpportunitySortOption = .companyName  // ✅ Default sorting

    @State private var selectedOpportunity: OpportunityWrapper?  // ✅ Used for BANT Editing
    @State private var editingOpportunity: OpportunityWrapper?   // ✅ Used for Opportunity Editing
    @State private var showingBANTEditor = false
    @State private var selectedBANT: BANTIndicatorView.BANTType = .budget
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

                            Text("Product: \(opportunity.productName)")
                                .foregroundColor(.gray)

                            Text("Quantity: \(opportunity.quantity)")
                            Text("Price: $\(opportunity.customPrice, specifier: "%.2f")")
                        }

                        Spacer()

                        // ✅ BANT Indicator remains intact
                        BANTIndicatorView(opportunity: opportunity) { bantType in
                            selectedOpportunity = opportunity
                            selectedBANT = bantType
                            showingBANTEditor = true
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
            .sheet(item: $selectedOpportunity) { opportunity in
                BANTEditorView(viewModel: viewModel, opportunity: opportunity, bantType: selectedBANT) // ✅ Opens BANT Editor
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
