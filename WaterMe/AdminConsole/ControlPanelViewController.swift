//
//  ControlPanelViewController.swift
//  WaterMe
//
//  Created by Jeffrey Bergier on 5/25/17.
//  Copyright © 2017 Saturday Apps. All rights reserved.
//

import WaterMeData
import RealmSwift
import UIKit

class ControlPanelViewController: UIViewController {
    
    @IBOutlet private weak var summaryView: UserSummmaryView?
    @IBOutlet private weak var syncView: SynchronizingView?
    @IBOutlet private weak var auditButton: UIButton?
    @IBOutlet private weak var refreshButton: UIButton?
    @IBOutlet private weak var deleteLocalButton: UIButton?
    private var buttons: [UIButton] {
        return [self.auditButton, self.refreshButton, self.deleteLocalButton].flatMap({ $0 })
    }
    
    private let adminController = AdminRealmController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let users = self.adminController.allUsers()
        self.notificationToken = users.addNotificationBlock() { [weak self] changes in self?.realmDataChanged(changes) }
    }
    
    private func realmDataChanged(_ changes: RealmCollectionChange<AnyRealmCollection<RealmUser>>) {
        switch changes {
        case .initial(let data), .update(let data, _, _, _):
            self.summaryView?.updateUI(with: .success(data))
            self.updateSyncSessionProgressNotifications()
        case .error(let error):
            self.summaryView?.updateUI(with: .error(error))
        }
    }
    
    private func updateSyncSessionProgressNotifications() {
        guard let user = SyncUser.current else { log.info("Realm User Not Logged In"); return }
        self.progressTokens = nil
        let sessions = user.allSessions()
        print("Sessions: \(sessions.count)")
        self.progressTokens = sessions.flatMap() { session -> SyncSession.ProgressNotificationToken? in
            return session.addProgressNotification(for: .download, mode: .reportIndefinitely) { [weak self] progress in
                if progress.isTransferComplete {
                    self?.syncView?.stop()
                } else {
                    self?.syncView?.start()
                }
            }
        }
        
    }
    
    @IBAction private func auditButtonTapped(_ sender: UIButton?) {
        //        self.buttons.forEach({ $0.isEnabled = false })
    }
    
    @IBAction private func refreshButtonTapped(_ sender: UIButton?) {
        
        self.buttons.forEach({ $0.isEnabled = false })
        
        var isDownloadOpFinished = false
        var isRealmOpFinished = true
        
        if SyncUser.current == nil {
            isRealmOpFinished = false
            log.info("Need to login to Realm")
            let server = WaterMeData.PrivateKeys.kRealmServer
            let credentials = SyncCredentials.usernamePassword(username: PrivateKeys.kRealmAdminLogin, password: PrivateKeys.kRealmAdminPassword, register: false)
            SyncUser.logIn(with: credentials, server: server) { user, error in
                DispatchQueue.main.async {
                    isRealmOpFinished = true
                    if user != nil {
                        log.info("Login Succeeded")
                    } else {
                        log.error(error!)
                    }
                }
                if isDownloadOpFinished && isRealmOpFinished {
                    self.buttons.forEach({ $0.isEnabled = true })
                }
            }
        }
        
        URLSession.shared.downloadROSFileTree() { result in
            isDownloadOpFinished = true
            switch result {
            case .success(let data):
                do {
                    try self.adminController.processServerDirectoryData(data)
                } catch {
                    log.error(error)
                }
            case .error(let error):
                log.error(error)
            }
            if isDownloadOpFinished && isRealmOpFinished {
                self.buttons.forEach({ $0.isEnabled = true })
            }
        }
    }
    
    @IBAction private func deleteLocalButtonTapped(_ sender: UIButton?) {
        let deleteHandler: (UIAlertAction) -> Void = { _ in
            self.buttons.forEach({ $0.isEnabled = false })
            self.adminController.deleteAll()
            self.buttons.forEach({ $0.isEnabled = true })
        }
        let actionSheet = UIAlertController(cancelDeleteActionSheetWithDeleteHandler: deleteHandler, sourceView: sender)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    private var notificationToken: NotificationToken?
    private var progressTokens: [SyncSession.ProgressNotificationToken]? {
        didSet {
            oldValue?.forEach({ $0.stop() })
        }
    }
    
    deinit {
        self.progressTokens = nil
        self.notificationToken?.stop()
    }
}

extension String: Error {}

extension URLSession {
    fileprivate func downloadROSFileTree(completionHandler: ((Result<Data>) -> Void)?) {
        let url = WaterMeData.PrivateKeys.kRealmServer.appendingPathComponent("realmsec/list")
        var request = URLRequest(url: url)
        request.setValue("sharedSecret=\(PrivateKeys.requestSharedSecret)", forHTTPHeaderField: "Cookie")
        let task = self.dataTask(with: request) { _data, __response, error in
            DispatchQueue.main.async {
                let _response = __response as? HTTPURLResponse
                let _sharedSecret = (_response?.allHeaderFields["Shared-Secret"] ?? _response?.allHeaderFields["shared-secret"]) as? String
                guard let data = _data, let response = _response, response.statusCode == 200 else {
                    completionHandler?(.error(__response?.debugDescription ?? error!))
                    return
                }
                guard let sharedSecret = _sharedSecret, sharedSecret == PrivateKeys.responseSharedSecret else {
                    completionHandler?(.error("SharedSecret does not match."))
                    return
                }
                completionHandler?(.success(data))
            }
        }
        task.resume()
    }
}

extension UIAlertController {
    convenience init(cancelDeleteActionSheetWithDeleteHandler deleteHandler: @escaping (UIAlertAction) -> Void, sourceView: UIView?) {
        self.init(title: nil, message: "Are you sure you want to delete this stuff?", preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Delete", style: .destructive, handler: deleteHandler)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        self.addAction(delete)
        self.addAction(cancel)
        self.popoverPresentationController?.sourceView = sourceView
    }
}