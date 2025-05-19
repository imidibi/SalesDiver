//
//  HandwritingCaptureView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/19/25.
//
import SwiftUI

struct HandwritingCaptureView: View {
    var onSave: (String) -> Void
    @State private var handwrittenText = ""

    var body: some View {
        VStack {
            TextEditor(text: $handwrittenText)
                .frame(height: 200)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                .padding()

            Button("Save Notes") {
                onSave(handwrittenText)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Handwritten Notes")
    }
}
