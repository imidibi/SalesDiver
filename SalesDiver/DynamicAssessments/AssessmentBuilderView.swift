//
//  AssessmentBuilderView 2.swift
//  SalesDiver
//
//  Created by Ian Miller on 11/11/25.
//


import SwiftUI

struct AssessmentBuilderView: View {
    // If provided, we will load the builder with this saved definition for editing
    private let existingDefinition: AssessmentDefinition?

    init(existingDefinition: AssessmentDefinition? = nil) {
        self.existingDefinition = existingDefinition
        // Initialize backing state from existing definition if present
        if let def = existingDefinition {
            _title = State(initialValue: def.title)
            _sections = State(initialValue: def.sections)
        } else {
            _title = State(initialValue: "New Assessment")
            _sections = State(initialValue: [AssessmentSectionDefinition(title: "Section 1", fields: [])])
        }
        _saveMessage = State(initialValue: "")
    }
    
    @State private var title: String
    @State private var sections: [AssessmentSectionDefinition]
    @State private var saveMessage: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Assessment Title")) {
                TextField("Title", text: $title)
            }
            
            ForEach($sections) { $section in
                Section(header: Text(section.title)) {
                    TextField("Section Title", text: $section.title)
                    ForEach($section.fields) { $field in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Field Title", text: $field.title)
                            Picker("Type", selection: $field.kind) {
                                ForEach(AssessmentFieldKind.allCases) { kind in
                                    Text(kind.rawValue.capitalized).tag(kind)
                                }
                            }
                            if field.kind == .icon {
                                TextField("SF Symbol (e.g., desktopcomputer)", text: Binding(
                                    get: { field.iconSystemName ?? "" },
                                    set: { field.iconSystemName = $0 }
                                ))
                            }
                            if field.kind == .multipleChoice {
                                MultipleChoiceEditor(options: Binding(
                                    get: { field.options ?? [] },
                                    set: { field.options = $0 }
                                ))
                            }
                        }
                    }
                    Button("Add Field") {
                        section.fields.append(AssessmentFieldDefinition(title: "New Field", kind: .text))
                    }
                }
            }
            Button("Add Section") {
                sections.append(AssessmentSectionDefinition(title: "New Section", fields: []))
            }
            
            Section {
                Button("Save Assessment") { saveAssessment() }
                if !saveMessage.isEmpty {
                    Text(saveMessage)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Assessment Builder")
    }
    
    private func saveAssessment() {
        var def = AssessmentDefinition(title: title, sections: sections)
        if let existing = existingDefinition {
            // Preserve ID so the logical assessment stays the same
            def.id = existing.id
            // If the title changed, remove the old file that used the previous title-based name
            let oldTitle = existing.title
            if oldTitle != title {
                let oldName = AssessmentStorage.sanitized(oldTitle) + ".json"
                let oldURL = AssessmentStorage.assessmentsDirectory().appendingPathComponent(oldName)
                try? FileManager.default.removeItem(at: oldURL)
            }
        }
        do {
            try AssessmentStorage.save(def)
            saveMessage = "Saved to Documents/Assessments as \(AssessmentStorage.sanitized(title)).json"
            // Return to the assessments list after a successful save
            dismiss()
        } catch {
            saveMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

private struct MultipleChoiceEditor: View {
    @Binding var options: [AssessmentFieldOption]
    @State private var newOption: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Options").font(.subheadline)
            ForEach(options) { opt in
                Text("• \(opt.title)")
            }
            HStack {
                TextField("Add option", text: $newOption)
                Button("Add") {
                    let trimmed = newOption.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    options.append(AssessmentFieldOption(title: trimmed))
                    newOption = ""
                }
            }
        }
    }
}
