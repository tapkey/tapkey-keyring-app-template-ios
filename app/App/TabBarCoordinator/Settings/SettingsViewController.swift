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

class SettingsViewController: UIViewController, Storyboarded {

    // MARK: - Outlets
    @IBOutlet private weak var profileHeaderView: ProfileHeaderView!

    // MARK: - View Model
    var viewModel: SettingsViewModel!

    var dataSource: [SettingsCellModel] = [
        SettingsCellModel(
            imageName: Theme.ImageNames.info.rawValue,
            title: "menu_about".localized()),
        SettingsCellModel(
            imageName: Theme.ImageNames.signOut.rawValue,
            title: "menu_sign_out".localized())
    ]

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setupProfileHeaderView(profileHeaderView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.navigationBar.isHidden = false
    }

}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsCell.identifier,
            for: indexPath) as? SettingsCell else {
                assertionFailure("This should be a SettingsCell")
                return UITableViewCell()
            }

        cell.viewModel = dataSource[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            viewModel.didTapAbout()
            break

        case 1:
            self.signOut()
            break

        default:
            break
        }
    }

    func signOut() {

        let alert = UIAlertController(
            title: "sign_out_warning_title".localized(),
            message: "sign_out_warning_message".localized(),
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "sign_out_warning_positive".localized(),
            style: .default) { [weak self] action in

                guard let self = self else {
                    return
                }

                MBProgressHUD.showAdded(to: self.view, animated: true)
                self.viewModel.signOut()
                    .finallyOnUi { [weak self] in
                        guard let self = self else {
                            return
                        }
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                    .conclude()
        })

        alert.addAction(UIAlertAction(
            title: "sign_out_warning_cancel".localized(),
            style: .cancel,
            handler: nil))

        self.present(alert, animated: true)
    }
}
