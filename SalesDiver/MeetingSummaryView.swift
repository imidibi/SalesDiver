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

                // Qualification Status Placeholder (expand later)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Qualification Summary:")
                        .font(.headline)
                    Text("Status overview of BANT / MEDDIC / SCUBATANK goes here.")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Meeting Summary")
    }
}
