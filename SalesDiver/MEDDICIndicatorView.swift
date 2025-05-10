//
//  MEDDICIndicatorView.swift
//  SalesDiver
//
//  Created by Ian Miller on 5/10/25.
//



import SwiftUI

struct MEDDICIndicatorView: View {
    var opportunity: OpportunityWrapper
    var onItemSelected: (String) -> Void

    var body: some View {
        HStack(spacing: 15) {
            QualificationIcon(iconName: "dollarsign.circle.fill", status: opportunity.budgetStatus)
                .onTapGesture { onItemSelected("Metrics") }
            QualificationIcon(iconName: "person.fill", status: opportunity.authorityStatus)
                .onTapGesture { onItemSelected("Economic Buyer") }
            QualificationIcon(iconName: "exclamationmark.circle.fill", status: opportunity.needStatus)
                .onTapGesture { onItemSelected("Identify Pain") }
            QualificationIcon(iconName: "clock.fill", status: opportunity.timingStatus)
                .onTapGesture { onItemSelected("Decision Process") }
            // Placeholder for additional MEDDIC elements
            QualificationIcon(iconName: "checkmark.circle.fill", status: 0)
                .onTapGesture { onItemSelected("Decision Criteria") }
            QualificationIcon(iconName: "star.circle.fill", status: 0)
                .onTapGesture { onItemSelected("Champion") }
        }
    }
}
