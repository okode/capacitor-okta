import Foundation

public class Helper: NSObject {

    public static func convertParams(params: [AnyHashable : Any]) -> [String:String] {
        return Dictionary(uniqueKeysWithValues: params.compactMap { (key: AnyHashable, value: Any) in
            return (key as! String, value as! String)
        })
    }

    public static func getBiometricStatus() -> [String:Bool] {
        return [
            "isBiometricAvailable": Biometric.isAvailable(),
            "isBiometricEnabled": Storage.getBiometric() == true
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
