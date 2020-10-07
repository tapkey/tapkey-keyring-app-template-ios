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
import TapkeyMobileLib

public class MessageResolver {

    static let sharedService = MessageResolver()

    public func getMessage(commandResultCode: TKMCommandResult.TKMCommandResultCode) -> String {

        switch commandResultCode {
        case .ok:
            return Localization.success.localized()

        case .wrongLockMode:
            return Localization.wrongLockMode.localized()

        case .lockVersionTooOld:
            return Localization.lockVersionTooOld.localized()

        case .lockVersionTooYoung:
            return Localization.lockVersionTooYoung.localized()

        case .lockNotFullyAssembled:
            return Localization.lockNotFullyAssembled.localized()

        case .serverCommunicationError:
            return Localization.serverCommunicationError.localized()

        case .lockDateTimeInvalid:
            return Localization.lockDateTimeInvalid.localized()

        case .temporarilyUnauthorized,
             .unauthorized_notYetValid:
            return Localization.unauthorizedNotYetValid.localized()

        case .unauthorized:
            return Localization.unauthorized.localized()

        case .lockCommunicationError:
            return Localization.lockCommunicationError.localized()

        case .userSpecificError,
             .technicalError:
            fallthrough

        default:
            return Localization.genericError.localized()
        }
    }
}

internal enum Localization: String {

    case empty = ""
    case success
    case wrongLockMode
    case unauthorized
    case unauthorizedNotYetValid
    case lockVersionTooOld
    case lockVersionTooYoung
    case lockNotFullyAssembled
    case serverCommunicationError
    case lockCommunicationError
    case genericError
    case lockDateTimeInvalid

    func localized() -> String {
        return self.rawValue.localized()
    }
}
