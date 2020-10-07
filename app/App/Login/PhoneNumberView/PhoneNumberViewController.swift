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

class PhoneNumberViewController: UIViewController, Storyboarded {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var termsAndConditionsSwitch: UISwitch!
    @IBOutlet weak var termsAndConditionsLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!

    var viewModel: PhoneNumberViewModel?

    // MARK: Actions
    @IBAction func signIn(_ sender: Any) {
        guard let phoneNumber = phoneNumberTextField.text else {
            return
        }
        if !phoneNumber.hasPrefix("+") {
            showNumberError()
        } else {
            viewModel?.verifyPhoneNumber(phoneNumber)
        }
    }

    @IBAction func acceptTermsAndConditions(_ sender: Any) {
        let numberLenth = phoneNumberTextField.text?.count ?? 0
        if termsAndConditionsSwitch.isOn && numberLenth != 0 {
            signInButton.isEnabled = true
        } else {
            signInButton.isEnabled = false
        }
    }

    // MARK: Setup UI
    private func setupNumberTextFied() {
        phoneNumberTextField.delegate = self
        phoneNumberTextField.placeholder = "+49123456789"
        phoneNumberTextField.textColor = Theme.lightColor
        phoneNumberTextField.textAlignment = .center
        // add white bottom line
        phoneNumberTextField.addBottomLine(withColor: Theme.lightColor)
        phoneNumberTextField.borderStyle = .none
    }

    private func setupTermsAndConditionsLabel() {
        let tosText = "i_accept_the_terms_and_conditions".localized().replacingOccurrences(of: "<u>", with: "")
        let range = ("i_accept_the_terms_and_conditions".localized() as NSString).range(of: "<u>")
        let attributedString = NSMutableAttributedString(string: tosText)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: range.location, length: tosText.count - range.location - 1))

        termsAndConditionsLabel.attributedText = attributedString
        termsAndConditionsLabel.adjustsFontSizeToFitWidth = true
        termsAndConditionsLabel.isUserInteractionEnabled = true
        termsAndConditionsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapTermsAndConditions)))
    }

    private func setupSignInButton() {
        signInButton.setTitleColor(Theme.lightColor, for: .normal)
        signInButton.setTitleColor(Theme.disabledColor, for: .disabled)
        signInButton.isEnabled = false
    }

    private func setupDismissKeyboardTapGesture() {
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.darkColor
        scrollView.backgroundColor = Theme.darkColor
        contentView.backgroundColor = Theme.darkColor
        logoImageView.image = UIImage(named: Theme.ImageNames.logo.rawValue)
        signInLabel.text = "sign_in_using_your_phone_number".localized()

        setupTermsAndConditionsLabel()
        setupSignInButton()
        setupDismissKeyboardTapGesture()
        subsctibeForNotificaions()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // configure the textfild only once
        guard phoneNumberTextField.delegate == nil else {
            return
        }
        setupNumberTextFied()
    }

    // MARK: Helpers
    @objc func dismissKeyboard() {
        phoneNumberTextField.resignFirstResponder()
    }

    private func showNumberAlertError() {
        let alert = UIAlertController(title: nil,
                                      message: "phone_number_error_missing_code".localized(),
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "ok".localized(), style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }

    @objc private func didTapTermsAndConditions() {
        guard let tosURL = URL(string: "tos_url".localized()) else {
            return
        }
        if UIApplication.shared.canOpenURL(tosURL) {
            UIApplication.shared.open(tosURL, options: [:], completionHandler: nil)
        }
    }
}

// MARK: Notifications Notifications
extension PhoneNumberViewController {
    private func subsctibeForNotificaions() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
            scrollView.scrollToBottom(animated: true)
        } else {
            let keyboardInset = view.frame.size.height - keyboardScreenEndFrame.origin.y
            let signInBottomInset = signInButton.frame.origin.y + signInButton.frame.size.height
            if keyboardScreenEndFrame.origin.y < signInBottomInset {
                scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardInset, right: 0)
                scrollView.scrollToBottom(animated: true)
            }
        }
    }
}

extension PhoneNumberViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let numberLenth = textField.text?.count ?? 0
        if numberLenth == 1 && string.isEmpty {
            signInButton.isEnabled = false
        } else if !termsAndConditionsSwitch.isOn {
            signInButton.isEnabled = false
        } else {
            signInButton.isEnabled = true
        }
        return true
    }
}

extension PhoneNumberViewController: PhoneNumberViewModelDelegate {
    func showNumberError() {
        showNumberAlertError()
    }
}
