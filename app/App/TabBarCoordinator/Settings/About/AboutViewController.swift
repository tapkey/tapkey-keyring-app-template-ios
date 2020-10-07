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

class AboutViewController: UIViewController, Storyboarded {

    // MARK: - Outlets
    @IBOutlet private weak var versionView: IconAndTextView!
    @IBOutlet private weak var companyView: IconAndTextView!
    @IBOutlet private weak var termsAndConditionsView: IconAndTextView!

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "menu_about".localized()
        setupView()
    }

    func setupView() {
        versionView.set(iconImage: UIImage(named: Theme.ImageNames.info.rawValue), andText: String(format: "version".localized(), UIApplication.appVersion))
        companyView.set(iconImage: UIImage(named: Theme.ImageNames.copyright.rawValue), andText: "address".localized())
        termsAndConditionsView.set(iconImage: UIImage(named: Theme.ImageNames.file.rawValue), andText: "terms_and_conditions".localized(), delegate: self)
    }

}

extension AboutViewController: IconAndTextViewDelegate {

    func didTapOnView(_ view: IconAndTextView) {
        guard let tosURL = URL(string: "tos_url".localized()) else {
            return
        }
        if UIApplication.shared.canOpenURL(tosURL) {
            UIApplication.shared.open(tosURL, options: [:], completionHandler: nil)
        }
    }
}
