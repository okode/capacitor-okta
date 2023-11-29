import Foundation
import WebAuthenticationUI

public class Helper: NSObject {

    public static func getOptions(params: [AnyHashable : Any]) -> [WebAuthentication.Option] {
        var options: [WebAuthentication.Option] = []
        Dictionary(uniqueKeysWithValues: params.compactMap { (key: AnyHashable, value: Any) in
            return (key as! String, value as! String)
        }).forEach { (key: String, value: String) in
            options.append(.custom(key: key, value: value))
        }
        return options
    }

    public static func getBiometricStatus(isBiometricAvailable: Bool, isBiometricEnabled: Bool) -> [String:Bool] {
        return [
            "isBiometricAvailable": isBiometricAvailable,
            "isBiometricEnabled": isBiometricEnabled
        ]
    }

    public static func convertError(error: String, message: String, code: String) -> [String:Any] {
        return [
            "error": error,
            "message": message,
            "code": code
        ]
    }

}
