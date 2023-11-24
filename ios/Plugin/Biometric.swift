import Foundation
import LocalAuthentication

@objc public class Biometric: NSObject {

    @available(iOS 13.0.0, *)
    public static func verifyIdentity() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let context = LAContext()
                context.localizedFallbackTitle = ""
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                           localizedReason: "Acceso biométrico") { success, authenticationError in
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    public static func isAvailable() -> Bool {
        var error: NSError?
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        return true
    }

}
