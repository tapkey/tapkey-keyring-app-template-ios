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
import MBProgressHUD
import TapkeyMobileLib

class KeyringViewController: UIViewController, Storyboarded {

    @IBOutlet private weak var bluetoothOverview: BluetoothOverview!
    @IBOutlet private weak var tableView: UITableView!

    var viewModel: KeyringViewModel! {
        didSet {
            viewModel.viewRefreshHandler = {
                self.refreshView()
            }
        }
    }

    private var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "menu_keys".localized()

        self.refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onPullForRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        setRefreshControlColorScheme()

        MBProgressHUD.showAdded(to: self.view, animated: true)

        viewModel.pollForNewKeys()
            .conclude()

        viewModel.queryLocalKeys()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    private func setRefreshControlColorScheme() {
        var color = Theme.darkColor
        if #available(iOS 12.0, *) {
            color = self.traitCollection.userInterfaceStyle == .dark ? Theme.lightColor : Theme.darkColor
        }
        tableView.refreshControl?.tintColor = color
        tableView.refreshControl?.attributedTitle = NSMutableAttributedString(
            string: "updating_keys".localized(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: color
            ]
        )
    }

    @objc private func onPullForRefresh() {
        self.refreshControl.beginRefreshing()
        TKMAsync.whenAll(
            viewModel.pollForNewKeys(),
            TKMAsync.delayAsync(delayMs: 500))
            .finallyOnUi { [weak self] in
                self?.refreshControl?.endRefreshing()
            }
            .conclude()
    }

    private func shouldShowBluetoothWarning() -> Bool {

        if !viewModel.shouldScan {
            return false
        }

        if viewModel.isBluetoothOn == false {
            bluetoothOverview.type = .disabled
            return true
        }

        if viewModel.isBluetoothAuthorized == false {
            bluetoothOverview.type = .unauthorized
            return true
        }

        return false
    }

    private func refreshView() {
        self.tableView?.reloadData()
        MBProgressHUD.hide(for: self.view, animated: true)

        let showBluetoothWarning = self.shouldShowBluetoothWarning()
        let currentAlpha = self.bluetoothOverview.alpha

        if showBluetoothWarning && currentAlpha == 0.0 {
            UIView.animate(withDuration: 0.3) { [unowned self] in
                self.bluetoothOverview.alpha = 1.0
            }
        }

        if !showBluetoothWarning && currentAlpha == 1.0 {
            UIView.animate(withDuration: 0.3) { [unowned self] in
                self.bluetoothOverview.alpha = 0.0
            }
        }
    }
}

extension KeyringViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Table view data source & delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = viewModel.cellType(at: indexPath)
        let cellIdentifier = cellType.identifier

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        switch cellType {
        case is KeyCell.Type:
            if let cellModel = viewModel.item(at: indexPath) as? KeyViewModel,
               let cell = cell as? KeyCell {
                cell.viewModel = cellModel
                cell.viewModel.viewRefreshHandler?()
            }

        case is KeyEmptyStateCell.Type:
            if let cellModel = viewModel.item(at: indexPath) as? KeyEmptyStateViewModel,
               let cell = cell as? KeyEmptyStateCell {
                cell.viewModel = cellModel
            }

        default:
            assertionFailure("this branch should never be reached")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.title(for: section)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectRow(at: indexPath)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setRefreshControlColorScheme()
    }
}
