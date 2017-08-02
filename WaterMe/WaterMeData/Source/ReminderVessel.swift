//
//  ReminderVessel.swift
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

import Result
import UIKit
import RealmSwift

public protocol UserFacingError: Swift.Error {
    var alertTitle: String { get }
    var alertMessage: String { get }
}

public protocol UICompleteCheckable {
    associatedtype E: UserFacingError
    var isUIComplete: [E] { get }
}

public class ReminderVessel: Object {
    
    public enum Kind: String {
        case plant
    }
    
    public internal(set) dynamic var uuid = UUID().uuidString
    public internal(set) dynamic var displayName: String?
    public let reminders = List<Reminder>()
    
    private dynamic var iconImageData: Data?
    private dynamic var iconEmojiString: String?
    public internal(set) var icon: Icon? {
        get { return Icon(rawImageData: self.iconImageData, emojiString: self.iconEmojiString) }
        set {
            self.iconImageData = newValue?.dataValue
            self.iconEmojiString = newValue?.stringValue
        }
    }
    
    private dynamic var kindString = Kind.plant.rawValue
    public internal(set) var kind: Kind {
        get { return Kind(rawValue: self.kindString) ?? .plant }
        set { self.kindString = newValue.rawValue }
    }
    
    override public class func primaryKey() -> String {
        return #keyPath(ReminderVessel.uuid)
    }
}

extension ReminderVessel: UICompleteCheckable {
    
    public enum Error: UserFacingError {
        case missingIcon, missingName, noReminders
        public var alertTitle: String {
            switch self {
            case .missingIcon:
                return "Missing Photo"
            case .missingName:
                return "Missing Name"
            case .noReminders:
                return "Missing Reminders"
            }
        }
        public var alertMessage: String {
            switch self {
            case .missingIcon:
                return "Please choose a photo or an emoji for your plant."
            case .missingName:
                return "Please name your plant."
            case .noReminders:
                return "Each plant must have at least one reminder."
            }
        }
    }
    
    public typealias E = Error
    
    public var isUIComplete: [Error] {
        let errors: [Error] = [
            self.icon == nil ? .missingIcon : nil,
            self.displayName == nil ? .missingName : nil,
            self.reminders.isEmpty ? .noReminders : nil
        ].flatMap({ $0 })
        return errors
    }
}
