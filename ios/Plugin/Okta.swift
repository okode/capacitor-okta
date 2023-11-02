import Foundation
import OktaOidc
import Capacitor
import OktaStorage

@objc public class Okta: NSObject {

    private static let KEYCHAIN_GROUP_KEY = "secureshare"
    private static let KEYCHAIN_DATA_KEY = "okta_user"
    private static let KEYCHAIN_BIOMETRIC_KEY = "okta_user_biometric"

    var authStateDelegate: OktaAuthStateDelegate?

    private var authSession: OktaOidc? = nil
    private var authStateManager: OktaOidcStateManager? = nil
    private var secureStorage: OktaSecureStorage? = nil

    @objc public func configureSDK(callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) -> Void {
        guard let config = try? OktaOidcConfig.default(),
          let oktaAuth = try? OktaOidc(configuration: config) else {
            // Fatal error as the configuration isn't editable in this app.
            return callback(nil, NSError(domain: "com.okode.okta", code: 404, userInfo: [NSLocalizedDescriptionKey: "Error configuring SDK. Check config"]))
        }
        self.authSession = oktaAuth
        self.secureStorage = OktaSecureStorage()
        // Check for an existing session
        self.authStateManager = OktaOidcStateManager.readFromSecureStorage(for: config)
        callback(self.authStateManager, nil)
        resumeSession()
        checkBiometric()
    }

    @objc public func signIn(vc: UIViewController?, params: [AnyHashable : Any], biometric: Bool, callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {

        var urlParams = Dictionary(uniqueKeysWithValues: params.compactMap { (key: AnyHashable, value: Any) in
            return (key as! String, value as! String)
        })

        if (self.isBiometricEnabled() && biometric) {
            refreshToken { authState, error in
                if error != nil {
                    urlParams["prompt"] = "login"
                    self.signInWithBrowser(vc: vc, params: urlParams) { authState, error in
                        if error != nil {
                            return callback(nil, error)
                        }
                        self.notifyAuthStateChange()
                        callback(self.authStateManager, nil)
                    }
                    return
                }
                self.notifyAuthStateChange()
                callback(authState, nil)
            }
            return
        }

        self.signInWithBrowser(vc: vc, params: urlParams) { authState, error in
            if error != nil {
                return callback(nil, error)
            }
            callback(self.authStateManager, nil)
            self.notifyAuthStateChange()
        }
    }

    @objc public func signOut(vc: UIViewController?, callback: @escaping ((_ result: NSNumber?, _ error: Error?) -> Void)) {
            guard let vc = vc else {
                return callback(nil, NSError(domain: "com.okode.okta", code: 400, userInfo: [NSLocalizedDescriptionKey: "Not a valid view controller provided"]))
            }

            guard let authSession = self.authSession else {
                return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth session initialized"]))
            }

            guard let authStateManager = self.authStateManager else {
                return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth state manager"]))
            }

            authSession.signOut(authStateManager: authStateManager, from: vc, progressHandler: { options in
            }, completionHandler: { success, opts in
                if (!success) {
                    return callback(nil, NSError(domain: "com.okode.okta", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error signing out"]))
                }
                self.clearSecureStorage()
                self.authStateManager = nil
                callback(NSNumber(value: opts.rawValue), nil)
            })
        }

    @objc public func enableBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {

        guard let secureStorage = self.secureStorage else {
            return callback(["":false], NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No secure storage initialized"]))
        }

        guard let authStateManager = self.authStateManager else {
            return callback(["":false], NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth state manager"]))
        }

        setBiometric(value: true)
        self.writeToSecureStorage(secureStorage: secureStorage, authStateManager: authStateManager)
        callback(self.getBiometricStatus(), nil)
    }

    @objc public func disableBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {

        guard let authStateManager = self.authStateManager else {
            return callback(["":false], NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth state manager"]))
        }

        clearSecureStorage()
        setBiometric(value: false)
        callback(getBiometricStatus(), nil)
    }

    @objc public func resetBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {

        guard let authStateManager = self.authStateManager else {
            return callback(["":false], NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth state manager"]))
        }

        clearSecureStorage()
        callback(self.getBiometricStatus(), nil)
    }

    @objc public func getBiometricStatus(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {
        callback(self.getBiometricStatus(), nil)
    }


    @objc public func getAuthState() ->  OktaOidcStateManager? {
        return authStateManager;
    }

    @objc public static func isTokenExpired(_ tokenString: String?) -> Bool {
      guard let token = tokenString,
      let tokenInfo = OKTIDToken.init(idTokenString: token) else {
        return false
      }

      return Date() > tokenInfo.expiresAt
    }

    private func refreshToken(callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {

        guard let secureStorage = self.secureStorage else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No secure storage initialized"]))
        }

        DispatchQueue.global().async {
            do {
                let authStateData = try secureStorage.getData(key: Okta.KEYCHAIN_DATA_KEY)
                guard let stateManager = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(authStateData) as? OktaOidcStateManager else {
                    return
                }
                stateManager.renew { authStateManager, error in
                    if let error = error {
                        return callback(nil, error)
                    }
                    self.authStateManager = authStateManager
                    authStateManager?.writeToSecureStorage()
                    callback(self.authStateManager, nil)
                }
            } catch let error as NSError {
                return callback(nil, error)
            }
        }

    }

    private func signInWithBrowser(vc: UIViewController?, params: [String:String], callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {
        guard let vc = vc else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 400, userInfo: [NSLocalizedDescriptionKey: "Not a valid view controller provided"]))
        }

        guard let authSession = self.authSession else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth session initialized"]))
        }

        guard let secureStorage = self.secureStorage else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No secure storage initialized"]))
        }

        authSession.signInWithBrowser(from: vc, additionalParameters: params, callback: { authStateManager, error in
            if error != nil {
                return callback(nil, error)
            }
            if (!self.isBiometricConfigured() && self.isBiometricSupported()) {
                self.showBiometricDialog(vc: vc, secureStorage: secureStorage, authStateManager: authStateManager)
            }
            self.writeToSecureStorage(secureStorage: secureStorage, authStateManager: authStateManager)
            self.authStateManager = authStateManager
            authStateManager?.writeToSecureStorage()
            callback(self.authStateManager, nil)
        })
    }

    private func notifyAuthStateChange() {
        self.authStateDelegate?.onOktaAuthStateChange(authState: getAuthState())
    }

    private func isBiometricSupported() -> Bool {
        guard let secureStorage = self.secureStorage else {
            return false
        }

        return secureStorage.isFaceIDSupported() || secureStorage.isTouchIDSupported()
    }

    private func isBiometricEnabled() -> Bool {
        guard let secureStorage = self.secureStorage else {
            return false
        }

        do {
            let biometric = try secureStorage.get(key: Okta.KEYCHAIN_BIOMETRIC_KEY)
            return isBiometricSupported()
                    && biometric == "true"
        } catch _ {
            return false
        }
    }

    private func isBiometricConfigured() -> Bool {
        guard let secureStorage = self.secureStorage else {
            return true
        }

        do {
            try secureStorage.get(key: Okta.KEYCHAIN_BIOMETRIC_KEY)
            return true
        } catch _ {
            return false
        }
    }

    private func writeToSecureStorage(secureStorage: OktaSecureStorage, authStateManager: OktaOidcStateManager?) {
        let authStateData = try? NSKeyedArchiver.archivedData(withRootObject: authStateManager, requiringSecureCoding: false)
        guard let authStateData = authStateData else {
            return
        }

        if (!self.isBiometricEnabled()) { return }

        do {
            try secureStorage.set(data: authStateData,
                                  forKey: Okta.KEYCHAIN_DATA_KEY,
                                  behindBiometrics: true)
            setBiometric(value: true)
        } catch _ {
            setBiometric(value: false)
        }
    }

    private func clearSecureStorage() {
        guard let secureStorage = self.secureStorage else {
            return
        }

        do {
            try secureStorage.delete(key: Okta.KEYCHAIN_DATA_KEY)
            try secureStorage.delete(key: Okta.KEYCHAIN_BIOMETRIC_KEY)
        } catch _ { }
    }

    private func showBiometricDialog(vc: UIViewController?, secureStorage: OktaSecureStorage, authStateManager: OktaOidcStateManager?) {
            let alert = UIAlertController(title: "Acceso biométrico", message: "¿Quieres utilizar el biométrico para futuros accesos?", preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: { (action: UIAlertAction!) in
                self.enableBiometric { success, error in }
            }))

            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (action: UIAlertAction!) in
                self.disableBiometric { success, error in }
            }))

            vc?.present(alert, animated: true, completion: nil)
    }

    private func resumeSession() {
        if (self.isBiometricEnabled() || self.authStateManager?.accessToken == nil) { return }
        self.notifyAuthStateChange()
    }

    private func getBiometricStatus() -> [String:Bool] {
        guard let secureStorage = self.secureStorage else {
            return ["": false]
        }

        return [
            "isBiometricEnabled":self.isBiometricEnabled(),
            "isBiometricSupported":self.isBiometricSupported()
        ]
    }

    private func setBiometric(value: Bool) {
        guard let secureStorage = self.secureStorage else {
            return
        }

        do {
            try secureStorage.set(String(value), forKey: Okta.KEYCHAIN_BIOMETRIC_KEY)
        } catch _ { }
    }

    private func checkBiometric() {
        guard let secureStorage = self.secureStorage else {
            return
        }

        do {
            let biometricEnabled = try secureStorage.get(key: Okta.KEYCHAIN_BIOMETRIC_KEY)
            if (!isBiometricSupported() && biometricEnabled == "true") {
                clearSecureStorage()
            }
        } catch _ { }
    }

}
