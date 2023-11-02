import Foundation
import OktaStorage
import OktaOidc

@objc public class OktaConverterHelper: NSObject {

    @objc public static func convertAuthState(authStateManager: OktaOidcStateManager?) -> [String:Any] {
        guard let authStateManager = authStateManager else {
            return [:]
        }
        let accessToken = !Okta.isTokenExpired(authStateManager.accessToken) ? authStateManager.accessToken : nil
        return [
            "accessToken": accessToken ?? NSNull()
        ]
    }

}
