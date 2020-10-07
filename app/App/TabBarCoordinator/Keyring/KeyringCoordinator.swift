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

class KeyringCoordinator: FlowCoordinator {
    var childCoordinators: [FlowCoordinator] = []
    var navigationController: UINavigationController
    var tapkeyServiceFactory: TKMServiceFactory
    let keyringViewController: KeyringViewController

    init(navigationController: UINavigationController, tapkeyServiceFactory: TKMServiceFactory) {
        self.navigationController = navigationController
        self.tapkeyServiceFactory = tapkeyServiceFactory
        self.navigationController.navigationBar.barTintColor = Theme.darkColor
        self.keyringViewController = KeyringViewController.instantiate()
    }

    func start() {
        let keyringViewModel = KeyringViewModel(tapkeyServiceFactory: tapkeyServiceFactory)
        keyringViewModel.navigationDelegate = self
        keyringViewController.viewModel = keyringViewModel

        keyringViewController.tabBarItem = tabBarItem()
        navigationController.show(keyringViewController, sender: self)
    }

    func tabBarItem() -> UITabBarItem {
        let tabBarItem = UITabBarItem(
            title: "menu_keys".localized(),
            image: UIImage(named: Theme.ImageNames.tab1.rawValue),
            selectedImage: nil)
        tabBarItem.titlePositionAdjustment = UIOffset.init(horizontal: 4, vertical: 0)
        return tabBarItem
    }
}

extension KeyringCoordinator: KeyringViewModelNavigationDelegate {

    func keysViewModel(_ keyringViewModel: KeyringViewModel, presentKeyDetails keyDetails: KeyViewModel) {
        let keyDetailsCoordinator = KeyDetailsCoordinator(navigationController: navigationController)
        keyDetailsCoordinator.keyDetails = keyDetails
        keyDetailsCoordinator.start()
    }

}