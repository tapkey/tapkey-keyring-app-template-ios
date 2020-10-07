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

class SettingsViewModel: NSObject {

    private static let TAG = String(describing: SettingsViewModel.self)

    var coordinatorDelegate: SettingsCoordinatorDelegate?
    var phoneNumberAuthenticationService: PhoneNumberAuthenticationService
    var userManager: TKMUserManager

    init(phoneNumberAuthenticationService: PhoneNumberAuthenticationService, userManager: TKMUserManager) {
        self.phoneNumberAuthenticationService = phoneNumberAuthenticationService
        self.userManager = userManager
        super.init()
    }

    func didTapAbout() {
        coordinatorDelegate?.didTapAbout()
    }

    func setupProfileHeaderView(_ profileHeaderView: ProfileHeaderView) {
        profileHeaderView.set(
            profileImage: UIImage(named: Theme.ImageNames.profile.rawValue),
            phoneNumberImage: UIImage(named: Theme.ImageNames.phone.rawValue),
            andPhoneNumber: phoneNumberAuthenticationService.getUserPhoneNumber() ?? "")
    }

    func signOut() -> TKMPromise<Void> {
        phoneNumberAuthenticationService.signOut()
        return TKMAsync.foreachAsync(items: userManager.users) { userId in
            return self.userManager.logOutAsync(userId: userId, cancellationToken: TKMCancellationTokens.None)
                .catchOnUi { asyncError in
                    let e = asyncError.syncSrcError
                    TKMLog.e(SettingsViewModel.TAG, "Failed to sign out userId \(userId)", e)
                    return nil
                }
                .asConst(TKMLoopResult.continue)
        }
        .finallyOnUi { [weak self] in
            self?.coordinatorDelegate?.didTapSignOut()
        }
        .asVoid()
    }
}
