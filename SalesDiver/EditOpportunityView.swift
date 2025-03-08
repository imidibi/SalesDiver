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
    @State private var quantity: String = ""
    @State private var customPrice: String = ""

    @State private var selectedProduct: ProductWrapper?
    @State private var isSelectingProduct: Bool = false
    @StateObject private var productViewModel = ProductViewModel()

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

                // 🎯 Section: Pricing & Quantity
                Section(header: Text("Pricing & Quantity")) {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: quantity) { _, _ in updatePrice() }

                    HStack {
                        Text("Total Price")
                        Spacer()
                        Text("$\(customPrice)")
                            .foregroundColor(.blue)
                    }
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
                    updatePrice()
                }
            }
        }
    }

    private func loadExistingData() {
        name = opportunity.name
        closeDate = opportunity.closeDate
        quantity = "\(opportunity.quantity)"
        customPrice = String(format: "%.2f", opportunity.customPrice)

        // ✅ Set initial selected product
        if let product = productViewModel.products.first(where: { $0.name == opportunity.productName }) {
            selectedProduct = product
        }
    }

    private func updatePrice() {
        guard let product = selectedProduct, let qty = Int(quantity) else { return }
        let calculatedPrice = product.salePrice * Double(qty)
        customPrice = String(format: "%.2f", calculatedPrice)
    }

    private func saveOpportunity() {
        guard let quantityInt = Int(quantity), let priceDouble = Double(customPrice) else { return }

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

        // ✅ Update Opportunity in Core Data (Fixed function signature)
        viewModel.updateOpportunity(
            opportunity: opportunity,
            name: name,
            closeDate: closeDate,
            quantity: quantityInt,
            customPrice: priceDouble
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
