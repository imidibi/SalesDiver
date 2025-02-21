//
//  PersistenceController.swift
//  SalesDiver
//
//  Created by Ian Miller on 2/19/25.
//
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "SalesDiverModel") // Must match your .xcdatamodeld filename
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

