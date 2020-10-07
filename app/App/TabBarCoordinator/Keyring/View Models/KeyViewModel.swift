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

enum LockState {
    case idle
    case triggerInProgress
    case triggerSuccessfully
    case triggerFailed
}

class KeyViewModel: NSObject {

    private static let TAG = String(describing: KeyViewModel.self)

    static let successTimeoutMS: Int64 = 2000
    static let errorTimeoutMS: Int64 = 5000

    // MARK: - Services
    private let bleLockCommunicator: TKMBleLockCommunicator
    private let bleLockScanner: TKMBleLockScanner
    private let commandExecutionFacade: TKMCommandExecutionFacade
    private let messageResolver = MessageResolver.sharedService

    // MARK: - Async state
    private var stateChangedListener: (() -> Void)?
    private var ongoingCancellationTokenSource: TKMCancellationTokenSource? = nil
    private var idleTimerCancellationTokenSource: TKMCancellationTokenSource? = nil

    private(set) var title: String
    private(set) var physicalLockId: String
    private(set) var isNearby: Bool
    private(set) var hasUnlimitedValidity: Bool
    private(set) var offlineFrom: String?
    private(set) var offlineUntil: String?
    private(set) var lockState: LockState
    private(set) var errorMessage: String?

    var viewRefreshHandler: (() -> Void)?

    init(
        tapkeyServiceFactory: TKMServiceFactory,
        title: String,
        physicalLockId: String,
        isNearby: Bool,
        hasUnlimitedValidity: Bool,
        offlineFrom: Date? = nil,
        offlineUntil: Date? = nil,
        stateChangedListener: ((LockState) -> Void)? = nil
    ) {

        self.bleLockCommunicator = tapkeyServiceFactory.bleLockCommunicator
        self.bleLockScanner = tapkeyServiceFactory.bleLockScanner
        self.commandExecutionFacade = tapkeyServiceFactory.commandExecutionFacade

        self.title = title
        self.physicalLockId = physicalLockId
        self.isNearby = isNearby
        self.hasUnlimitedValidity = hasUnlimitedValidity
        self.offlineFrom = offlineFrom?.toString(withFormat: Theme.dateFormat)
        self.offlineUntil = offlineUntil?.toString(withFormat: Theme.dateFormat)
        self.lockState = .idle
    }

    deinit {
        self.ongoingCancellationTokenSource?.requestCancellation()
        self.ongoingCancellationTokenSource = nil
    }

    public func updateData(
        title: String,
        physicalLockId: String,
        isNearby: Bool,
        hasUnlimitedValidity: Bool,
        offlineFrom: Date? = nil,
        offlineUntil: Date? = nil
    ) -> KeyViewModel {
        self.title = title
        self.physicalLockId = physicalLockId
        self.isNearby = isNearby
        self.hasUnlimitedValidity = hasUnlimitedValidity
        self.offlineFrom = offlineFrom?.toString(withFormat: Theme.dateFormat)
        self.offlineUntil = offlineUntil?.toString(withFormat: Theme.dateFormat)
        return self
    }

    public func triggerLock() {

        print("trigger me")

        //self.lockState = .triggerInProgress
        //viewRefreshHandler?()

        if lockState == .triggerInProgress {
            return
        }

        guard let bluetoothAddress = bleLockScanner.getLock(physicalLockId: physicalLockId)?.bluetoothAddress else {
            NSLog("Lock not nearby")
            return
        }

        if let idleTimerCancellationTokenSource = self.idleTimerCancellationTokenSource {
            self.idleTimerCancellationTokenSource = nil
            idleTimerCancellationTokenSource.requestCancellation()
        }

        self.stateChanged(.triggerInProgress)

        let ongoingCancellationTokenSource = TKMCancellationTokenSource()
        let ct = TKMCancellationTokens.withTimeout(original: ongoingCancellationTokenSource.token, timeoutMs: 15000)
        self.ongoingCancellationTokenSource = ongoingCancellationTokenSource

        self.bleLockCommunicator.executeCommandAsync(
            bluetoothAddress: bluetoothAddress,
            physicalLockId: physicalLockId,
            commandFunc: { tlcpConnection -> TKMPromise<TKMCommandResult> in

                let triggerLockCommand = TKMDefaultTriggerLockCommandBuilder()
                    .build()

                // Pass the TLCP connection to the command execution facade
                return self.commandExecutionFacade.executeStandardCommandAsync(
                    tlcpConnection,
                    command: triggerLockCommand,
                    cancellationToken: ct)
            },
            cancellationToken: ct)
            .continueOnUi { [weak self] commandResult -> Void in

                guard let self = self else {
                    return
                }

                let code = commandResult?.code ?? TKMCommandResult.TKMCommandResultCode.technicalError

                if code == .ok {
                    TKMLog.d(KeyViewModel.TAG, "Lock opened successfully")
                    self.stateChanged(.triggerSuccessfully)
                    self.startIdleTimer()
                    return
                }

                let errorMessage = self.messageResolver.getMessage(commandResultCode: code)
                self.stateChanged(.triggerFailed)
                self.errorMessage = errorMessage
                self.startIdleTimer()
            }
            .catchOnUi { [weak self] asyncError -> Void in

                guard let self = self else {
                    return
                }

                let syncError = asyncError.syncSrcError
                TKMLog.e(KeyViewModel.TAG, "trigger lock failed with an unhandled exception", syncError)
                self.stateChanged(.triggerFailed)
                self.errorMessage = self.messageResolver.getMessage(commandResultCode: .technicalError)
                self.startIdleTimer()
                return
            }
            .finallyOnUi { [weak self] in
                self?.ongoingCancellationTokenSource = nil
            }
            .conclude()
    }

    private func stateChanged(_ state: LockState) {
        self.lockState = state
        self.viewRefreshHandler?()
        self.stateChangedListener?()
    }

    private func startIdleTimer() {

        let timerInterval: Int64 = self.lockState == .triggerSuccessfully ? KeyViewModel.successTimeoutMS : KeyViewModel.errorTimeoutMS

        let cts = TKMCancellationTokenSource()
        self.idleTimerCancellationTokenSource = cts
        _ = TKMAsync.delayAsync(delayMs: timerInterval, cancellationToken: cts.token)
            .continueOnUi { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.idleTimerCancellationTokenSource = nil
                self.stateChanged(.idle)
                self.errorMessage = nil
            }
    }

}
