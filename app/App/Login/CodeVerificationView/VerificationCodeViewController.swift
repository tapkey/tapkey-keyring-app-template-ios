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

private let defaultResendIn = 60

class VerificationCodeViewController: UIViewController, Storyboarded {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var enterCodeLabel: UILabel!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var resendCodeButton: UIButton!

    var viewModel: VerificationCodeViewModel?
    var resendInSeconds = defaultResendIn
    var resendCodeTimer: Timer?

    // MARK: Actions
    @IBAction func verifyCode(_ sender: Any) {
        guard let code = codeTextField.text else {
            return
        }
        viewModel?.verifyCode(code)
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }

    @IBAction func resendCode(_ sender: Any) {
        print("Resend code triggered")
        resendCodeButton.isEnabled = false
        resendInSeconds = defaultResendIn
        updateResendButtonTitle()
        setupResendCodeTimer()
        viewModel?.resendCode()
    }

    // MARK: Setup UI
    private func setupCodeTextFied() {
        codeTextField.delegate = self
        codeTextField.placeholder = "123456"
        codeTextField.textColor = Theme.lightColor
        codeTextField.textAlignment = .center
        // add white bottom line
        codeTextField.addBottomLine(withColor: Theme.lightColor)
        codeTextField.borderStyle = .none
        codeTextField.becomeFirstResponder()
    }

    private func setupContinueButton() {
        continueButton.setTitle("continue_sign_in".localized(), for: .normal)
        continueButton.setTitleColor(Theme.lightColor, for: .normal)
        continueButton.setTitleColor(Theme.disabledColor, for: .disabled)
        continueButton.isEnabled = false
    }

    private func setupResendCodeButton() {
        resendCodeButton.setTitleColor(Theme.lightColor, for: .normal)
        resendCodeButton.setTitleColor(Theme.disabledColor, for: .disabled)
        resendCodeButton.isEnabled = false
        updateResendButtonTitle()
    }

    // MARK: Helpers
    private func updateResendButtonTitle() {
        var buttonTitle = ""
        if resendInSeconds == 0 {
            buttonTitle = "resend_code".localized()
        } else {
            buttonTitle = "resend_code_in".localized() + ": \(resendInSeconds)"
        }
        resendCodeButton.setTitle(buttonTitle, for: .normal)
    }

    private func setupResendCodeTimer() {
        resendCodeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {[weak self] _ in
            self?.resendInSeconds -= 1
            self?.updateResendButtonTitle()
            if self?.resendInSeconds == 0 {
                self?.resendCodeButton.isEnabled = true
                self?.resendCodeTimer?.invalidate()
            }
        }
    }

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.darkColor
        scrollView.backgroundColor = Theme.darkColor
        contentView.backgroundColor = Theme.darkColor
        enterCodeLabel.text = "enter_the_code_that_was_sent_to_you".localized()

        setupContinueButton()
        setupResendCodeButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupResendCodeTimer()

        // configure the textfild only once
        guard codeTextField.delegate == nil else {
            return
        }
        setupCodeTextFied()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resendCodeTimer?.invalidate()
        MBProgressHUD.hide(for: self.view, animated: true)
    }
}

// MARK: UITextFieldDelegate
extension VerificationCodeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let numberLenth = textField.text?.count ?? 0
        if numberLenth == 1 && string.isEmpty {
            continueButton.isEnabled = false
        } else {
            continueButton.isEnabled = true
        }
        return true
    }
}

// MARK: CodeValidationViewDelegate
extension VerificationCodeViewController: VerificationCodeViewModelDelegate {
    func showValidation(codeError: VerificationError) {
        var messageString = "code_error".localized()
        if codeError == .invalidCode {
            messageString = "wrong_code".localized()
        }

        MBProgressHUD.hide(for: self.view, animated: true)
        let alert = UIAlertController(title: nil,
                                      message: messageString,
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "ok".localized(), style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
}
