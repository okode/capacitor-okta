import Foundation
import LocalAuthentication
import OktaOidc
import Capacitor
import OktaStorage

@objc public class Okta: NSObject {

    private static let BUNDLE_ID = Bundle.main.bundleIdentifier ?? ""
    private static let KEYCHAIN_DATA_KEY = BUNDLE_ID + "okta_user"
    private static let KEYCHAIN_BIOMETRIC_KEY = BUNDLE_ID + "okta_user_biometric"

    var oktaDelegate: OktaDelegate?

    private var authSession: OktaOidc? = nil
    private var authStateManager: OktaOidcStateManager? = nil
    private var secureStorage: OktaSecureStorage? = nil

    @objc public func configureSDK(config: [String : String], callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) -> Void {
        guard let config = try? OktaOidcConfig(with: ["scopes":config["scopes"]!, "redirectUri":config["redirectUri"]!, "clientId":config["clientId"]!, "issuer":config["uri"]!, "logoutRedirectUri":config["endSessionUri"]!]),
          let oktaAuth = try? OktaOidc(configuration: config) else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 404, userInfo: [NSLocalizedDescriptionKey: "Error configuring SDK. Check config"]))
        }
        self.authSession = oktaAuth
        self.secureStorage = OktaSecureStorage()
        self.authStateManager = OktaOidcStateManager.readFromSecureStorage(for: config)
        callback(self.authStateManager, nil)
    }

    @objc public func signIn(vc: UIViewController?, params: [AnyHashable : Any], promptLogin: Bool, callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {

        var showLogin = promptLogin
        let isAuthenticated = (!Okta.isTokenExpired(authStateManager?.accessToken) ? authStateManager?.accessToken : nil) != nil

        if (isBiometricLocked()) { showLogin = true }
        if (!showLogin && !self.isBiometricEnabled() && isAuthenticated) {
            self.notifyAuthStateChange()
            return
        }

        var urlParams = Dictionary(uniqueKeysWithValues: params.compactMap { (key: AnyHashable, value: Any) in
            return (key as! String, value as! String)
        })

        if (!showLogin && self.isBiometricEnabled() && self.isBiometricAvailable()) {
            refreshToken { authState, error in
                if error != nil {
                    self.signIn(vc: vc, params: params, promptLogin: true, callback: callback)
                    return
                }
                callback(authState, nil)
            }
            return
        }

        if (showLogin) { urlParams["prompt"] = "login" }
        self.signInWithBrowser(vc: vc, params: urlParams, callback: callback)
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

        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Acceso biométrico") {
            success, authenticationError in
            if (success) {
                self.setBiometric(value: true)
                self.writeToSecureStorage(secureStorage: secureStorage, authStateManager: authStateManager)
            }
            callback(self.getBiometricStatus(), nil)
        }
    }

    @objc public func disableBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {

        clearSecureStorage()
        setBiometric(value: false)
        callback(getBiometricStatus(), nil)
    }

    @objc public func resetBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {

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
                    if error != nil {
                        self.notifyError(error: "REFRESH_ERROR", message: error?.localizedDescription ?? "", code: "")
                        return callback(nil, error)
                    }
                    self.authStateManager = authStateManager
                    authStateManager?.writeToSecureStorage()
                    self.notifyAuthStateChange()
                    callback(self.authStateManager, nil)
                }
            } catch let error as NSError {
                let e = self.getBiometricError()
                self.notifyError(error: "BIOMETRIC_ERROR", message: e?.localizedDescription ?? error.localizedDescription, code: String(e?.code ?? 0))
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
            if (self.isBiometricEnabled() && !self.isBiometricAvailable() && !self.isBiometricLocked()) {
                self.clearSecureStorage()
            }
            if (!self.isBiometricConfigured() && self.isBiometricAvailable()) {
                self.showBiometricDialog(vc: vc, secureStorage: secureStorage, authStateManager: authStateManager)
            }
            self.writeToSecureStorage(secureStorage: secureStorage, authStateManager: authStateManager)
            self.authStateManager = authStateManager
            authStateManager?.writeToSecureStorage()
            self.notifyAuthStateChange()
            callback(self.authStateManager, nil)
        })
    }

    private func notifyAuthStateChange() {
        self.oktaDelegate?.onOktaAuthStateChange(authState: getAuthState())
    }

    private func notifyError(error: String, message: String, code: String) {
        self.oktaDelegate?.onOktaError(error: error, message: message, code: code)
    }

    private func isBiometricAvailable() -> Bool {
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
            return biometric == "true"
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

    private func getBiometricStatus() -> [String:Bool] {
        return [
            "isBiometricEnabled":self.isBiometricEnabled(),
            "isBiometricAvailable":self.isBiometricAvailable()
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

    private func isBiometricLocked() -> Bool {
        let error = getBiometricError()
        if (error?.code == LAError.Code.biometryLockout.rawValue) { return true; }
        return false;
    }

    private func getBiometricError() -> NSError? {
        var error : NSError?
        LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return error;
    }

}
