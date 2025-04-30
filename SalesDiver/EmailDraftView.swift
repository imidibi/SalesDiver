//
//  EmailDraftView.swift
//  SalesDiver
//
//  Created by Ian Miller on 4/30/25.
//

import SwiftUI

struct EmailDraftView: View {
    let to: String
    let subject: String
    @Binding var emailText: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Group {
                    Text("To:")
                        .font(.headline)
                    Text(to)
                        .padding(.bottom, 5)

                    Text("Subject:")
                        .font(.headline)
                    Text(subject)
                        .padding(.bottom, 5)

                    Text("Body:")
                        .font(.headline)
                }

                TextEditor(text: $emailText)
                    .border(Color.gray.opacity(0.5), width: 1)
                    .padding(.bottom, 20)

                Spacer()

                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.red)

                    Spacer()

                    Button("Send Email") {
                        if let emailUrl = createEmailUrl(to: to, subject: subject, body: emailText) {
                            UIApplication.shared.open(emailUrl)
                        }
                        isPresented = false
                    }
                    .disabled(to.isEmpty)
                }
            }
            .padding()
            .navigationTitle("Email Draft")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        return URL(string: urlString)
    }
}
