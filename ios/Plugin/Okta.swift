import Foundation
import OktaOidc

@objc public class Okta: NSObject {

    var authStateDelegate: OktaAuthStateDelegate?

    private var authSession: OktaOidc? = nil
    private var authStateManager: OktaOidcStateManager? = nil

    @objc public func configureSDK(callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) -> Void {
        guard let config = try? OktaOidcConfig.default(),
          let oktaAuth = try? OktaOidc(configuration: config) else {
            // Fatal error as the configuration isn't editable in this app.
            return callback(nil, NSError(domain: "com.okode.okta", code: 404, userInfo: [NSLocalizedDescriptionKey: "Error configuring SDK. Check config"]))
        }
        self.authSession = oktaAuth
        // Check for an existing session
        self.authStateManager = OktaOidcStateManager.readFromSecureStorage(for: config)
        callback(self.authStateManager, nil)
        self.notifyAuthStateChange()
    }

    @objc public func signInWithBrowser(vc: UIViewController?, callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {
        guard let vc = vc else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 400, userInfo: [NSLocalizedDescriptionKey: "Not a valid view controller provided"]))
        }

        guard let authSession = self.authSession else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth session initialized"]))
        }

        authSession.signInWithBrowser(from: vc, callback: { authStateManager, error in
            if error != nil {
                return callback(nil, error)
            }
            self.authStateManager = authStateManager
            authStateManager?.writeToSecureStorage()
            callback(self.authStateManager, nil)
            self.notifyAuthStateChange()
        })
    }

    @objc public func refreshToken(vc: UIViewController?, callback: @escaping ((_ authState: OktaOidcStateManager?,_ error: Error?) -> Void)) {
        self.authStateManager?.renew { authStateManager, error in
            if let error = error {
                return callback(nil, error)
            }
            self.authStateManager = authStateManager
            authStateManager?.writeToSecureStorage()
            callback(self.authStateManager, nil)
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
            // NOP
        }, completionHandler: { success, opts in
            if (!success) {
                return callback(nil, NSError(domain: "com.okode.okta", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error signing out"]))
            }
            self.authStateManager = nil;
            callback(NSNumber(value: opts.rawValue), nil)
            self.notifyAuthStateChange()
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

    @objc public static func isTokenExpired(_ tokenString: String?) -> Bool {
      guard let token = tokenString,
      let tokenInfo = OKTIDToken.init(idTokenString: token) else {
        return false
      }

      return Date() > tokenInfo.expiresAt
    }

    private func notifyAuthStateChange() {
        self.authStateDelegate?.onOktaAuthStateChange(authState: getAuthState())
    }

}
