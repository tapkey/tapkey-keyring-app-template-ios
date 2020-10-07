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

class KeyCell: UITableViewCell {

    var viewRefreshHandler: (() -> Void)? = nil

    @IBOutlet private weak var circleViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var circleView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var openButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var triggerStatusImageView: UIImageView!
    @IBOutlet weak var errorMessageLabel: UILabel!

    var viewModel: KeyViewModel! {
        didSet {
            refreshView()
            viewModel.viewRefreshHandler = {
                self.refreshView()
            }
        }
    }

    @IBAction func didPressOpenButton(_ sender: Any) {
        viewModel.triggerLock()
    }

    override func awakeFromNib() {
        circleView.layer.cornerRadius = circleViewWidthConstraint.constant / 2
        circleView.clipsToBounds = true
        setupColors()
        super.awakeFromNib()
    }

    private func setupColors() {
        openButton.setTitle("open".localized().capitalized, for: .normal)
        openButton.setTitleColor(Theme.darkColor, for: .normal)
        activityIndicator.color = Theme.darkColor
    }

    private func refreshView() {
        circleView.backgroundColor = viewModel.isNearby ? Theme.darkColor : Theme.disabledColor
        iconImageView.image = UIImage(named: Theme.ImageNames.key.rawValue)
        nameLabel.text = viewModel.title
        openButton.isHidden = !viewModel.isNearby
        triggerStatusImageView.isHidden = true
        statusLabel.text = viewModel.hasUnlimitedValidity ? "unrestricted".localized() : "restricted".localized()
        errorMessageLabel.text = ""
        errorMessageLabel.isHidden = true

        if viewModel.isNearby {
            switch viewModel.lockState {
            case .idle:
                activityIndicator.stopAnimating()
                openButton.isHidden = false
                triggerStatusImageView.isHidden = true
                errorMessageLabel.text = ""
                errorMessageLabel.isHidden = true

            case .triggerInProgress:
                activityIndicator.startAnimating()
                openButton.isHidden = true
                triggerStatusImageView.isHidden = true
                errorMessageLabel.text = ""
                errorMessageLabel.isHidden = true

            case .triggerSuccessfully:
                activityIndicator.stopAnimating()
                openButton.isHidden = true
                triggerStatusImageView.isHidden = false
                triggerStatusImageView.image = UIImage(named: Theme.ImageNames.triggerStatusSuccess.rawValue)
                errorMessageLabel.text = ""
                errorMessageLabel.isHidden = true

            case .triggerFailed:
                activityIndicator.stopAnimating()
                openButton.isHidden = true
                triggerStatusImageView.isHidden = false
                triggerStatusImageView.image = UIImage(named: Theme.ImageNames.triggerStatusFailure.rawValue)
                if let errorMessage = viewModel.errorMessage {
                    errorMessageLabel.text = errorMessage
                    errorMessageLabel.isHidden = false
                } else {
                    errorMessageLabel.text = ""
                    errorMessageLabel.isHidden = true
                }
            }
        }
    }
}
