//
//  AssessmentBuilderView 2.swift
//  SalesDiver
//
//  Created by Ian Miller on 11/11/25.
//


import SwiftUI

struct AssessmentBuilderView: View {
    @State private var title: String = "New Assessment"
    @State private var sections: [AssessmentSectionDefinition] = [
        AssessmentSectionDefinition(title: "Section 1", fields: [])
    ]
    @State private var saveMessage: String = ""
    
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
        let def = AssessmentDefinition(title: title, sections: sections)
        do {
            try AssessmentStorage.save(def)
            saveMessage = "Saved to Documents/Assessments as \(AssessmentStorage.sanitized(title)).json"
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

