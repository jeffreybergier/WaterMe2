//
//  Reminder.swift
//  Pods
//
//  Created by Jeffrey Bergier on 5/31/17.
//  Copyright © 2017 Saturday Apps.
//
//  This file is part of WaterMe.  Simple Plant Watering Reminders for iOS.
//
//  WaterMe is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  WaterMe is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with WaterMe.  If not, see <http://www.gnu.org/licenses/>.
//

import RealmSwift
import Foundation

public class Reminder: Object {
    
    public static let minimumInterval: Int = 1
    public static let maximumInterval: Int = 180
    public static let defaultInterval: Int = 7
    
    public enum Kind {
        case water, fertilize, move(location: String?), other(title: String?, description: String?)
        public static let count = 4
    }
    
    // MARK: Public Interface
    public var kind: Kind {
        get { return self.kindValue }
        set { self.update(with: newValue) }
    }
    public internal(set) dynamic var interval: Int = Reminder.defaultInterval
    public let performed = List<ReminderPerform>()
    public var vessel: ReminderVessel? { return self.vessels.first }
    
    // MARK: Implementation Details
    internal dynamic var kindString: String = Reminder.kCaseWaterValue
    internal dynamic var titleString: String?
    internal dynamic var descriptionString: String?
    internal let vessels = LinkingObjects(fromType: ReminderVessel.self, property: "reminders") //#keyPath(ReminderVessel.reminders)
}

public class ReminderPerform: Object {
    public internal(set) var date = Date()
}

fileprivate extension Reminder {
    
    fileprivate static let kCaseWaterValue = "kReminderKindCaseWaterValue"
    fileprivate static let kCaseFertilizeValue = "kReminderKindCaseFertilizeValue"
    fileprivate static let kCaseMoveValue = "kReminderKindCaseMoveValue"
    fileprivate static let kCaseOtherValue = "kReminderKindCaseOtherValue"
    
    internal func update(with kind: Reminder.Kind) {
        switch kind {
        case .water:
            self.kindString = type(of: self).kCaseWaterValue
            self.titleString = nil
            self.descriptionString = nil
        case .fertilize:
            self.kindString = type(of: self).kCaseFertilizeValue
            self.titleString = nil
            self.descriptionString = nil
        case .move(let location):
            self.kindString = type(of: self).kCaseMoveValue
            self.titleString = nil
            self.descriptionString = location
        case .other(let title, let description):
            self.kindString = type(of: self).kCaseOtherValue
            self.titleString = title
            self.descriptionString = description
        }
    }
    
    var kindValue: Reminder.Kind {
        switch self.kindString {
        case type(of: self).kCaseWaterValue:
            return .water
        case type(of: self).kCaseFertilizeValue:
            return .fertilize
        case type(of: self).kCaseMoveValue:
            let description = self.descriptionString
            return .move(location: description)
        case type(of: self).kCaseOtherValue:
            let title = self.titleString
            let description = self.descriptionString
            return .other(title: title, description: description)
        default:
            fatalError("Reminder.Kind: Invalid Case String Key")
        }
    }
}
