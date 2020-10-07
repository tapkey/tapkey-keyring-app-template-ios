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
import TapkeyFcm
import Firebase
import FirebaseAnalytics
import Sentry

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private static let TAG: String = String(describing: AppDelegate.self)

    var coordinator: AppCoordinator!

    private var _tapkeyServiceFactory: TKMServiceFactory!
    private var _phoneNumberAuthenticationService: PhoneNumberAuthenticationService!
    private var _firebaseNotificationService: TKMFirebasePushNotificationService!

    func setupExternalFrameworks() {

        let tapkeyKeyringAppTemplateVersion = Bundle.main.infoDictionary?["tapkeyKeyringAppTemplateVersion"] ?? "unknown"

        if let sentryDSN = AppConfiguration.sentryDSN, !sentryDSN.isEmpty {
            SentrySDK.start { options in
                options.dsn = AppConfiguration.sentryDSN
                options.debug = false
                options.beforeSend = { e in
                    if e.extra == nil {
                        e.extra = [:]
                    }
                    e.extra?[AnalyticsEvents.Parameters.TapkeyKeyringAppTemplateVersion] = tapkeyKeyringAppTemplateVersion
                    return e
                }
            }
        }

        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        Analytics.setDefaultEventParameters([AnalyticsEvents.Parameters.TapkeyKeyringAppTemplateVersion: tapkeyKeyringAppTemplateVersion])
    }

    func setupAppeareance() {
        UINavigationBar.appearance().tintColor = Theme.darkColor
    }

    // MARK: App Delegate
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAppeareance()
        setupExternalFrameworks()

        // create a basic UIWindow and activate it
        let window = UIWindow(frame: UIScreen.main.bounds)

        let config = TKMEnvironmentConfigBuilder()
            .setBaseUri(AppConfiguration.tapkeyBaseUri)
            .build()

        let tapkeyAdvertisingFormatBuilder = TKMBleAdvertisingFormatBuilder()
            .addV2Format(domainId: AppConfiguration.tapkeyDomainId)

        if let v1BleServiceId = AppConfiguration.tapkeyBleServiceUuid, !v1BleServiceId.isEmpty {
            _ = tapkeyAdvertisingFormatBuilder.addV1Format(serviceUuid: v1BleServiceId)
        }

        let tapkeyAdvertisingFormat = tapkeyAdvertisingFormatBuilder.build()

        let firebaseAuthenticationService = FirebaseAuthenticationService()
        self._phoneNumberAuthenticationService = firebaseAuthenticationService

        self._tapkeyServiceFactory = TKMServiceFactoryBuilder()
            .setTokenRefreshHandler(firebaseAuthenticationService.tokenRefreshHandler)
            .setConfig(config)
            .setBluetoothAdvertisingFormat(tapkeyAdvertisingFormat)
            .withFirebaseCloudMessaging()
            .build()

        guard let pushNotificationManager = self._tapkeyServiceFactory.pushNotificationManager else {
            fatalError("Push notification is not configured properly")
        }

        self._firebaseNotificationService = TKMFirebasePushNotificationService(pushNotificationManager: pushNotificationManager)

        coordinator = AppCoordinator(window, phoneNumberAuthenticationService: firebaseAuthenticationService, tapkeyServiceFactory: tapkeyServiceFactory)
        coordinator.start()

        window.makeKeyAndVisible()

        Analytics.logEvent(AnalyticsEvents.Events.AppStarted, parameters: nil)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        TKMLog.d(AppDelegate.TAG, "Running background fetch")

        // prevent app to sleep until fetching is completed
        runAsyncInBackground(
            application,
            promise: TKMAsync.firstAsync { () -> TKMPromise<Void> in
                return self.tapkeyServiceFactory.notificationManager
                    .pollForNotificationsAsync(cancellationToken: TKMCancellationTokens.None)
                    .catchOnUi { asyncError in
                        let syncSrcError = asyncError.syncSrcError
                        TKMLog.e(AppDelegate.TAG, "Failed to poll for notifcations", syncSrcError)
                        return nil
                    }
            }
            .finallyOnUi {
                TKMLog.d(AppDelegate.TAG, "Background fetch finished")
                completionHandler(.newData)
            }
        )
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler handler: @escaping (UIBackgroundFetchResult) -> Void ) {
        self._firebaseNotificationService
            .didReceiveRemoteNotification(userInfo, fetchCompletionHandler: handler)
    }

    public var tapkeyServiceFactory: TKMServiceFactory {
        return _tapkeyServiceFactory
    }

    public var phoneNumberAuthenticationService: PhoneNumberAuthenticationService {
        return self._phoneNumberAuthenticationService
    }
}
