import SwiftUI

struct DynamicAssessmentView: View {
    let definition: AssessmentDefinition
    let companyID: String?
    let existingResponse: AssessmentResponse?
    
    init(definition: AssessmentDefinition, companyID: String? = nil, existingResponse: AssessmentResponse? = nil) {
        self.definition = definition
        self.companyID = companyID
        self.existingResponse = existingResponse
    }
    
    @State private var textValues: [UUID: String] = [:]
    @State private var numberValues: [UUID: Double] = [:]
    @State private var yesNoValues: [UUID: Bool] = [:]
    @State private var choiceValues: [UUID: UUID] = [:]
    @State private var dateValues: [UUID: Date] = [:]
    @State private var saveStatus: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(definition.title)
                    .font(.largeTitle)
                    .bold()
                HStack(spacing: 12) {
                    Button("Load Last") { loadLatest() }
                    Button("Save") { saveResponse() }
                    if !saveStatus.isEmpty { Text(saveStatus).font(.footnote).foregroundColor(.secondary) }
                }
                ForEach(definition.sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.title2)
                            .bold()
                        ForEach(section.fields) { field in
                            fieldView(field)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                }
            }
            .padding()
        }
        .onAppear {
            if let existing = existingResponse {
                preload(from: existing)
            } else {
                loadLatest()
            }
        }
    }
    
    @ViewBuilder
    private func fieldView(_ field: AssessmentFieldDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if field.kind == .icon {
                    if let name = field.iconSystemName, !name.isEmpty {
                        Image(systemName: name)
                            .foregroundColor(.blue)
                    }
                }
                Text(field.title).font(.headline)
            }
            switch field.kind {
            case .icon:
                Text("Icon field").foregroundColor(.secondary)
            case .text:
                TextField("Enter text", text: Binding(
                    get: { textValues[field.id] ?? "" },
                    set: { textValues[field.id] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
            case .number:
                TextField("0", value: Binding(
                    get: { numberValues[field.id] ?? 0 },
                    set: { numberValues[field.id] = $0 }
                ), format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            case .yesno:
                Toggle("", isOn: Binding(
                    get: { yesNoValues[field.id] ?? false },
                    set: { yesNoValues[field.id] = $0 }
                ))
                .labelsHidden()
            case .multipleChoice:
                let opts = field.options
                if opts.isEmpty {
                    Text("No options configured")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Select", selection: Binding(
                        get: { choiceValues[field.id] ?? opts.first?.id },
                        set: { choiceValues[field.id] = $0 }
                    )) {
                        ForEach(opts) { opt in
                            Text(opt.title).tag(opt.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            case .date:
                DatePicker("", selection: Binding(
                    get: { dateValues[field.id] ?? field.dateValue ?? Date() },
                    set: { dateValues[field.id] = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
            }
        }
    }
    
    private func saveResponse() {
        var values: [UUID: AssessmentResponseFieldValue] = [:]
        for section in definition.sections {
            for field in section.fields {
                var v = AssessmentResponseFieldValue()
                switch field.kind {
                case .text:
                    v.text = textValues[field.id]
                case .number:
                    v.number = numberValues[field.id]
                case .yesno:
                    v.yesNo = yesNoValues[field.id]
                case .multipleChoice:
                    v.choiceID = choiceValues[field.id]
                case .icon:
                    break
                case .date:
                    v.date = dateValues[field.id]
                }
                values[field.id] = v
            }
        }
        let response = AssessmentResponse(assessmentID: definition.id, assessmentTitle: definition.title, companyID: companyID, values: values)
        do {
            try AssessmentResponseStorage.save(response, for: definition)
            saveStatus = "Saved at \(Date().formatted(date: .numeric, time: .standard))"
        } catch {
            saveStatus = "Save failed: \(error.localizedDescription)"
        }
    }
    
    private func loadLatest() {
        guard let latest = AssessmentResponseStorage.loadLatest(for: definition) else {
            saveStatus = "No saved responses"
            return
        }
        for section in definition.sections {
            for field in section.fields {
                let v = latest.values[field.id]
                switch field.kind {
                case .text:
                    textValues[field.id] = v?.text ?? ""
                case .number:
                    numberValues[field.id] = v?.number ?? 0
                case .yesno:
                    yesNoValues[field.id] = v?.yesNo ?? false
                case .multipleChoice:
                    if let id = v?.choiceID { choiceValues[field.id] = id }
                case .icon:
                    break
                case .date:
                    if let d = v?.date { dateValues[field.id] = d }
                }
            }
        }
        saveStatus = "Loaded last saved"
    }
    
    private func preload(from response: AssessmentResponse) {
        for section in definition.sections {
            for field in section.fields {
                let v = response.values[field.id]
                switch field.kind {
                case .text:
                    textValues[field.id] = v?.text ?? ""
                case .number:
                    numberValues[field.id] = v?.number ?? 0
                case .yesno:
                    yesNoValues[field.id] = v?.yesNo ?? false
                case .multipleChoice:
                    if let id = v?.choiceID { choiceValues[field.id] = id }
                case .icon:
                    break
                case .date:
                    if let d = v?.date { dateValues[field.id] = d }
                }
            }
        }
        saveStatus = "Loaded saved assessment"
    }
}
