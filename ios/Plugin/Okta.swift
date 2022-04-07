import Foundation
import OktaOidc

@objc public class Okta: NSObject {

    var authStateDelegate: OktaAuthStateDelegate?

    private var authSession: OktaOidc? = nil
    private var authStateManager: OktaOidcStateManager? = nil

    @objc public func configureSDK(callback: @escaping ((_ authDetails: [String:Any]?,_ error: Error?) -> Void)) -> Void {
        guard let config = try? OktaOidcConfig.default(),
          let oktaAuth = try? OktaOidc(configuration: config) else {
            // Fatal error as the configuration isn't editable in this app.
            return callback(nil, NSError(domain: "com.okode.okta", code: 404, userInfo: [NSLocalizedDescriptionKey: "Error configuring SDK. Check config"]))
        }
        self.authSession = oktaAuth
        // Check for an existing session
        self.authStateManager = OktaOidcStateManager.readFromSecureStorage(for: config)
        callback(getAuthStateAsMap(), nil)
        self.notifyAuthStateChange()
    }

    @objc public func signInWithBrowser(vc: UIViewController?, callback: @escaping ((_ authDetails: [String:Any]?,_ error: Error?) -> Void)) {
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
            callback(self.getAuthStateAsMap(), nil)
            self.notifyAuthStateChange()
        })
    }

    @objc public func signOut(vc: UIViewController?, callback: @escaping ((_ authDetails: [String:Any]?, _ error: Error?) -> Void)) {
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
            callback(self.getAuthStateAsMap(), nil)
            self.notifyAuthStateChange()
        })
    }

    @objc public func getUser(_ callback: @escaping ([String: Any]?, Error?) -> Void) {
        guard let authStateManager = authStateManager else {
            return callback(nil, NSError(domain: "com.okode.okta", code: 412, userInfo: [NSLocalizedDescriptionKey: "No auth state manager initialized"]))
        }
        return authStateManager.getUser(callback)
    }

    @objc public func getAuthStateAsMap() -> [String:Any] {
        guard let authStateManager = authStateManager else {
            return [:]
        }
        let accessToken = !isTokenExpired(authStateManager.accessToken) ? authStateManager.accessToken : nil
        return [
            "isAuthorized": authStateManager.authState.isAuthorized,
            "accessToken": accessToken ?? NSNull(),
            "refreshToken": authStateManager.refreshToken ?? NSNull(),
            "idToken": authStateManager.idToken ?? NSNull()
        ]
    }

    @objc public func isTokenExpired(_ tokenString: String?) -> Bool {
      guard let accessToken = tokenString,
      let tokenInfo = OKTIDToken.init(idTokenString: accessToken) else {
        return false
      }

      return Date() > tokenInfo.expiresAt
    }

    private func notifyAuthStateChange() {
        self.authStateDelegate?.onOktaAuthStateChange(authState: getAuthStateAsMap())
    }

}
