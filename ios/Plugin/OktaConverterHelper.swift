import Foundation
import OktaOidc

@objc public class OktaConverterHelper: NSObject {

    @objc public static func convertAuthState(authStateManager: OktaOidcStateManager?) -> [String:Any] {
        guard let authStateManager = authStateManager else {
            return [:]
        }
        return [
            "isAuthenticated": authStateManager.authState.isAuthorized,
            "accessToken": authStateManager.accessToken ?? NSNull(),
            "refreshToken": authStateManager.refreshToken ?? NSNull(),
            "idToken": authStateManager.idToken ?? NSNull()
        ]
    }

}
