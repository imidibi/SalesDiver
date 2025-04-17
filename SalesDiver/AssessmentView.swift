//
//  AssessmentView.swift
//  SalesDiver
//
//  Created by Ian Miller on 4/16/25.
//

import SwiftUI

struct AssessmentView: View {
    @State private var selectedCompany: String = ""
    @State private var assessmentDate: Date = Date()

    let subjectAreas = [
        ("EndPoints", "desktopcomputer"),
        ("Servers", "server.rack"),
        ("Network", "network"),
        ("Phone System", "phone"),
        ("Email", "envelope"),
        ("Security & Compliance", "lock.shield"),
        ("Directory Services", "person.3"),
        ("Infrastructure", "building.2"),
        ("Cloud Services", "icloud"),
        ("Backup", "externaldrive")
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Assessment")
                    .font(.largeTitle)
                    .bold()

                TextField("Select Company", text: $selectedCompany)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.trailing)

                DatePicker("Date", selection: $assessmentDate, displayedComponents: .date)
                    .padding(.trailing)

                Text("Select Area to Assess:")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
                    ForEach(subjectAreas, id: \.0) { area in
                        VStack {
                            Image(systemName: area.1)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                                .padding(.top, 10)
                            Text(area.0)
                                .font(.caption)
                                .padding(.bottom, 10)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                        .onTapGesture {
                            // Placeholder for tap action
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct AssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        AssessmentView()
    }
}
