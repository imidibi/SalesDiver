//
//  SCUBATANKIndicatorView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/10/25.
//



import SwiftUI

struct SCUBATANKIndicatorView: View {
    var opportunity: OpportunityWrapper
    var onItemSelected: (String) -> Void

    var body: some View {
        HStack(spacing: 15) {
            QualificationIcon(iconName: "lightbulb.fill", status: 0)
                .onTapGesture { onItemSelected("Solution") }
            QualificationIcon(iconName: "flag.fill", status: 0)
                .onTapGesture { onItemSelected("Competition") }
            QualificationIcon(iconName: "star.circle.fill", status: 0)
                .onTapGesture { onItemSelected("Uniques") }
            QualificationIcon(iconName: "gift.fill", status: 0)
                .onTapGesture { onItemSelected("Benefits") }
            QualificationIcon(iconName: "person.fill", status: opportunity.authorityStatus)
                .onTapGesture { onItemSelected("Authority") }
            QualificationIcon(iconName: "clock.fill", status: opportunity.timingStatus)
                .onTapGesture { onItemSelected("Timescale") }
            QualificationIcon(iconName: "checkmark.circle.fill", status: 0)
                .onTapGesture { onItemSelected("Action Plan") }
            QualificationIcon(iconName: "exclamationmark.circle.fill", status: opportunity.needStatus)
                .onTapGesture { onItemSelected("Need") }
            QualificationIcon(iconName: "dollarsign.circle.fill", status: opportunity.budgetStatus)
                .onTapGesture { onItemSelected("Kash") }
        }
    }
}
