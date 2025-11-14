//
//  AssessmentsHubView.swift
//  SalesDiver
//
//  Created by Ian Miller on 11/11/25.
//


import SwiftUI

struct AssessmentsHubView: View {
    @State private var assessments: [AssessmentDefinition] = []
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Saved Assessments")) {
                    ForEach(assessments) { def in
                        NavigationLink(destination: DynamicAssessmentView(definition: def)) {
                            Text(def.title)
                        }
                    }
                }
            }
            .navigationTitle("Assessments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showBuilder = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .onAppear(perform: refresh)
            .sheet(isPresented: $showBuilder, onDismiss: refresh) {
                NavigationStack { AssessmentBuilderView() }
            }
        }
        .task {
            await copySeedIfNeeded()
            refresh()
        }
    }

    private func refresh() {
        assessments = AssessmentStorage.loadAll()
    }
}

extension AssessmentsHubView {
    private func copySeedIfNeeded() async {
        let dir = AssessmentStorage.assessmentsDirectory()
        let seedName = "Security_Review.json"
        let target = dir.appendingPathComponent(seedName)
        guard !FileManager.default.fileExists(atPath: target.path) else { return }
        if let url = Bundle.main.url(forResource: "SecurityReview.seed", withExtension: "json") {
            if let data = try? Data(contentsOf: url) { try? data.write(to: target, options: .atomic) }
        }
    }
}

