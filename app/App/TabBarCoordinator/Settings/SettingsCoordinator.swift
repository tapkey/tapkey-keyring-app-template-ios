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

protocol SettingsCoordinatorDelegate {
    func didTapSignOut()
    func didTapAbout()
}

class SettingsCoordinator: FlowCoordinator {

    var childCoordinators: [FlowCoordinator] = []
    var navigationController: UINavigationController
    let phoneNumberAuthenticationService: PhoneNumberAuthenticationService
    let tapkeyServiceFactory: TKMServiceFactory
    let settingsViewController: SettingsViewController

    init(navigationController: UINavigationController, phoneAuthenticationService: PhoneNumberAuthenticationService, tapkeyServiceFactory: TKMServiceFactory) {
        self.navigationController = navigationController
        self.phoneNumberAuthenticationService = phoneAuthenticationService
        self.tapkeyServiceFactory = tapkeyServiceFactory
        self.navigationController.navigationBar.barTintColor = Theme.darkColor
        self.settingsViewController = SettingsViewController.instantiate()
    }

    func start() {
        let settingsViewModel = SettingsViewModel(phoneNumberAuthenticationService: phoneNumberAuthenticationService, userManager: self.tapkeyServiceFactory.userManager)
        settingsViewModel.coordinatorDelegate = self
        settingsViewController.viewModel = settingsViewModel

        settingsViewController.tabBarItem = tabBarItem()
        navigationController.show(settingsViewController, sender: self)
    }

    func tabBarItem() -> UITabBarItem {
        let tabBarItem = UITabBarItem(title: "settings".localized(), image: UIImage(named: Theme.ImageNames.tab2.rawValue), selectedImage: nil)
        tabBarItem.titlePositionAdjustment = UIOffset.init(horizontal: 4, vertical: 0)
        return tabBarItem
    }
}

extension SettingsCoordinator: SettingsCoordinatorDelegate {
    func didTapAbout() {
        let aboutCoordinator = AboutCoordinator(navigationController: navigationController)
        aboutCoordinator.start()
    }

    func didTapSignOut() {
        self.getAppCoordinator().showLoginViewController()
    }
}
