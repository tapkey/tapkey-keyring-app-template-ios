//
// Copyright (c) 2022 Tapkey GmbH
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The software is only used for evaluation purposes OR educational purposes OR
// private, non-commercial, low-volume projects.
//
// The above copyright notice and these permission notices shall be included in all
// copies or substantial portions of the Software.
//
// For any use not covered by this license, a commercial license must be acquired
// from Tapkey GmbH.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit
import TapkeyMobileLib

protocol KeyringViewModelNavigationDelegate: AnyObject {
    func keysViewModel(_ keyringViewModel: KeyringViewModel, presentKeyDetails keyDetails: KeyViewModel)
}

class KeyringViewModel: NSObject {

    private static let TAG = String(describing: KeyringViewModel.self)

    private(set) var dataSource: [KeyringTableSection] = []
    private var bluetoothAdapter: BluetoothAdapter?

    private let tapkeyServiceFactory: TKMServiceFactory
    private let bleLockScanner: TKMBleLockScanner
    private let keyManager: TKMKeyManager
    private let userManager: TKMUserManager
    private let notificationManager: TKMNotificationManager

    private var keyViewModels: [String: KeyViewModel] = [:]
    private var localKeys: [TKMKeyDetails] = []

    private var localKeysObserverRegistration: TKMObserverRegistration?
    private var nearbyBluetoothDevicesObserverRegistration: TKMObserverRegistration?
    private var bluetoothScanRegistration: TKMObserverRegistration?

    private(set) var shouldScan: Bool = false {
        didSet {
            self.toggleBluetoothScan()
        }
    }

    public var isBluetoothOn: Bool {
        return bluetoothAdapter?.isOn ?? false
    }

    public var isBluetoothAuthorized: Bool {
        return bluetoothAdapter?.isAuthorized ?? false
    }

    public var shouldShowBluetoothWarning: Bool {
        if !shouldScan {
            return false
        }

        return true
    }

    public weak var navigationDelegate: KeyringViewModelNavigationDelegate?
    public var viewRefreshHandler: (() -> Void)?

    private var queryLocalKeysInProgress: Bool = false

    init(tapkeyServiceFactory: TKMServiceFactory) {

        self.tapkeyServiceFactory = tapkeyServiceFactory
        self.bleLockScanner = tapkeyServiceFactory.bleLockScanner
        self.keyManager = tapkeyServiceFactory.keyManager
        self.userManager = tapkeyServiceFactory.userManager
        self.notificationManager = tapkeyServiceFactory.notificationManager
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startObserving),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopObserving),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        startObserving()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.stopObserving()
    }

    @objc private func startObserving() {

        if let ongoingObserverRegistration = self.localKeysObserverRegistration {
            TKMLog.w(KeyringViewModel.TAG, "KeyringViewModel lifecycle issue detected, localKeysObserver was not closed probably.")
            ongoingObserverRegistration.close()
            self.localKeysObserverRegistration = nil
        }

        self.localKeysObserverRegistration = keyManager.keyUpdateObservable.addObserver { [weak self] in
            self?.queryLocalKeys()
        }

        if let ongoingObserverRegistration = self.nearbyBluetoothDevicesObserverRegistration {
            TKMLog.w(KeyringViewModel.TAG, "KeyringViewModel lifecycle issue detected, nearbyBluetoothDevicesObserver was not closed probably.")
            ongoingObserverRegistration.close()
            self.nearbyBluetoothDevicesObserverRegistration = nil
        }

        self.nearbyBluetoothDevicesObserverRegistration = self.bleLockScanner.observable.addObserver { [weak self] _ in
            self?.loadDataSource()
        }

        toggleBluetoothScan()
    }

    @objc private func stopObserving() {

        nearbyBluetoothDevicesObserverRegistration?.close()
        nearbyBluetoothDevicesObserverRegistration = nil

        localKeysObserverRegistration?.close()
        localKeysObserverRegistration = nil

        if self.shouldScan {
            bluetoothScanRegistration?.close()
            bluetoothScanRegistration = nil
        }
    }

    private func toggleBluetoothScan() {

        if self.shouldScan {

            let bluetoothAdapter = self.bluetoothAdapter ?? BluetoothAdapter { [weak self] in
                self?.toggleBluetoothScan()
                self?.viewRefreshHandler?()
            }
            self.bluetoothAdapter = bluetoothAdapter

            guard bluetoothAdapter.isOn else {
                // bluetooth is not on yet
                return
            }

            guard bluetoothAdapter.isAuthorized else {
                // bluetooth is not authorized yet
                return
            }

            guard self.bluetoothScanRegistration == nil else {
                // bluetooth is already ongoing
                return
            }

            self.bluetoothScanRegistration = self.bleLockScanner.startForegroundScan()

        } else {

            self.bluetoothAdapter = nil

            self.bluetoothScanRegistration?.close()
            self.bluetoothScanRegistration = nil
        }

    }

    private func loadDataSource() {

        let updatedKeyViewModelList = self.localKeys
            .filter { $0.grant != nil } // grant should not be null anyway, but without grant we can not map it to an physical lock
            .map { key -> KeyViewModel in

                let grant = key.grant! // were already filtered out before

                let physicalLockId = grant.getBoundLock()?.getPhysicalLockId() ?? ""

                let isNearby = self.bleLockScanner.isLockNearby(physicalLockId: grant.getBoundLock().getPhysicalLockId())
                let hasUnlimitedValidity = grant.getValidBefore() == nil && grant.getValidFrom() == nil && grant.getTimeRestrictionIcal() == nil

                if let model = self.keyViewModels[physicalLockId] {

                    return model.updateData(
                        title: grant.getBoundLock()?.getTitle() ?? "",
                        physicalLockId: grant.getBoundLock()?.getPhysicalLockId() ?? "",
                        isNearby: isNearby,
                        hasUnlimitedValidity: hasUnlimitedValidity,
                        offlineFrom: key.autorenewedBefore,
                        offlineUntil: key.autoRenewalScheduledAt)

                } else {
                    // swiftlint:disable:next trailing_closure
                    return KeyViewModel(
                        tapkeyServiceFactory: tapkeyServiceFactory,
                        title: grant.getBoundLock()?.getTitle() ?? "",
                        physicalLockId: grant.getBoundLock()?.getPhysicalLockId() ?? "",
                        isNearby: isNearby,
                        hasUnlimitedValidity: hasUnlimitedValidity,
                        offlineFrom: key.autorenewedBefore,
                        offlineUntil: key.autoRenewalScheduledAt,
                        stateChangedListener: { [weak self] state -> Void in
                            // Refresh view to release pinned items
                            if state == .idle {
                                self?.loadDataSource()
                            }
                        })
                }
            }

        self.keyViewModels = Dictionary(uniqueKeysWithValues: updatedKeyViewModelList.map { ($0.physicalLockId, $0) })
        let allKeys = updatedKeyViewModelList
            .sorted { $0.title < $1.title }

        // Mark all itmes which are not idle as nearby too
        // keep them pinned in the nearby list until the idle again
        let nearbyKeys = allKeys
            .filter { $0.isNearby == true || $0.lockState != .idle }

        let otherKeys = allKeys
            .filter { !nearbyKeys.contains($0) }

        self.dataSource = [
            KeyringTableSection(
                title: "nearby".localized(),
                cellModels: nearbyKeys.isEmpty ? [KeyEmptyStateViewModel()] : nearbyKeys,
                sectionType: .nearby),
            KeyringTableSection(
                title: "other".localized(),
                cellModels: otherKeys,
                sectionType: .other)
        ]

        viewRefreshHandler?()
    }

    func numberOfSections() -> Int {
        guard !dataSource.isEmpty else {
            return 0
        }
        var numberOfSections = 2
        let section = dataSource.filter { $0.sectionType == .other }.first
        if section?.cellModels.isEmpty == true {
            numberOfSections = 1
        }
        return numberOfSections
    }

    func numberOfRows(in section: Int) -> Int {
        let keySection = dataSource[section]
        return keySection.cellModels.count
    }

    func item(at indexPath: IndexPath) -> Any {
        let keySection = dataSource[indexPath.section]
        return keySection.cellModels[indexPath.row]
    }

    func cellType(at index: IndexPath) -> UITableViewCell.Type {
        let keySection = dataSource[index.section]
        switch keySection.sectionType {
        case .nearby:
            let viewModel = item(at: index)
            if viewModel is KeyEmptyStateViewModel {
                return KeyEmptyStateCell.self
            }
            return KeyCell.self

        case .other:
            return KeyCell.self

        default:
            assertionFailure("this branch should never be reached")
            return KeyCell.self
        }
    }

    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func title(for section: Int) -> String {
        let section = dataSource[section]
        return section.title
    }

    func didSelectRow(at indexPath: IndexPath) {
        guard let keyDetails = item(at: indexPath) as? KeyViewModel else {
            return
        }
        navigationDelegate?.keysViewModel(self, presentKeyDetails: keyDetails)
    }

    public func queryLocalKeys() {
        if self.queryLocalKeysInProgress {
            return
        }

        guard !self.userManager.users.isEmpty else {
            return
        }

        let userId = self.userManager.users[0]

        self.queryLocalKeysInProgress = true

        self.keyManager.queryLocalKeysAsync(userId: userId, cancellationToken: TKMCancellationTokens.None)
            .continueOnUi { [weak self] keyDetails in
                guard let self = self else {
                    return
                }
                self.localKeys = keyDetails ?? []

                if self.shouldScan == true && self.localKeys.isEmpty {
                    self.shouldScan = false
                }

                if self.shouldScan == false && !self.localKeys.isEmpty {
                    self.shouldScan = true
                }
            }
            .catchOnUi { asyncError in
                TKMLog.e(KeyringViewModel.TAG, "Failed to query local keys", asyncError.syncSrcError)
                return nil
            }
            .finallyOnUi { [weak self] in

                guard let self = self else {
                    return
                }

                self.queryLocalKeysInProgress = false
                self.loadDataSource()
            }
            .conclude()
    }

    public func pollForNewKeys() -> TKMPromise<Void> {
        return self.notificationManager.pollForNotificationsAsync(cancellationToken: TKMCancellationTokens.None)
            .continueOnUi { _ -> Void? in
                TKMLog.d(KeyringViewModel.TAG, "Successfully polled for new keys")
                return nil
            }
            .catchOnUi { asyncError -> Void? in
                // ToDo: Show error
                TKMLog.e(KeyringViewModel.TAG, "Failed to poll for new keys")
                return nil
            }
    }
}
