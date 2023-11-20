import Foundation
import OktaStorage

@objc public class OktaConverterHelper: NSObject {

    @objc public static func convertAuthState(authStateManager: Any?) -> [String:Any] {

        return [
            "accessToken": ""
        ]
    }

    @objc public static func convertError(error: String, message: String, code: String) -> [String:Any] {
        return [
            "error": error,
            "message": message,
            "code": code
        ]
    }

}
