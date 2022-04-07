import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(OktaPlugin)
public class OktaPlugin: CAPPlugin, OktaAuthStateDelegate {
    
    private let implementation = Okta()
    
    override public func load() {
        super.load()
        implementation.authStateDelegate = self
        implementation.configureSDK { authDetails, error in
            if error != nil {
                return self.notifyListeners("initError", data: [
                    "description": error?.localizedDescription ?? NSNull(),
                ], retainUntilConsumed: true)
            }
            self.notifyListeners("initSuccess", data: authDetails, retainUntilConsumed: true)
        }
    }
    
    @objc public func signInWithBrowser(_ call: CAPPluginCall) {
        implementation.signInWithBrowser(vc: self.bridge?.viewController) { authDetails, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve(authDetails ?? [:]);
            }
        }
    }
    
    @objc public func signOut(_ call: CAPPluginCall) {
        implementation.signOut(vc: self.bridge?.viewController) { authDetails, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve(authDetails ?? [:]);
            }
        }
    }

    @objc public func getUser(_ call: CAPPluginCall) {
        implementation.getUser { userData, error in
            call.resolve(userData ?? [:])
        }
    }

    @objc public func getAuthStateDetails(_ call: CAPPluginCall) {
        call.resolve(implementation.getAuthStateAsMap())
    }
    
    func onOktaAuthStateChange(authState: [String : Any]) {
        self.notifyListeners("authState", data: implementation.getAuthStateAsMap(), retainUntilConsumed: true)
    }
    
}
