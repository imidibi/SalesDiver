import SwiftUI

struct AddOpportunityView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: OpportunityViewModel
    @StateObject private var sheetManager = SheetManager()

    @State private var name: String = ""
    @State private var closeDate: Date = Date()
    @State private var selectedCompany: CompanyWrapper?
    @State private var selectedProduct: ProductWrapper?

    @State private var quantity: String = "1"
    @FocusState private var isQuantityFocused: Bool
    @State private var customPrice: String = ""
    @State private var isDatePickerVisible: Bool = false  // ✅ Toggle for DatePicker visibility

    @State private var companies: [CompanyWrapper] = []
    @State private var products: [ProductWrapper] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // 🎨 Opportunity Name Input
                        TextField("Opportunity Name", text: $name)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                            .padding(.horizontal)

                        // 🎨 Close Date Picker
                        VStack {
                            Button(action: { isDatePickerVisible.toggle() }) {
                                HStack {
                                    Text("Close Date: \(closeDate.formatted(date: .abbreviated, time: .omitted))")
                                    Spacer()
                                    Image(systemName: "calendar")
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                            }
                            .padding(.horizontal)

                            if isDatePickerVisible {
                                VStack {
                                    DatePicker("Select Close Date", selection: $closeDate, displayedComponents: .date)
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                        .padding()
                                    
                                    // ✅ "Done" Button to close picker
                                    Button("Done") {
                                        isDatePickerVisible = false
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // 🎨 Searchable Company Selector
                        SelectionCard(title: "Select Company", subtitle: selectedCompany?.name ?? "Tap to select") {
                            sheetManager.showCompanySearch()
                        }

                        // 🎨 Searchable Product Selector
                        SelectionCard(title: "Select Product", subtitle: selectedProduct?.name ?? "Tap to select") {
                            sheetManager.showProductSearch()
                        }

                        // 🎨 Pricing & Quantity
                        VStack(spacing: 10) {
                            HStack {
                                Text("Quantity:")
                                Spacer()
                                TextField("Enter quantity", text: $quantity)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: quantity) { oldValue, newValue in
                                        updatePrice()
                                    }
                                    .padding(8)
                                    .frame(width: 80)
                                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                            }

                            HStack {
                                Text("Custom Price:")
                                Spacer()
                                TextField("Enter price", text: $customPrice)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .padding(8)
                                    .frame(width: 120)
                                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Add Opportunity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveOpportunity()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCompany == nil || selectedProduct == nil || Double(customPrice) == nil)
                }
            }
            .onAppear(perform: loadCompaniesAndProducts)
            .sheet(item: $sheetManager.activeSheet) { sheet in
                switch sheet {
                case .companySearch:
                    SearchCompanyView(companies: companies) { company in
                        selectedCompany = company
                        sheetManager.dismiss()
                    }
                case .productSearch:
                    SearchProductView(products: products) { product in
                        selectedProduct = product
                        updatePrice()
                        sheetManager.dismiss()
                    }
                }
            }
        }
    }

    // 🎨 Custom Card for Selectable Fields
    private func SelectionCard(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .foregroundColor(subtitle == "Tap to select" ? .gray : .black)
                    .padding(.top, 2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 1))
            .padding(.horizontal)
        }
    }

    // ✅ Load Data
    private func loadCompaniesAndProducts() {
        let companyViewModel = CompanyViewModel()
        let productViewModel = ProductViewModel()
        companies = companyViewModel.companies
        products = productViewModel.products
    }

    // ✅ Auto-Calculate Price
    private func updatePrice() {
        guard let product = selectedProduct, let qty = Int(quantity) else { return }
        let calculatedPrice = product.salePrice * Double(qty)
        customPrice = String(format: "%.2f", calculatedPrice)
    }

    // ✅ Save Opportunity
    private func saveOpportunity() {
        guard let company = selectedCompany, let product = selectedProduct,
              let quantityInt = Int(quantity), let priceDouble = Double(customPrice) else { return }

        viewModel.addOpportunity(name: name, closeDate: closeDate, company: company, product: product, quantity: quantityInt, customPrice: priceDouble)
    }
}
