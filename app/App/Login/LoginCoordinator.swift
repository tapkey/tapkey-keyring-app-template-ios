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
import UIKit
import TapkeyMobileLib

protocol LoginCoordinatorDelegate: AnyObject {
    func coordinatorDidLogin(coordinator: LoginCoordinator)

}

class LoginCoordinator: FlowCoordinator {
    weak var delegate: LoginCoordinatorDelegate?

    var childCoordinators: [FlowCoordinator] = []
    var navigationController: UINavigationController
    let loginViewController: PhoneNumberViewController
    let phoneNumberAuthenticationService: PhoneNumberAuthenticationService
    let tapkeyServiceFactory: TKMServiceFactory

    init(navigationController: UINavigationController, phoneNumberAuthenticationService: PhoneNumberAuthenticationService, tapkeyServiceFactory: TKMServiceFactory) {

        self.navigationController = navigationController
        self.phoneNumberAuthenticationService = phoneNumberAuthenticationService
        self.tapkeyServiceFactory = tapkeyServiceFactory

        self.loginViewController = PhoneNumberViewController.instantiate()
        let loginViewModel = PhoneNumberViewModel(phoneNumberAuthenticationService: phoneNumberAuthenticationService)
        loginViewModel.coordinatorDelegate = self
        loginViewModel.viewDelegate = loginViewController
        loginViewController.viewModel = loginViewModel
    }

    func start() {
        navigationController.show(loginViewController, sender: self)
    }

    func pushVerificationCodeView(phoneNumber: String, verificationId: String) {
        let verificationCodeViewController = VerificationCodeViewController.instantiate()
        let verificationCodeViewModel = VerificationCodeViewModel(
            phoneNumberAuthenticationService: phoneNumberAuthenticationService,
            userManager: tapkeyServiceFactory.userManager,
            phoneNumber: phoneNumber,
            verificationId: verificationId)
        verificationCodeViewModel.viewDelegate = verificationCodeViewController
        verificationCodeViewController.viewModel = verificationCodeViewModel
        verificationCodeViewModel.coordinatorDelegate = self
        self.navigationController.pushViewController(verificationCodeViewController, animated: true)
    }
}

extension LoginCoordinator: PhoneNumberViewModelCoordinatorDelegate {
    func verifyPhoneNumber(phoneNumber: String, verificationId: String) {
        pushVerificationCodeView(phoneNumber: phoneNumber, verificationId: verificationId)
    }
}

extension LoginCoordinator: VerificationCodeViewCoordinatorDelegate {
    func didLogin() {
        delegate?.coordinatorDidLogin(coordinator: self)
    }
}
