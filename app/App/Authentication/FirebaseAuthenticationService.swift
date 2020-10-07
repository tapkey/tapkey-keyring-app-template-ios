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
import FirebaseAuth
import AppAuth
import TapkeyMobileLib
import FirebaseAnalytics

class FirebaseAuthenticationService: PhoneNumberAuthenticationService {

    private static let TAG = String(describing: FirebaseAuthenticationService.self)

    fileprivate class TokenRefreshHandler: TKMTokenRefreshHandler {

        private static let TAG = String(describing: TokenRefreshHandler.self)

        private let authService: FirebaseAuthenticationService

        fileprivate init(authService: FirebaseAuthenticationService) {
            self.authService = authService
        }

        func refreshAuthenticationAsync(userId: String, cancellationToken: TKMCancellationToken) -> TKMPromise<String> {
            guard let user = authService.getUser() else {
                NSLog("Refresh token failed. No user is signed in")
                Analytics.logEvent(AnalyticsEvents.Events.TokenRefreshFailed, parameters: [AnalyticsEvents.Parameters.Reason: "No user is signed in"])
                return TKMAsync.promiseFromError(TKMError(errorDescriptor: TKMErrorDescriptor(
                    code: TKMAuthenticationHandlerErrorCodes.TokenRefreshFailed,
                    message: "No user is signed in",
                    details: nil)))
            }

            return TKMAsync.firstAsync { () -> TKMPromise<String> in
                return user.getIDTokenAsync()
                    .catchOnUi { asyncError in

                        let error = asyncError.syncSrcError as NSError
                        if error.domain == AuthErrorDomain,
                           let errorCode = AuthErrorCode(rawValue: error.code) {

                            switch errorCode {
                            case .invalidUserToken,
                                    .userDisabled,
                                    .userNotFound,
                                    .userTokenExpired,
                                    .userMismatch:

                                TKMLog.e(TokenRefreshHandler.TAG, "Refresh token failed permanently with error code \(errorCode)", error)
                                Analytics.logEvent(AnalyticsEvents.Events.TokenRefreshFailed, parameters: [AnalyticsEvents.Parameters.Reason: "Refresh token failed permanently with error code \(errorCode)"])

                                throw TKMError(errorDescriptor: TKMErrorDescriptor(
                                    code: TKMAuthenticationHandlerErrorCodes.TokenRefreshFailed,
                                    message: "No new token can be obtained. \(errorCode)",
                                    details: nil))

                            default:
                                NSLog("Refresh token failed temporarily with error code \(errorCode)")
                                throw asyncError
                            }
                        }

                        TKMLog.e(TokenRefreshHandler.TAG, "Refresh token failed", error)
                        throw asyncError
                    }
            }
            .continueAsyncOnUi { firebaseIdToken in
                guard let firebaseIdToken = firebaseIdToken else {
                    NSLog("Refreshed firebase IdToken  was nil")
                    return TKMAsync.promiseFromError(TKMRuntimeError.illegalState("Refresh token failed. Token was nil"))
                }

                return self.authService.exchangeForTapkeyToken(idToken: firebaseIdToken)
            }
        }

        func onRefreshFailed(userId: String) {
            authService.refreshFailedDelegate?()
        }

    }

    public var refreshFailedDelegate: (() -> Void)? = nil
    private(set) lazy var tokenRefreshHandler: TKMTokenRefreshHandler = TokenRefreshHandler(authService: self)

    public func isUserLoggedIn() -> Bool {
        return (Auth.auth().currentUser != nil)
    }

    func getUser() -> User? {
        return Auth.auth().currentUser
    }

    public func getUserPhoneNumber() -> String? {
        Auth.auth().currentUser?.phoneNumber
    }

    public func verifyPhoneNumber(_ phoneNumber: String) -> TKMPromise<String> {
        setAuthLanguage()
        return PhoneAuthProvider.verifyPhoneNumberAsync(phoneNumber: phoneNumber, uiDelegate: nil)
    }

    public func verifyCodeAsync(verificationId: String, verificationCode code: String) -> TKMPromise<String> {

        let credential = PhoneAuthProvider.provider()
            .credential(
                withVerificationID: verificationId,
                verificationCode: code)

        return Auth.auth()
            .signInAsync(with: credential)
            .catchOnUi { error -> AuthDataResult in
                TKMLog.e(FirebaseAuthenticationService.TAG, "Failed to verify code", error)
                throw error
            }
            .continueAsyncOnUi { (authResult: AuthDataResult?) -> TKMPromise<String> in

                guard let authResult = authResult else {
                    TKMLog.e(FirebaseAuthenticationService.TAG, "AuthResult was nil")
                    return TKMAsync.promiseFromError(NSError(domain: "Unknown_sign_in_error", code: 401, userInfo: [:]))
                }

                return authResult.user.getIDTokenAsync()
                    .catchOnUi { error in
                        TKMLog.e(FirebaseAuthenticationService.TAG, "Failed to fetch the idToken", error)
                        throw error
                    }
            }
            .continueAsyncOnUi { firebaseIdToken -> TKMPromise<String> in

                guard let firebaseIdToken = firebaseIdToken else {
                    TKMLog.e(FirebaseAuthenticationService.TAG, "FirebaseIdToken was nil")
                    return TKMAsync.promiseFromError(NSError(domain: "Unknown_get_token_id_error", code: 401, userInfo: [:]))
                }

                return self.exchangeForTapkeyToken(idToken: firebaseIdToken)
            }
    }

    public func signOut() {
        do {
            try Auth.auth().signOut()
        } catch _ { }
    }

    private func setAuthLanguage() {
        guard var languageCode = Bundle.main.preferredLocalizations.first else {
            return
        }
        if languageCode.count >= 2 {
            languageCode = String(languageCode.prefix(2))
            Auth.auth().languageCode = languageCode
        }
    }

    fileprivate func exchangeForTapkeyToken(idToken: String) -> TKMPromise<String> {

        let issuer = URL(string: AppConfiguration.tapkeyAuthorizationEndpoint)!
        let gratType = "http://tapkey.net/oauth/token_exchange"
        let clientId = AppConfiguration.tapkeyOAuthClientId

        return TKMAsync.firstAsync { () -> TKMPromise<OIDServiceConfiguration> in
            return OIDAuthorizationService.discoverConfigurationAsync(forIssuer: issuer)
                .catchOnUi { asyncError -> OIDServiceConfiguration? in
                    TKMLog.e(FirebaseAuthenticationService.TAG, "Error retrieving discovery document", asyncError.syncSrcError)
                    throw asyncError
                }
        }
        .continueAsyncOnUi { (configuration: OIDServiceConfiguration?) -> TKMPromise<OIDTokenResponse> in
            guard let configuration = configuration else {
                TKMLog.e(FirebaseAuthenticationService.TAG, "OIDServiceConfiguration was nil")
                return TKMAsync.promiseFromError(NSError(domain: "DEFAULT_ERROR", code: 100, userInfo: nil))
            }

            let parameters = [
                "provider": AppConfiguration.tapkeyIdentityProviderId,
                "subject_token_type": "jwt",
                "subject_token": idToken,
                "audience": "tapkey_api",
                "requested_token_type": "access_token"
            ]

            let tokenRequest = OIDTokenRequest(configuration: configuration,
                                               grantType: gratType,
                                               authorizationCode: nil,
                                               redirectURL: nil,
                                               clientID: clientId,
                                               clientSecret: nil,
                                               scopes: ["register:mobiles", "read:user", "handle:keys"],
                                               refreshToken: nil,
                                               codeVerifier: nil,
                                               additionalParameters: parameters)

            return OIDAuthorizationService.performAsync(tokenRequest)
                .catchOnUi { asyncError in
                    TKMLog.e(FirebaseAuthenticationService.TAG, "Failed to perform token exchange request", asyncError.syncSrcError)
                    throw asyncError
                }
        }
        .continueOnUi { tokenResponse in

            guard let tokenResponse = tokenResponse else {
                throw NSError(domain: "Missing_response", code: 401, userInfo: [:])
            }

            guard let accessToken = tokenResponse.accessToken else {
                throw NSError(domain: "Missing_access_token", code: 401, userInfo: [:])
            }

            return accessToken
        }
    }
}
