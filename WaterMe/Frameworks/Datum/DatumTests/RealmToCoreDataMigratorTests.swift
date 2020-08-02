//
//  RealmToCoreDataMigratorTests.swift
//  DatumTests
//
//  Created by Jeffrey Bergier on 2020/08/02.
//  Copyright © 2020 Saturday Apps.
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

import XCTest
@testable import Datum

class RealmToCoreDataMigratorBaseTests: XCTestCase {

    let source = try! RLM_BasicController(kind: .local, forTesting: true)
    let destination = try! CD_BasicController(kind: .local, forTesting: true)

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let realmDir = RLM_BasicController.localRealmDirectory
        let coreDataDir = CD_BasicController.dbDirectoryURL
        let fm = FileManager.default
        try? fm.removeItem(at: realmDir)
        try? fm.removeItem(at: coreDataDir)
    }
}

class RealmToCoreDataMigratorAccuracyTests: RealmToCoreDataMigratorBaseTests {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

}

class RealmToCoreDataMigratorScaleTests: RealmToCoreDataMigratorBaseTests {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

}