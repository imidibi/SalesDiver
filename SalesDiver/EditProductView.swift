//
//  EditProductView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//

import SwiftUI

struct EditProductView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProductViewModel
    var product: ProductWrapper  // ✅ Now using ProductWrapper instead of ProductEntity

    @State private var name: String
    @State private var costPrice: String
    @State private var salePrice: String
    @State private var type: String
    @State private var benefits: String
    @State private var prodDescription: String
    @State private var units: String

    init(viewModel: ProductViewModel, product: ProductWrapper) {
        self.viewModel = viewModel
        self.product = product
        _name = State(initialValue: product.name)
        _costPrice = State(initialValue: "\(product.costPrice)")
        _salePrice = State(initialValue: "\(product.salePrice)")
        _type = State(initialValue: product.type)
        _benefits = State(initialValue: product.benefits)
        _prodDescription = State(initialValue: product.prodDescription)
        _units = State(initialValue: product.units)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Product Information")) {
                    TextField("Product Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(["Hardware", "Software", "Service", "Labor", "Bundle"], id: \.self) { Text($0) }
                    }
                    Picker("Units", selection: $units) {
                        ForEach(["Per Device", "Per User", "Per Email User", "Per Site"], id: \.self) { Text($0) }
                    }
                }

                Section(header: Text("Pricing")) {
                    HStack {
                        Text("Cost Price: $")
                        TextField("0.00", text: $costPrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Sale Price: $")
                        TextField("0.00", text: $salePrice)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Description")) {
                    TextEditor(text: $prodDescription)
                        .frame(height: 100)
                }

                Section(header: Text("Benefits")) {
                    TextEditor(text: $benefits)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let convertedCostPrice = Double(costPrice) ?? 0.0
                        let convertedSalePrice = Double(salePrice) ?? 0.0

                        viewModel.updateProduct(
                            product: product,
                            name: name,
                            costPrice: convertedCostPrice,
                            salePrice: convertedSalePrice,
                            type: type,
                            benefits: benefits,
                            prodDescription: prodDescription,
                            units: units
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
