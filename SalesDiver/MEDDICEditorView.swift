//
//  MEDDICEditorView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/10/25.
//

import SwiftUI

struct MEDDICEditorView: View {
    @ObservedObject var viewModel: OpportunityViewModel
    var opportunity: OpportunityWrapper
    @State private var selectedStatus: Int = 0
    @State private var commentary: String = ""
    var metricType: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit \(metricType) Status")
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
                viewModel.updateMEDDICStatus(for: opportunity, metricType: metricType, status: selectedStatus, commentary: commentary)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear {
            let statusInfo = viewModel.getMEDDICStatus(for: opportunity, metricType: metricType)
            selectedStatus = statusInfo.status
            commentary = statusInfo.commentary
        }
    }
}
