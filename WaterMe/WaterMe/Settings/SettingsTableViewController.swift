//
//  SettingsTableViewController.swift
//  WaterMe
//
//  Created by Jeffrey Bergier on 9/1/18.
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

import StoreKit
import WaterMeStore
import UIKit

class SettingsTableViewController: UITableViewController {

    var settingsRowChosen: ((SettingsRows, ((Bool) -> Void)?) -> Void)?
    var tipJarRowChosen: ((TipJarRowSelection, ((Bool) -> Void)?) -> Void)?
    var products: TipJarProducts? {
        didSet {
            self.tableView.reloadSections(IndexSet([Sections.tipJar.rawValue]), with: .automatic)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        self.tableView.register(SimpleLabelTableViewCell.self, forCellReuseIdentifier: SimpleLabelTableViewCell.reuseID)
        self.tableView.register(SettingsTipJarTableViewCell.self, forCellReuseIdentifier: SettingsTipJarTableViewCell.reuseID)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Sections(rawValue: section) else { assertionFailure("Wrong Section"); return 0 }
        switch section {
        case .settings:
            return SettingsRows.count
        case .tipJar:
            return TipJarRows.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let (_, row) = Sections.sectionsAndRows(from: indexPath) else { fatalError("Wrong Section/Row") }
        switch row {
        case .left(let row):
            let _cell = tableView.dequeueReusableCell(withIdentifier: SimpleLabelTableViewCell.reuseID, for: indexPath)
            guard let cell = _cell as? SimpleLabelTableViewCell else { return _cell }
            cell.label.attributedText = NSAttributedString(string: row.localizedTitle, style: .selectableTableViewCell)
            cell.accessoryType = .disclosureIndicator
            return cell
        case .right(let row):
            let _cell = tableView.dequeueReusableCell(withIdentifier: SettingsTipJarTableViewCell.reuseID, for: indexPath)
            guard let cell = _cell as? SettingsTipJarTableViewCell else { return _cell }
            cell.configure(with: row, product: row.product(from: self.products))
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Sections(rawValue: section) else { assertionFailure("Wrong Section"); return nil; }
        return section.localizedTitle
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let (_, row) = Sections.sectionsAndRows(from: indexPath) else { assertionFailure("Wrong Section/Row"); return nil; }
        switch row {
        case .left:
            return indexPath
        case .right(let row):
            switch row {
            case .free:
                return indexPath
            case .large, .medium, .small:
                return self.products != nil ? indexPath : nil
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let (_, row) = Sections.sectionsAndRows(from: indexPath) else { assertionFailure("Wrong Section/Row"); return; }
        let completion: ((Bool) -> Void)? = { tableView.deselectRow(at: indexPath, animated: $0) }
        switch row {
        case .left(let row):
            self.settingsRowChosen?(row, completion)
        case .right(let row):
            guard let selection = TipJarRowSelection(row: row, products: self.products) else { return }
            self.tipJarRowChosen?(selection, completion)
        }
    }
}

extension SettingsTableViewController {
    fileprivate enum Sections: Int {
        static let count = 2
        case settings, tipJar
        var localizedTitle: String {
            switch self {
            case .settings:
                return SettingsMainViewController.LocalizedString.title
            case .tipJar:
                return SettingsMainViewController.LocalizedString.sectionTitleTipJar
            }
        }
        static func sectionsAndRows(from indexPath: IndexPath) -> (Sections, Either<SettingsRows, TipJarRows>)? {
            guard let section = Sections(rawValue: indexPath.section) else { assertionFailure("Wrong Section"); return nil; }
            switch section {
            case .settings:
                guard let rows = SettingsRows(rawValue: indexPath.row) else { assertionFailure("Wrong Rows"); return nil; }
                return (section, .left(rows))
            case .tipJar:
                guard let rows = TipJarRows(rawValue: indexPath.row) else { assertionFailure("Wrong Rows"); return nil; }
                return (section, .right(rows))
            }
        }
    }

    enum SettingsRows: Int {
        static let count = 2
        case openSettings, emailDeveloper
        var localizedTitle: String {
            switch self {
            case .openSettings:
                return SettingsMainViewController.LocalizedString.cellTitleOpenSettings
            case .emailDeveloper:
                return SettingsMainViewController.LocalizedString.cellTitleEmailDeveloper
            }
        }
    }

    enum TipJarRows: Int {
        static let count = 4
        case free, small, medium, large
        func product(from products: TipJarProducts?) -> SKProduct? {
            switch self {
            case .free:
                return nil
            case .small:
                return products?.small
            case .medium:
                return products?.medium
            case .large:
                return products?.large
            }
        }
    }

    enum TipJarRowSelection {
        case free, small(SKProduct), medium(SKProduct), large(SKProduct)
        init?(row: TipJarRows, products: TipJarProducts?) {
            if case .free = row {
                self = .free
            }
            guard let products = products else { return nil }
            switch row {
            case .free:
                fatalError()
            case .small:
                self = .small(products.small)
            case .medium:
                self = .medium(products.medium)
            case .large:
                self = .large(products.large)
            }
        }
    }
}
