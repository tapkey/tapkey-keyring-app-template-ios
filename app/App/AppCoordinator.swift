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

class AppCoordinator: FlowCoordinator {
    var window: UIWindow
    var childCoordinators = [FlowCoordinator]()
    var navigationController: UINavigationController
    let phoneNumberAuthenticationService: PhoneNumberAuthenticationService
    let tapkeyServiceFactory: TKMServiceFactory

    init(_ window: UIWindow, phoneNumberAuthenticationService: PhoneNumberAuthenticationService, tapkeyServiceFactory: TKMServiceFactory) {
        self.window = window
        let navigationController = UINavigationController()
        self.navigationController = navigationController
        self.phoneNumberAuthenticationService = phoneNumberAuthenticationService
        self.tapkeyServiceFactory = tapkeyServiceFactory
        window.rootViewController = self.navigationController
    }

    func start() {
        if phoneNumberAuthenticationService.isUserLoggedIn() {
            showTabBarController()
        } else {
            showLoginViewController()
        }
    }

    private func showTabBarController() {
        navigationController.viewControllers = []
        let tabCoordinator = TabBarCoordinator(
            phoneNumberAuthenticationService: self.phoneNumberAuthenticationService,
            tapkeyServiceFactory: self.tapkeyServiceFactory)

        tabCoordinator.start()
        childCoordinators.append(tabCoordinator)
        window.rootViewController = tabCoordinator.tabBarController
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }

    func showLoginViewController() {
        let navigationController = UINavigationController()
        self.navigationController = navigationController

        let loginCoordinator = LoginCoordinator(
            navigationController: navigationController,
            phoneNumberAuthenticationService: self.phoneNumberAuthenticationService,
            tapkeyServiceFactory: self.tapkeyServiceFactory)
        loginCoordinator.start()
        loginCoordinator.delegate = self
        childCoordinators.append(loginCoordinator)
        window.rootViewController = self.navigationController
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
}

extension AppCoordinator: LoginCoordinatorDelegate {
    func coordinatorDidLogin(coordinator: LoginCoordinator) {
        showTabBarController()
    }
}
