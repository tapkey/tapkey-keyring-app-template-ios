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

class TabBarCoordinator: NSObject, FlowCoordinator {

    var tabBarController: TabBarController
    var childCoordinators: [FlowCoordinator] = []
    var navigationController: UINavigationController
    let phoneNumberAuthenticationService: PhoneNumberAuthenticationService
    let tapkeyServiceFactory: TKMServiceFactory

    init(phoneNumberAuthenticationService: PhoneNumberAuthenticationService, tapkeyServiceFactory: TKMServiceFactory) {
        self.tabBarController = TabBarController.instantiate()
        self.navigationController = UINavigationController()
        self.phoneNumberAuthenticationService = phoneNumberAuthenticationService
        self.tapkeyServiceFactory = tapkeyServiceFactory
        super.init()
    }

    func start() {
        let keysCoordinator = KeyringCoordinator(navigationController: UINavigationController(), tapkeyServiceFactory: tapkeyServiceFactory)
        keysCoordinator.start()

        let settingsCoordinator = SettingsCoordinator(
            navigationController: UINavigationController(),
            phoneAuthenticationService: phoneNumberAuthenticationService,
            tapkeyServiceFactory: self.tapkeyServiceFactory)
        settingsCoordinator.start()

        childCoordinators.append(keysCoordinator)
        childCoordinators.append(settingsCoordinator)

        let viewModel = TabBarViewModel()
        tabBarController.viewModel = viewModel

        tabBarController.viewControllers = [keysCoordinator.navigationController, settingsCoordinator.navigationController]
        tabBarController.delegate = self
    }

}

extension TabBarCoordinator: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard tabBarController.selectedViewController != viewController else {
            return false
        }

        return true
    }

}