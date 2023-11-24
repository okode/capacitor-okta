import Foundation

public class Helper: NSObject {

    public static func convertParams(params: [AnyHashable : Any]) -> [String:String] {
        return Dictionary(uniqueKeysWithValues: params.compactMap { (key: AnyHashable, value: Any) in
            return (key as! String, value as! String)
        })
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
