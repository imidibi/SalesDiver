//
//  ProductDataView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//
import SwiftUI
import CoreData

struct ProductDataView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var isShowingAddSheet = false
    @State private var selectedProduct: ProductWrapper?

    var body: some View {
        NavigationStack {
            VStack {
                // 🔍 Search Bar
                TextField("Search products...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: viewModel.searchText) {
                        viewModel.fetchProducts()
                    }
                // 🔀 Sorting Options
                Picker("Sort by", selection: $viewModel.sortOption) {
                    ForEach(ProductSortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: viewModel.searchText) {
                    viewModel.fetchProducts()
                }

                List {
                    ForEach(viewModel.products) { product in
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                            Text("Cost: $\(product.costPrice, specifier: "%.2f") | Sale: $\(product.salePrice, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .onTapGesture {
                            selectedProduct = product
                        }
                    }
                    .onDelete(perform: deleteProduct)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Product Data")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
            }
            .sheet(item: $selectedProduct) { product in
                EditProductView(viewModel: viewModel, product: product)
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddProductView(viewModel: viewModel)
            }
        }
    }

    private func deleteProduct(at offsets: IndexSet) {
        for index in offsets {
            let product = viewModel.products[index]
            viewModel.deleteProduct(product: product)
        }
        viewModel.products.remove(atOffsets: offsets)
    }
}
