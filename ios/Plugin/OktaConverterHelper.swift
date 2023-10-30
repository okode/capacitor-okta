import Foundation
import OktaStorage
import OktaOidc

@objc public class OktaConverterHelper: NSObject {

    @objc public static func convertAuthState(authStateManager: OktaOidcStateManager?, secureStorage: OktaSecureStorage?) -> [String:Any] {
        guard let authStateManager = authStateManager else {
            return [:]
        }
        return [
            "accessToken": authStateManager.accessToken ?? NSNull(),
            "isBiometricSupported": secureStorage?.isFaceIDSupported() ?? false || secureStorage?.isTouchIDSupported() ?? false
        ]
    }

}
