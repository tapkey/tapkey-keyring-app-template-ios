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

import Foundation
import FirebaseAnalytics
import UIKit
import TapkeyMobileLib

protocol VerificationCodeViewCoordinatorDelegate {
    func didLogin()
}

protocol VerificationCodeViewModelDelegate {
    func showValidation(codeError: VerificationError)
}

enum VerificationError {
    case general
    case invalidCode
}

class VerificationCodeViewModel {
    var coordinatorDelegate: VerificationCodeViewCoordinatorDelegate?
    var viewDelegate: VerificationCodeViewModelDelegate?

    private let phoneNumberAuthenticationService: PhoneNumberAuthenticationService
    private let userManager: TKMUserManager
    private let phoneNumber: String
    private var verificationId: String

    init(phoneNumberAuthenticationService: PhoneNumberAuthenticationService, userManager: TKMUserManager, phoneNumber: String, verificationId: String) {
        self.phoneNumberAuthenticationService = phoneNumberAuthenticationService
        self.userManager = userManager
        self.phoneNumber = phoneNumber
        self.verificationId = verificationId
    }

    func verifyCode(_ verificationCode: String) {
        phoneNumberAuthenticationService
            .verifyCodeAsync(verificationId: self.verificationId, verificationCode: verificationCode)
            .continueAsyncOnUi { accessToken -> TKMPromise<String> in

                guard let accessToken = accessToken else {
                    return TKMAsync.promiseFromError(NSError(domain: "Unknown_access_token_nil", code: 401, userInfo: [:]))
                }

                return self.userManager.logInAsync(accessToken: accessToken, cancellationToken: TKMCancellationTokens.None)
                    .catchOnUi { asyncError in

                        // ToDo: log error

                        throw asyncError
                    }
            }
            .continueOnUi { [weak self] _ in
                Analytics.logEvent(AnalyticsEvents.Events.LoginSucceeded, parameters: nil)
                self?.coordinatorDelegate?.didLogin()
                return nil
            }
            .catchOnUi { [weak self] asyncError in
                let error = asyncError.syncSrcError as NSError
                var codeError = VerificationError.general
                var reason: String = error.description
                if let errorString = error.userInfo["FIRAuthErrorUserInfoNameKey"] {
                    if errorString as! String == "ERROR_INVALID_VERIFICATION_CODE" {
                        codeError = VerificationError.invalidCode
                        reason = "invalid_code"
                    }
                }
                Analytics.logEvent(AnalyticsEvents.Events.LoginFailed, parameters: [AnalyticsEvents.Parameters.Reason: reason])
                self?.viewDelegate?.showValidation(codeError: codeError)
            }
            .conclude()
    }

    func resendCode() {
        phoneNumberAuthenticationService
            .verifyPhoneNumber(self.phoneNumber)
            .asVoid()
            .catchOnUi { asyncError in
                // ToDo: Handle error
            }
            .conclude()
    }
}
