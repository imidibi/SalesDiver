//
//  AssessmentTemplateInterchange.swift
//  SalesDiver
//
//  Created by Assistant on 12/5/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - CSV Codec

enum CSVCodec {
    // Numeric mapping for field kinds
    // 1 = icon, 2 = number, 3 = text, 4 = yes/no, 5 = multipleChoice, 6 = date
    static func code(for kind: AssessmentFieldKind) -> Int {
        switch kind {
        case .icon: return 1
        case .number: return 2
        case .text: return 3
        case .yesno: return 4
        case .multipleChoice: return 5
        case .date: return 6
        }
    }

    static func kind(for code: Int) throws -> AssessmentFieldKind {
        switch code {
        case 1: return .icon
        case 2: return .number
        case 3: return .text
        case 4: return .yesno
        case 5: return .multipleChoice
        case 6: return .date
        default:
            throw CSVError.invalidKindCode
        }
    }

    enum CSVError: Error, LocalizedError {
        case invalidFormat
        case invalidKindCode
        case missingTemplateTitle
        case missingSectionTitle
        case missingFieldTitle
        case unexpectedRowType

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Invalid CSV format."
            case .invalidKindCode: return "Unknown field type code."
            case .missingTemplateTitle: return "Missing template title."
            case .missingSectionTitle: return "Missing section title."
            case .missingFieldTitle: return "Missing field title."
            case .unexpectedRowType: return "Unexpected row type."
            }
        }
    }

    // Encoding a single template to CSV
    static func encode(definition: AssessmentDefinition) -> Data {
        var rows: [[String]] = []

        // Instructional header as commented lines for human readers
        rows.append(["# Assessment Template CSV"])
        rows.append(["# Row formats:"])
        rows.append(["# TemplateTitle,<Title>"])
        rows.append(["# Section,<Section Title>"])
        rows.append(["# Field,<Field Title>,<KindCode>,<IconSystemName>,<OptionsPipeSeparated>,<DateISO8601>"])
        rows.append(["# Kind codes: 1=icon, 2=number, 3=text, 4=yes/no, 5=multipleChoice, 6=date"])
        rows.append(["# Notes:"])
        rows.append(["# - IconSystemName only used when KindCode=1 (icon)"])
        rows.append(["# - Options only used when KindCode=5 (multipleChoice), e.g. Option A|Option B|Option C"])
        rows.append(["# - DateISO8601 only used when KindCode=6 (date), e.g. 2025-12-05T00:00:00Z"])
        rows.append([])

        rows.append(["TemplateTitle", definition.title])

        for section in definition.sections {
            rows.append(["Section", section.title])
            for field in section.fields {
                let kindCode = code(for: field.kind)
                let iconName = field.iconSystemName ?? ""
                let optionsString = field.options.map { $0.title }.joined(separator: "|")
                let dateString: String
                if let d = field.dateValue {
                    dateString = ISO8601DateFormatter().string(from: d)
                } else {
                    dateString = ""
                }
                rows.append([
                    "Field",
                    field.title,
                    String(kindCode),
                    iconName,
                    optionsString,
                    dateString
                ])
            }
        }

        let csv = makeCSV(from: rows)
        return Data(csv.utf8)
    }

    // Decoding a single template from CSV
    static func decode(data: Data) throws -> AssessmentDefinition {
        guard let text = String(data: data, encoding: .utf8) else {
            throw CSVError.invalidFormat
        }
        let lines = text.split(whereSeparator: \.isNewline).map { String($0) }

        var title: String?
        var sections: [AssessmentSectionDefinition] = []
        var currentSection: AssessmentSectionDefinition?
        var seenTemplateTitle = false

        func pushCurrentSectionIfNeeded() {
            if let s = currentSection {
                sections.append(s)
                currentSection = nil
            }
        }

        for rawLine in lines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("#") { continue } // ignore comments

            let cols = parseCSVRow(trimmed)

            guard let first = cols.first?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty else {
                continue
            }

            if first.caseInsensitiveCompare("TemplateTitle") == .orderedSame {
                // TemplateTitle,<Title>
                guard cols.count >= 2 else { throw CSVError.missingTemplateTitle }
                title = cols[1]
                seenTemplateTitle = true
                continue
            }

            if first.caseInsensitiveCompare("Section") == .orderedSame {
                // Section,<Section Title>
                guard cols.count >= 2 else { throw CSVError.missingSectionTitle }
                // Close previous section if open
                pushCurrentSectionIfNeeded()
                currentSection = AssessmentSectionDefinition(title: cols[1], fields: [])
                continue
            }

            if first.caseInsensitiveCompare("Field") == .orderedSame {
                // Field,<Field Title>,<KindCode>,<IconSystemName>,<OptionsPipeSeparated>,<DateISO8601>
                guard cols.count >= 3 else { throw CSVError.missingFieldTitle }
                let fieldTitle = cols[1]
                let codeString = cols[2].trimmingCharacters(in: .whitespacesAndNewlines)
                guard let code = Int(codeString) else { throw CSVError.invalidKindCode }
                let kind = try kind(for: code)
                var field = AssessmentFieldDefinition(title: fieldTitle, kind: kind)

                if cols.count >= 4, !cols[3].isEmpty {
                    field.iconSystemName = cols[3]
                }
                if cols.count >= 5, !cols[4].isEmpty, kind == .multipleChoice {
                    let titles = cols[4].split(separator: "|").map { String($0) }
                    field.options = titles.map { AssessmentFieldOption(title: $0) }
                }
                if cols.count >= 6, !cols[5].isEmpty, kind == .date {
                    field.dateValue = ISO8601DateFormatter().date(from: cols[5])
                }

                if currentSection == nil {
                    // If a field appears before any section, create a default section
                    currentSection = AssessmentSectionDefinition(title: "Section 1", fields: [])
                }
                currentSection?.fields.append(field)
                continue
            }

            // If we get here, it’s an unknown row type
            throw CSVError.unexpectedRowType
        }

        // Finalize last section
        pushCurrentSectionIfNeeded()

        guard seenTemplateTitle, let finalTitle = title else {
            throw CSVError.missingTemplateTitle
        }

        return AssessmentDefinition(title: finalTitle, sections: sections)
    }

    // Blank instructional CSV for users to fill in
    static func blankTemplateCSV() -> Data {
        var rows: [[String]] = []
        rows.append(["# Assessment Template CSV - Blank"])
        rows.append(["# Fill this in and import it back into the app."])
        rows.append(["# Row formats:"])
        rows.append(["# TemplateTitle,<Title>"])
        rows.append(["# Section,<Section Title>"])
        rows.append(["# Field,<Field Title>,<KindCode>,<IconSystemName>,<OptionsPipeSeparated>,<DateISO8601>"])
        rows.append(["# Kind codes: 1=icon, 2=number, 3=text, 4=yes/no, 5=multipleChoice, 6=date"])
        rows.append(["# Notes:"])
        rows.append(["# - Put exactly one TemplateTitle row at the top."])
        rows.append(["# - Add as many Section rows as you need."])
        rows.append(["# - Add Field rows under each Section."])
        rows.append(["# - IconSystemName is an SF Symbol name when KindCode=1 (e.g. \"lock.fill\")."])
        rows.append(["# - For multipleChoice, list options separated by | (pipe), e.g. \"Basic|Standard|Premium\"."])
        rows.append(["# - DateISO8601 example: 2025-12-05T00:00:00Z"])
        rows.append([])

        // Minimal sample skeleton the user can overwrite
        rows.append(["TemplateTitle", "New Assessment"])
        rows.append(["Section", "Section 1"])
        rows.append(["Field", "Intro Icon", "1", "lock.fill", "", ""])
        rows.append(["Field", "Your Name", "3", "", "", ""])
        rows.append(["Field", "Your Budget", "2", "", "", ""])
        rows.append(["Field", "Approved?", "4", "", "", ""])
        rows.append(["Field", "Plan Tier", "5", "", "Basic|Standard|Premium", ""])
        rows.append(["Field", "Review Date", "6", "", "", "2025-12-05T00:00:00Z"])

        let csv = makeCSV(from: rows)
        return Data(csv.utf8)
    }

    // MARK: - CSV helpers (simple, with quoting)
    private static func makeCSV(from rows: [[String]]) -> String {
        rows.map { row in
            row.map { csvEscape($0) }.joined(separator: ",")
        }.joined(separator: "\n") + "\n"
    }

    private static func csvEscape(_ field: String) -> String {
        // Escape if contains quote, comma, newline, or leading/trailing space
        var needsQuotes = false
        if field.contains(",") || field.contains("\n") || field.contains("\r") || field.contains("\"") || field.hasPrefix(" ") || field.hasSuffix(" ") || field.hasPrefix("#") {
            needsQuotes = true
        }
        var value = field.replacingOccurrences(of: "\"", with: "\"\"")
        if needsQuotes {
            value = "\"\(value)\""
        }
        return value
    }

    private static func parseCSVRow(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var chars = Array(line)
        var i = 0

        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        current.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(c)
                }
            } else {
                if c == "\"" {
                    inQuotes = true
                } else if c == "," {
                    result.append(current)
                    current = ""
                } else {
                    current.append(c)
                }
            }
            i += 1
        }
        result.append(current)
        return result
    }
}

// MARK: - Document pickers

struct CSVImportPicker: UIViewControllerRepresentable {
    typealias Completion = (URL?) -> Void
    let onPick: Completion

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.commaSeparatedText, .plainText]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: Completion
        init(onPick: @escaping Completion) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}

struct CSVExportShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension View {
    func presentCSVExport(_ url: URL) -> some View {
        self.sheet(isPresented: .constant(true)) {
            CSVExportShareSheet(fileURL: url)
        }
    }
}

