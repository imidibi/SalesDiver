//
//  SCUBATANKEditorView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/10/25.
//



import SwiftUI

struct SCUBATANKEditorView: View {
    @ObservedObject var viewModel: OpportunityViewModel
    var opportunity: OpportunityWrapper
    @State private var selectedStatus: Int = 0
    @State private var commentary: String = ""
    var elementType: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit \(elementType) Status")
                .font(.headline)

            Picker("Status", selection: $selectedStatus) {
                Text("Not Qualified").tag(0)
                Text("In Progress").tag(1)
                Text("Qualified").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())

            TextField("Add commentary...", text: $commentary)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Save") {
                viewModel.updateSCUBATANKStatus(for: opportunity, elementType: elementType, status: selectedStatus, commentary: commentary)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear {
            let statusInfo = viewModel.getSCUBATANKStatus(for: opportunity, elementType: elementType)
            selectedStatus = statusInfo.status
            commentary = statusInfo.commentary
        }
    }
}
