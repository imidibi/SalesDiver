//
//  IconCounterView.swift
//  SalesDiver
//
//  Created by Ian Miller on 4/19/25.
//
import SwiftUI

struct IconCounterView: View {
    var label: String
    var icon: String
    @Binding var count: String
    @Binding var isManaged: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(height: 30)
                .foregroundColor(.blue)

            Text(label)
                .font(.subheadline)

            TextField("0", text: $count)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            Toggle("Managed", isOn: $isManaged)
                .labelsHidden()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
