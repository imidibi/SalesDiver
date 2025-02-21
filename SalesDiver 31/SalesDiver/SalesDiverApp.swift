//
//  SalesDiverApp.swift
//  SalesDiver
//
//  Created by Ian Miller on 2/19/25.
//

import SwiftUI
import CoreData

@main
struct SalesDiverApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
