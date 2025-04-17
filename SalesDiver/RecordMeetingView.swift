import SwiftUI
import CoreData

struct RecordMeetingView: View {
    let meeting: MeetingsEntity
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentQuestionIndex = 0
    @StateObject private var speechManager = SpeechManager()
    @State private var currentAnswer = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Meeting Info Header
            Group {
                Text(meeting.title ?? "Untitled Meeting")
                    .font(.title)
                    .bold()

                if let date = meeting.date {
                    Text("Date: \(date, formatter: dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                if let company = meeting.company {
                    Text("Company: \(company.name ?? "Unknown Company")")
                        .font(.subheadline)
                }

                if let contacts = meeting.contacts as? Set<ContactsEntity>, !contacts.isEmpty {
                    let attendeeNames = contacts.map { "\($0.firstName ?? "") \($0.lastName ?? "")" }.joined(separator: ", ")
                    Text("Attendees: \(attendeeNames)")
                        .font(.subheadline)
                }

                if let objective = meeting.objective {
                    Text("Objective: \(objective)")
                        .font(.subheadline)
                        .italic()
                }

                if let opportunityEntity = meeting.opportunity {
                    let wrapper = OpportunityWrapper(managedObject: opportunityEntity)
                    BANTIndicatorView(opportunity: wrapper, onBANTSelected: { _ in })
                        .scaleEffect(0.8)
                }
            }

            Divider()

            // Question and Answer Section
            let sortedQuestions = (meeting.questions as? Set<MeetingQuestionEntity>)?.sorted { ($0.questionText ?? "") < ($1.questionText ?? "") } ?? []

            if currentQuestionIndex < sortedQuestions.count {
                let question = sortedQuestions[currentQuestionIndex]

                VStack(alignment: .leading, spacing: 12) {
                    Text("Question \(currentQuestionIndex + 1) of \(sortedQuestions.count):")
                        .font(.headline)

                    Text(question.questionText ?? "")
                        .font(.body)

                    TextEditor(text: $speechManager.transcribedText)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                        .onChange(of: speechManager.transcribedText) {
                            currentAnswer = speechManager.transcribedText
                            question.answer = speechManager.transcribedText
                            try? viewContext.save()
                        }

                    HStack {
                        Button("Start Recording") {
                            try? speechManager.startTranscribing()
                        }
                        Button("Stop Recording") {
                            speechManager.stopTranscribing()
                        }
                    }

                    Button("Next Question") {
                        question.answer = currentAnswer
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error saving answer: \(error.localizedDescription)")
                        }
                        currentAnswer = ""
                        currentQuestionIndex += 1
                    }
                    .padding(.top)
                }
            } else {
                Text("All questions answered. Thank you!")
                    .font(.title2)
                    .padding(.top)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Record Meeting")
        .navigationBarBackButtonHidden(false)
    }
}

// Helper DateFormatter for displaying date
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
