//
//  BANTEditorView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//

import SwiftUI

struct BANTEditorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: OpportunityViewModel
    var opportunity: OpportunityWrapper  // ✅ FIX: Use global `OpportunityWrapper`
    var bantType: BANTIndicatorView.BANTType

    @State private var selectedStatus: Int = 0
    @State private var commentary: String = ""

    var title: String {
        switch bantType {
        case .budget: return "Budget Qualification"
        case .authority: return "Authority Qualification"
        case .need: return "Need Qualification"
        case .timing: return "Timing Qualification"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select Qualification Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        Text("Not Qualified").tag(0)
                        Text("In Process").tag(1)
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
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveQualification()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }

    private func loadExistingData() {
        switch bantType {
        case .budget:
            selectedStatus = opportunity.budgetStatus
            commentary = opportunity.budgetCommentary
        case .authority:
            selectedStatus = opportunity.authorityStatus
            commentary = opportunity.authorityCommentary
        case .need:
            selectedStatus = opportunity.needStatus
            commentary = opportunity.needCommentary
        case .timing:
            selectedStatus = opportunity.timingStatus
            commentary = opportunity.timingCommentary
        }
    }

    private func saveQualification() {
        viewModel.updateBANT(opportunity: opportunity, bantType: bantType, status: selectedStatus, commentary: commentary)
    }
}
