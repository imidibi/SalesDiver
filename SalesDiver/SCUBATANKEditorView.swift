//
//  SCUBATANKEditorView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/10/25.
//

import SwiftUI

struct SCUBATANKEditorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: OpportunityViewModel
    var opportunity: OpportunityWrapper
    var elementType: String

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
            .navigationTitle("\(elementType) Qualification")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("Saving SCUBATANK - Element: \(elementType), Status: \(selectedStatus), Commentary: \(commentary)")
                        viewModel.updateSCUBATANKStatus(for: opportunity, elementType: elementType, status: selectedStatus, commentary: commentary)
                        dismiss()
                    }
                }
            }
            .onAppear {
                let statusInfo = viewModel.getSCUBATANKStatus(for: opportunity, elementType: elementType)
                print("Loaded SCUBATANK - Element: \(elementType), Status: \(statusInfo.status), Commentary: \(statusInfo.commentary)")
                selectedStatus = statusInfo.status
                commentary = statusInfo.commentary
            }
        }
    }
}
