//
//  BANTQuestion+CoreDataProperties.swift
//  SalesDiver
//
//  Created by Ian Miller on 2/28/25.
//
//

import Foundation
import CoreData


extension BANTQuestion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BANTQuestion> {
        return NSFetchRequest<BANTQuestion>(entityName: "BANTQuestion")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var category: String?
    @NSManaged public var questionText: String?

}

extension BANTQuestion : Identifiable {

}
