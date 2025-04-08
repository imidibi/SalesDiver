import SwiftUI
import CoreData

struct EditMeetingSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool

    @StateObject private var viewModel: EditMeetingViewModel

    init(meeting: MeetingsEntity, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: EditMeetingViewModel(meeting: meeting, context: meeting.managedObjectContext!))
        _isPresented = isPresented
    }

    var body: some View {
        mainView
    }

    private var meetingDetailsSection: some View {
        Section {
            TextField("Title", text: $viewModel.title)
            DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
            Text(viewModel.attendeeList)
            TextField("Objective", text: $viewModel.objective)
        } header: {
            Text("Meeting Details")
        }
    }

    @ViewBuilder
    private var selectedQuestionsSection: some View {
        if viewModel.questions.isEmpty {
            Section(header: Text("Selected Questions")) {
                Text("No questions selected")
                    .foregroundColor(.gray)
            }
        } else {
            Section(header: Text("Selected Questions")) {
                ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { index, question in
                    HStack {
                        Text(question.questionText ?? "")
                        Spacer()
                        Button(role: .destructive) {
                            viewModel.removeQuestion(question)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }

    private var mainView: some View {
        NavigationView {
            Form {
                meetingDetailsSection
                selectedQuestionsSection
            }
            .navigationTitle("Edit Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveChanges()
                        isPresented = false
                    }
                }
            }
        }
    }
}
