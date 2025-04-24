import SwiftUI

struct EditFollowUpView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var followUp: FollowUpsEntity

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Follow Up Details")) {
                    TextField("Name", text: Binding(
                        get: { followUp.name ?? "" },
                        set: { followUp.name = $0 }
                    ))
                    TextField("Assigned To", text: Binding(
                        get: { followUp.assignedTo ?? "" },
                        set: { followUp.assignedTo = $0 }
                    ))
                    DatePicker("Due Date", selection: Binding(
                        get: { followUp.dueDate ?? Date() },
                        set: { followUp.dueDate = $0 }
                    ), displayedComponents: .date)
                    Toggle("Completed", isOn: Binding(
                        get: { followUp.completed },
                        set: { followUp.completed = $0 }
                    ))
                }

                Button("Save") {
                    do {
                        try viewContext.save()
                        dismiss()
                    } catch {
                        print("Failed to save follow-up: \(error.localizedDescription)")
                    }
                }

                Button("Cancel", role: .cancel) {
                    viewContext.rollback()
                    dismiss()
                }
            }
            .navigationTitle("Edit Follow Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
