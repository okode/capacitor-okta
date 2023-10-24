import Foundation
import OktaOidc
import Capacitor
import OktaStorage

@objc public class Okta: NSObject {

    private static let KEYCHAIN_GROUP_NAME = "secureshare"

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

        var hasDataStored: String? = nil

        do {
            try hasDataStored = secureStorage.get(key: "okta_user_biometric", accessGroup: self.getAccessGroup())
        } catch _ {  }

        if (hasDataStored != nil && urlParams["prompt"] != "login") {
            refreshToken { authState, error in
                if error != nil {
                    do {
                        try secureStorage.delete(key: "okta_user", accessGroup: self.getAccessGroup())
                        try secureStorage.delete(key: "okta_user_biometric", accessGroup: self.getAccessGroup())
                    } catch _ {  }
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
                do {
                    try secureStorage.delete(key: "okta_user", accessGroup: self.getAccessGroup())
                } catch let error {
                    return callback(nil, error)
                }
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
                let authStateData = try secureStorage.getData(key: "okta_user", accessGroup: self.getAccessGroup())
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

    private func notifyAuthStateChange() {
        self.authStateDelegate?.onOktaAuthStateChange(authState: getAuthState())
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
            let authStateData = try? NSKeyedArchiver.archivedData(withRootObject: authStateManager, requiringSecureCoding: false)
            guard let authStateData = authStateData else {
                return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth data initialized"]))
            }

            do {
                try secureStorage.set(data: authStateData,
                                      forKey: "okta_user",
                                      behindBiometrics: secureStorage.isTouchIDSupported() || secureStorage.isFaceIDSupported(), accessGroup: self.getAccessGroup())
                try secureStorage.set("true", forKey: "okta_user_biometric", behindBiometrics: false, accessGroup: self.getAccessGroup())
            } catch _ { }
            self.authStateManager = authStateManager
            authStateManager?.writeToSecureStorage()
            callback(self.authStateManager, nil)
        })
    }

    private func getAccessGroup() -> String {
        let appIdentifierPrefix = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String ?? ""
        return "\(appIdentifierPrefix)\(Okta.KEYCHAIN_GROUP_NAME)"
    }

}
