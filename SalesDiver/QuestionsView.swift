import SwiftUI
import CoreData

struct QuestionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var questions: [BANTQuestion] = []
    @State private var selectedCategory: String = "Budget"
    @State private var questionText: String = ""
    @State private var isEditing: Bool = false
    @State private var editingQuestion: BANTQuestion?

    let categories = ["Budget", "Authority", "Need", "Timescale"]
    let icons = ["b.circle.fill", "a.circle.fill", "n.circle.fill", "t.circle.fill"]

    init() {
        loadDefaultQuestions()
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Questions")
                .font(.largeTitle)
                .bold()
                .padding()
            
            categorySelectionView
            questionInputView
            questionListView
        }
        .padding()
        .onAppear(perform: loadQuestions)
    }
    
    private var categorySelectionView: some View {
        HStack(spacing: 15) {
            ForEach(Array(categories.enumerated()), id: \.0) { index, category in
                Button(action: {
                    selectedCategory = category
                    loadQuestions()
                }) {
                    Image(systemName: icons[index])
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(selectedCategory == category ? .blue : .gray)
                }
            }
        }
        .padding()
    }
    
    private var questionInputView: some View {
        VStack {
            TextField("Enter BANT Question", text: $questionText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: saveQuestion) {
                Text(isEditing ? "Update Question" : "Add Question")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var questionListView: some View {
        List {
            ForEach(questions, id: \.id) { question in
                HStack {
                    Text(String(question.category?.prefix(1) ?? "?"))
                        .font(.title)
                        .bold()
                        .foregroundColor(.blue)
                    
                    Text(question.questionText ?? "")
                        .font(.body)
                    
                    Spacer()
                    
                    Button(action: { editQuestion(question) }) {
                        Image(systemName: "pencil.circle.fill").foregroundColor(.orange)
                    }
                    Button(action: { deleteQuestion(question) }) {
                        Image(systemName: "trash.fill").foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func saveQuestion() {
        if isEditing {
            editingQuestion?.questionText = questionText
        } else {
            let newQuestion = BANTQuestion(context: CoreDataManager.shared.context)
            newQuestion.id = UUID()
            newQuestion.category = selectedCategory
            newQuestion.questionText = questionText
            questions.append(newQuestion)
        }
        do {
            try CoreDataManager.shared.context.save()
        } catch {
            print("Failed to save Core Data: \(error.localizedDescription)")
        }
        resetForm()
        loadQuestions()
    }
    
    private func loadQuestions() {
        let bantOrder = ["B", "A", "N", "T"]
        questions = ((try? CoreDataManager.shared.context.fetch(BANTQuestion.fetchRequest()) as? [BANTQuestion]) ?? [])
            .sorted { lhs, rhs in
                let orderedCategories = [selectedCategory.prefix(1).uppercased()] + bantOrder
                let lhsIndex = orderedCategories.firstIndex(of: lhs.category?.prefix(1).uppercased() ?? "Z") ?? 4
                let rhsIndex = orderedCategories.firstIndex(of: rhs.category?.prefix(1).uppercased() ?? "Z") ?? 4
                return lhsIndex < rhsIndex
            }
    }
    
    private func editQuestion(_ question: BANTQuestion) {
        questionText = question.questionText ?? ""
        selectedCategory = question.category ?? "Budget"
        editingQuestion = question
        isEditing = true
    }
    
    private func deleteQuestion(_ question: BANTQuestion) {
        CoreDataManager.shared.context.delete(question)
        do {
            try CoreDataManager.shared.context.save()
        } catch {
            print("Failed to save Core Data: \(error.localizedDescription)")
        }
        loadQuestions()
    }
    
    private func resetForm() {
        questionText = ""
        isEditing = false
        editingQuestion = nil
    }
    
    private func loadDefaultQuestions() {
        let defaults: [(String, String)] = [
            ("Budget", "What budget has been allocated for this project or solution?"),
            ("Budget", "Are there any financial constraints we should be aware of?"),
            ("Budget", "How does this investment compare to other priorities within your organization?"),
            ("Budget", "Have you made similar purchases before? If so, what was your budget range?"),
            ("Budget", "Would you need internal approvals or additional funding to move forward?"),
            ("Authority", "Who is responsible for making the final decision on this purchase?"),
            ("Authority", "Are there any other stakeholders involved in the approval process?"),
            ("Authority", "Have you gone through a similar purchasing process before? How did it work?"),
            ("Authority", "Do you have the authority to sign off on this purchase, or is there a committee involved?"),
            ("Authority", "What criteria do decision-makers prioritize when evaluating solutions like this?"),
            ("Need", "What specific problem or challenge are you trying to solve?"),
            ("Need", "How are you currently handling this issue, and what are the limitations?"),
            ("Need", "What impact would solving this problem have on your business?"),
            ("Need", "What features or capabilities are most important in a solution?"),
            ("Need", "What would happen if you didn’t address this need?"),
            ("Timescale", "When are you looking to implement this solution?"),
            ("Timescale", "Are there any deadlines or external factors driving this timeline?"),
            ("Timescale", "How long has this issue been a priority for your company?"),
            ("Timescale", "Are there any internal approvals or processes that could delay implementation?"),
            ("Timescale", "What is your ideal timeline for seeing results from this investment?")
        ]
        
        let fetchRequest: NSFetchRequest<BANTQuestion> = BANTQuestion.fetchRequest()
        if let existingQuestions = try? CoreDataManager.shared.context.fetch(fetchRequest), existingQuestions.isEmpty {
            for (category, text) in defaults {
                let newQuestion = BANTQuestion(context: CoreDataManager.shared.context)
                newQuestion.id = UUID()
                newQuestion.category = category
                newQuestion.questionText = text
            }
            do {
                try CoreDataManager.shared.context.save()
            } catch {
                print("Failed to save default questions: \(error.localizedDescription)")
            }
        }
    }
}

struct QuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionsView()
    }
}
