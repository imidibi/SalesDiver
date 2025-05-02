//
//  EditOpportunityView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//

import SwiftUI
import CoreData  // ✅ Added CoreData import

struct EditOpportunityView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: OpportunityViewModel
    var opportunity: OpportunityWrapper

    @State private var name: String = ""
    @State private var closeDate: Date = Date()

    @State private var selectedProduct: ProductWrapper?
    @State private var isSelectingProduct: Bool = false
    @StateObject private var productViewModel = ProductViewModel()

    @State private var probability: Int = 0
    @State private var monthlyRevenue: String = ""
    @State private var onetimeRevenue: String = ""
    @State private var estimatedValue: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // 🎯 Section: Company Information (Static)
                Section(header: Text("Company")) {
                    Text(opportunity.companyName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                // 🎯 Section: Opportunity Details
                Section(header: Text("Opportunity Details")) {
                    TextField("Opportunity Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    DatePicker("Close Date", selection: $closeDate, displayedComponents: .date)

                    // 🎯 Selectable Product Field
                    Button(action: { isSelectingProduct = true }) {
                        HStack {
                            Text("Product")
                            Spacer()
                            Text(selectedProduct?.name ?? opportunity.productName)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // 🎯 Section: Financial Details
                Section(header: Text("Financial Details")) {
                    Stepper("Probability: \(probability)%", value: $probability, in: 0...100)

                    TextField("Monthly Revenue", text: $monthlyRevenue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("One-Time Revenue", text: $onetimeRevenue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Estimated Value", text: $estimatedValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // 🎯 Delete Button
                Section {
                    Button(role: .destructive, action: deleteOpportunity) {
                        Label("Delete Opportunity", systemImage: "trash")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Opportunity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveOpportunity()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingData()
            }
            .sheet(isPresented: $isSelectingProduct) {
                ProductSelectionModalView(products: productViewModel.products) { product in  // ✅ Uses correct view
                    selectedProduct = product
                }
            }
        }
    }

    private func loadExistingData() {
        name = opportunity.name
        closeDate = opportunity.closeDate

        probability = opportunity.probability
        monthlyRevenue = String(format: "%.2f", opportunity.monthlyRevenue)
        onetimeRevenue = String(format: "%.2f", opportunity.onetimeRevenue)
        estimatedValue = String(format: "%.2f", opportunity.estimatedValue)

        // ✅ Set initial selected product
        if let product = productViewModel.products.first(where: { $0.name == opportunity.productName }) {
            selectedProduct = product
        }
    }

    private func saveOpportunity() {
        guard let monthly = Double(monthlyRevenue),
              let onetime = Double(onetimeRevenue),
              let estimated = Double(estimatedValue) else { return }

        // ✅ Fetch the correct ProductEntity from Core Data
        var updatedProduct: NSManagedObject? = opportunity.managedObject.value(forKey: "product") as? NSManagedObject

        if let selectedProductName = selectedProduct?.name {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ProductEntity")
            fetchRequest.predicate = NSPredicate(format: "name == %@", selectedProductName)

            do {
                let matchingProducts = try CoreDataManager.shared.context.fetch(fetchRequest)
                updatedProduct = matchingProducts.first
            } catch {
                print("⚠️ Error fetching selected product: \(error)")
            }
        }

        viewModel.updateOpportunity(
            opportunity: opportunity,
            name: name,
            closeDate: closeDate,
            probability: Int16(probability),
            monthlyRevenue: monthly,
            onetimeRevenue: onetime,
            estimatedValue: estimated
        )

        // ✅ Ensure product is updated separately if needed
        if let updatedProduct = updatedProduct {
            opportunity.managedObject.setValue(updatedProduct, forKey: "product")
            CoreDataManager.shared.saveContext()
        }
    }

    private func deleteOpportunity() {
        viewModel.deleteOpportunity(opportunity: opportunity)  // ✅ Correct function call
        dismiss()
    }
}
