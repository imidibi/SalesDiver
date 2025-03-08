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

    init(viewModel: ProductViewModel, product: ProductWrapper) {
        self.viewModel = viewModel
        self.product = product
        _name = State(initialValue: product.name)
        _costPrice = State(initialValue: "\(product.costPrice)")
        _salePrice = State(initialValue: "\(product.salePrice)")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Product Information")) {
                    VStack(alignment: .leading) {
                        Text("Product Name").font(.headline)
                        TextField("Enter product name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Cost Price").font(.headline)
                        TextField("Enter cost price", text: $costPrice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }

                    VStack(alignment: .leading) {
                        Text("Sale Price").font(.headline)
                        TextField("Enter sale price", text: $salePrice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Convert strings to Double safely
                        let convertedCostPrice = Double(costPrice) ?? 0.0
                        let convertedSalePrice = Double(salePrice) ?? 0.0

                        // ✅ Correct function call now using `ProductWrapper`
                        viewModel.updateProduct(
                            product: product,
                            name: name,
                            costPrice: convertedCostPrice,
                            salePrice: convertedSalePrice
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
