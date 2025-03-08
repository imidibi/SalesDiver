//
//  BANTIndicatorView.swift
//  iPadtester
//
//  Created by Ian Miller on 2/15/25.
//
import SwiftUI

struct BANTIndicatorView: View {
    var opportunity: OpportunityWrapper  // ✅ Uses global OpportunityWrapper
    var onBANTSelected: (BANTType) -> Void

    enum BANTType {
        case budget, authority, need, timing
    }

    var body: some View {
        HStack(spacing: 15) {
            BANTIcon(type: .budget, status: opportunity.budgetStatus)
                .onTapGesture { onBANTSelected(.budget) }
            BANTIcon(type: .authority, status: opportunity.authorityStatus)
                .onTapGesture { onBANTSelected(.authority) }
            BANTIcon(type: .need, status: opportunity.needStatus)
                .onTapGesture { onBANTSelected(.need) }
            BANTIcon(type: .timing, status: opportunity.timingStatus)
                .onTapGesture { onBANTSelected(.timing) }
        }
    }
}

// ✅ Define BANTIcon inside the same file
struct BANTIcon: View {
    var type: BANTIndicatorView.BANTType
    var status: Int

    var icon: String {
        switch type {
        case .budget: return "dollarsign.circle.fill"
        case .authority: return "person.fill"
        case .need: return "exclamationmark.circle.fill"
        case .timing: return "clock.fill"
        }
    }

    var color: Color {
        switch status {
        case 0: return .red     // Not Qualified
        case 1: return .yellow  // In Process
        case 2: return .green   // Qualified
        default: return .gray
        }
    }

    var body: some View {
        Image(systemName: icon)
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(color)
    }
}
