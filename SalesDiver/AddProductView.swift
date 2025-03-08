//
//  AddProductView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//

import SwiftUI

struct AddProductView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProductViewModel

    @State private var name = ""
    @State private var costPrice = ""
    @State private var salePrice = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Product Information")) {
                    TextField("Product Name", text: $name)
                    TextField("Cost Price", text: $costPrice)
                        .keyboardType(.decimalPad)
                    TextField("Sale Price", text: $salePrice)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Product")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let cost = Double(costPrice), let sale = Double(salePrice) {
                            viewModel.addProduct(name: name, costPrice: cost, salePrice: sale)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || costPrice.isEmpty || salePrice.isEmpty)
                }
            }
        }
    }
}
