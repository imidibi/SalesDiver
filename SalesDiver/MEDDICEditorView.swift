//
//  MEDDICEditorView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/10/25.
//

import SwiftUI

struct MEDDICEditorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: OpportunityViewModel
    var opportunity: OpportunityWrapper
    var metricType: String

    @State private var selectedStatus: Int = 0
    @State private var commentary: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select Qualification Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        Text("Not Qualified").tag(0)
                        Text("In Progress").tag(1)
                        Text("Qualified").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Commentary")) {
                    TextEditor(text: $commentary)
                        .frame(height: 100)
                        .border(Color.gray, width: 1)
                }
            }
            .navigationTitle("\(metricType) Qualification")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateMEDDICStatus(for: opportunity, metricType: metricType, status: selectedStatus, commentary: commentary)
                        dismiss()
                    }
                }
            }
            .onAppear {
                let statusInfo = viewModel.getMEDDICStatus(for: opportunity, metricType: metricType)
                selectedStatus = statusInfo.status
                commentary = statusInfo.commentary
            }
        }
    }
}
