//
//  EditMeetingView.swift
//  SalesDiver
//
//  Created by Ian Miller on 4/8/25.
//
import Foundation
import CoreData

class EditMeetingViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var date: Date = Date()
    @Published var objective: String = ""
    @Published var attendeeList: String = ""
    @Published var questions: [BANTQuestion] = []

    private let meeting: MeetingsEntity
    private let context: NSManagedObjectContext

    init(meeting: MeetingsEntity, context: NSManagedObjectContext) {
        self.meeting = meeting
        self.context = context
        loadData()
    }

    private func loadData() {
        title = meeting.title ?? ""
        date = meeting.date ?? Date()
        objective = meeting.objective ?? ""

        if let contacts = meeting.contacts as? Set<ContactsEntity> {
            attendeeList = contacts.map {
                [ $0.firstName, $0.lastName ]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }.joined(separator: ", ")
        }

        if let qSet = meeting.questions as? Set<BANTQuestion> {
            questions = Array(qSet)
        }
    }

    func removeQuestion(_ question: BANTQuestion) {
        if let index = questions.firstIndex(of: question) {
            questions.remove(at: index)
        }
    }

    func saveChanges() {
        meeting.title = title
        meeting.date = date
        meeting.objective = objective

        meeting.removeFromQuestions(meeting.questions ?? [])
        let questionSet = NSSet(array: questions)
        meeting.addToQuestions(questionSet)

        try? context.save()
    }
}
