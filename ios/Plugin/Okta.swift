import Foundation
import OktaOidc
import Capacitor
import OktaStorage

@objc public class Okta: NSObject {

    private static let KEYCHAIN_GROUP_KEY = "secureshare"
    private static let KEYCHAIN_DATA_KEY = "okta_user"
    private static let KEYCHAIN_BEHIND_BIOMETRIC_KEY = "okta_user_biometric"

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
    }

    @objc public func signIn(vc: UIViewController?, params: [AnyHashable : Any], callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {

        guard let secureStorage = self.secureStorage else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No secure storage initialized"]))
        }

        var urlParams = Dictionary(uniqueKeysWithValues: params.compactMap { (key: AnyHashable, value: Any) in
            return (key as! String, value as! String)
        })

        if (self.hasSecureStoredData(secureStorage: secureStorage) && urlParams["prompt"] != "login") {
            refreshToken { authState, error in
                if error != nil {
                    self.clearSecureStorage(secureStorage: secureStorage)
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
                callback(authState, nil)
                self.notifyAuthStateChange()
            }
            return
        }

        urlParams["prompt"] = "login"

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

            guard let secureStorage = self.secureStorage else {
                return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No secure storage initialized"]))
            }

            authSession.signOut(authStateManager: authStateManager, from: vc, progressHandler: { options in
            }, completionHandler: { success, opts in
                if (!success) {
                    return callback(nil, NSError(domain: "com.okode.okta", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error signing out"]))
                }
                self.clearSecureStorage(secureStorage: secureStorage)
                self.authStateManager = nil;
                callback(NSNumber(value: opts.rawValue), nil)
            })
        }

    @objc public func getUser(_ callback: @escaping ([String: Any]?, Error?) -> Void) {
        guard let authStateManager = authStateManager else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth state manager initialized"]))
        }
        return authStateManager.getUser(callback)
    }

    @objc public func getAuthState() ->  OktaOidcStateManager? {
        return authStateManager;
    }

    private func refreshToken(callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {

        guard let secureStorage = self.secureStorage else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No secure storage initialized"]))
        }

        DispatchQueue.global().async {
            do {
                let authStateData = try secureStorage.getData(key: Okta.KEYCHAIN_DATA_KEY, accessGroup: self.getAccessGroup())
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

            self.writeToSecureStorage(secureStorage: secureStorage, authStateManager: authStateManager)
            self.authStateManager = authStateManager
            authStateManager?.writeToSecureStorage()
            callback(self.authStateManager, nil)
        })
    }

    private func notifyAuthStateChange() {
        self.authStateDelegate?.onOktaAuthStateChange(authState: getAuthState())
    }

    private func getAccessGroup() -> String {
        let appIdentifierPrefix = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String ?? ""
        return "\(appIdentifierPrefix)\(Okta.KEYCHAIN_GROUP_KEY)"
    }

    private func clearSecureStorage(secureStorage: OktaSecureStorage) {
        do {
            try secureStorage.delete(key: Okta.KEYCHAIN_DATA_KEY, accessGroup: self.getAccessGroup())
            try secureStorage.delete(key: Okta.KEYCHAIN_BEHIND_BIOMETRIC_KEY, accessGroup: self.getAccessGroup())
        } catch _ { }
    }

    private func writeToSecureStorage(secureStorage: OktaSecureStorage, authStateManager: OktaOidcStateManager?) {
        let authStateData = try? NSKeyedArchiver.archivedData(withRootObject: authStateManager, requiringSecureCoding: false)
        guard let authStateData = authStateData else {
            return
        }

        do {
            try secureStorage.set(data: authStateData,
                                  forKey: Okta.KEYCHAIN_DATA_KEY,
                                  behindBiometrics: secureStorage.isTouchIDSupported() || secureStorage.isFaceIDSupported(), accessGroup: self.getAccessGroup())
            try secureStorage.set("true", forKey: Okta.KEYCHAIN_BEHIND_BIOMETRIC_KEY, behindBiometrics: false, accessGroup: self.getAccessGroup())
        } catch _ { }
    }

    private func hasSecureStoredData(secureStorage: OktaSecureStorage) -> Bool {
        do {
            let hasStoredData = try secureStorage.get(key: Okta.KEYCHAIN_BEHIND_BIOMETRIC_KEY, accessGroup: self.getAccessGroup())
            return true
        } catch _ {
            return false
        }
    }

}
