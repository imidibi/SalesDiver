//
//  MeetingSummaryView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/19/25.
//
import SwiftUI
import CoreData

struct MeetingSummaryView: View {
    @ObservedObject var meeting: MeetingsEntity

    @AppStorage("selectedMethodology") private var currentMethodology: String = "BANT"
    @State private var showingQualificationEditor = false
    @State private var editorType: String = ""
    @State private var selectedBANTType: BANTIndicatorView.BANTType?
    @State private var selectedMEDDICType: MEDDICType?
    @State private var selectedSCUBATANKType: SCUBATANKType?
    @StateObject private var viewModel = OpportunityViewModel()
    @State private var selectedOpportunity: OpportunityWrapper?
    @State private var aiRecommendation: String = ""

    var body: some View {
        let resolvedDate = meeting.date ?? Date()
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Header Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title ?? "Untitled Meeting")
                        .font(.title2)
                        .bold()
                    Text(resolvedDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let company = meeting.company?.name {
                        Text("Company: \(company)")
                    }
                    if let opportunity = meeting.opportunity?.name {
                        Text("Opportunity: \(opportunity)")
                    }
                    if let objective = meeting.objective {
                        Text("Objective: \(objective)")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Divider()

                // Attendees
                if let attendees = meeting.contacts as? Set<ContactsEntity>, !attendees.isEmpty {
                    let sortedAttendees = attendees.sorted(by: {
                        let nameA = "\($0.firstName ?? "") \($0.lastName ?? "")"
                        let nameB = "\($1.firstName ?? "") \($1.lastName ?? "")"
                        return nameA < nameB
                    })
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attendees:")
                            .font(.headline)
                        ForEach(sortedAttendees, id: \.self) { contact in
                            Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                        }
                    }
                    Divider()
                }

                // Questions & Notes
                if let questions = meeting.questions as? Set<MeetingQuestionEntity>, !questions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Questions & Notes:")
                            .font(.headline)
                        let sortedQuestions = questions.sorted(by: { ($0.questionText ?? "") < ($1.questionText ?? "") })
                        ForEach(sortedQuestions, id: \.self) { question in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(question.questionText ?? "")
                                    .font(.subheadline)
                                    .bold()
                                Text(question.answer ?? "No notes captured.")
                                    .foregroundColor(.secondary)
                                if let answer = question.answer, answer.contains("[INSIGHT]") {
                                    Text("⭐ Key Insight Identified")
                                        .foregroundColor(.yellow)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    Divider()
                }

                // Transcription
                if let transcript = meeting.notes, !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Full Transcription:")
                            .font(.headline)
                        Text(transcript)
                            .foregroundColor(.secondary)
                    }
                    Divider()
                }

                // Qualification Status Section with interactive icons
                VStack(alignment: .leading, spacing: 4) {
                    Text("Qualification Summary:")
                        .font(.headline)
                    Text("Please edit the qualification status based on the meeting outcome:")
                        .foregroundColor(.secondary)
                    if let opportunity = meeting.opportunity {
                        let wrapper = OpportunityWrapper(managedObject: opportunity)
                        switch currentMethodology {
                        case "BANT":
                            BANTIndicatorView(opportunity: wrapper, onBANTSelected: { selected in
                                selectedOpportunity = wrapper
                                selectedBANTType = selected
                                editorType = "BANT"
                                showingQualificationEditor = true
                            })
                        case "MEDDIC":
                            MEDDICIndicatorView(opportunity: wrapper, onMEDDICSelected: { selected in
                                selectedOpportunity = wrapper
                                selectedMEDDICType = selected
                                editorType = "MEDDIC"
                                showingQualificationEditor = true
                            })
                        case "SCUBATANK":
                            SCUBATANKIndicatorView(opportunity: wrapper, onSCUBATANKSelected: { selected in
                                selectedOpportunity = wrapper
                                selectedSCUBATANKType = selected
                                editorType = "SCUBATANK"
                                showingQualificationEditor = true
                            })
                        default:
                            EmptyView()
                        }
                    }
                }

                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Recommendation:")
                        .font(.headline)
                    Text(aiRecommendation)
                        .foregroundColor(.primary)
                        .padding(.top, 2)
                    Button("Generate Recommendation") {
                        generateAIRecommendation()
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            if aiRecommendation.isEmpty,
               let saved = meeting.aiRecommendation,
               !saved.isEmpty {
                aiRecommendation = saved
            }
        }
        .navigationTitle("Meeting Summary")
        .sheet(isPresented: $showingQualificationEditor) {
            QualificationEditorRouter(
                editorType: editorType,
                wrapper: selectedOpportunity,
                bantType: selectedBANTType,
                meddicType: selectedMEDDICType,
                scubatankType: selectedSCUBATANKType,
                viewModel: viewModel
            )
        }
    }
    private func generateAIRecommendation() {
        var summary = ""

        if let questions = meeting.questions as? Set<MeetingQuestionEntity> {
            let answered = questions
                .filter { ($0.answer ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
                .map { "Q: \($0.questionText ?? "")\nA: \($0.answer ?? "")" }
                .joined(separator: "\n\n")
            summary += "Meeting Q&A:\n" + answered + "\n\n"
        }

        if let opportunity = meeting.opportunity {
            let wrapper = OpportunityWrapper(managedObject: opportunity)
            summary += "Qualification Summary:\n"
            summary += "Budget: \(wrapper.budgetStatus)\n"
            summary += "Authority: \(wrapper.authorityStatus)\n"
            summary += "Need: \(wrapper.needStatus)\n"
            summary += "Timing: \(wrapper.timingStatus)\n"
        }

        let prompt = """
This data represents the latest sales meeting between a Managed service provider sales person and their prospect, as well as the sales person's latest qualification assessment. Given this, what would be the logical next step for the sales person to do? Please create a recommendation for the sales person, which can include qualifying out of the deal if the situation looks like it will be time wasted.

\(summary)
"""

        guard let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty else {
            aiRecommendation = "⚠️ OpenAI API key is not set."
            return
        }

        let model = UserDefaults.standard.string(forKey: "openAISelectedModel") ?? ""
        let chosenModel = model.isEmpty ? "gpt-4" : model

        let body: [String: Any] = [
            "model": chosenModel,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant for sales strategy in the managed IT services space."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 400
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        aiRecommendation = "Generating recommendation..."

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let result = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
                   let message = result.choices.first?.message.content {
                    aiRecommendation = message.trimmingCharacters(in: .whitespacesAndNewlines)
                    meeting.aiRecommendation = aiRecommendation
                    try? meeting.managedObjectContext?.save()
                } else {
                    if let data = data,
                       let debug = String(data: data, encoding: .utf8) {
                        if debug.contains("insufficient_quota") {
                            aiRecommendation = "⚠️ Your OpenAI account has no available quota. Please visit https://platform.openai.com/account/billing to update your plan."
                        } else {
                            aiRecommendation = "❌ OpenAI error: \(debug)"
                        }
                    } else if let error = error {
                        aiRecommendation = "❌ Request failed: \(error.localizedDescription)"
                    } else {
                        aiRecommendation = "⚠️ Failed to retrieve recommendation from OpenAI."
                    }
                }
            }
        }.resume()
    }
}

struct QualificationEditorRouter: View {
    let editorType: String
    let wrapper: OpportunityWrapper?
    let bantType: BANTIndicatorView.BANTType?
    let meddicType: MEDDICType?
    let scubatankType: SCUBATANKType?
    let viewModel: OpportunityViewModel

    var body: some View {
        if let wrapper = wrapper {
            switch editorType {
            case "BANT":
                if let type = bantType {
                    BANTEditorView(viewModel: viewModel, opportunity: wrapper, bantType: type)
                } else {
                    Text("Missing BANT type")
                }
            case "MEDDIC":
                if let type = meddicType {
                    MEDDICEditorView(viewModel: viewModel, opportunity: wrapper, metricType: type.rawValue)
                } else {
                    Text("Missing MEDDIC type")
                }
            case "SCUBATANK":
                if let type = scubatankType {
                    SCUBATANKEditorView(viewModel: viewModel, opportunity: wrapper, elementType: type.rawValue)
                } else {
                    Text("Missing SCUBATANK type")
                }
            default:
                Text("Unknown qualification method")
            }
        } else {
            ProgressView("Loading...")
        }
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    struct Choice: Codable {
        let message: Message
    }
    struct Message: Codable {
        let content: String
    }
}
