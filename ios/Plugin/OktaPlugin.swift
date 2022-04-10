import Foundation
import Capacitor
import OktaOidc

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
        implementation.configureSDK { authState, error in
            if error != nil {
                return self.notifyListeners("initError", data: [
                    "description": error?.localizedDescription ?? NSNull(),
                ], retainUntilConsumed: true)
            }
            self.notifyListeners("initSuccess", data: OktaConverterHelper.convertAuthState(authStateManager: authState), retainUntilConsumed: true)
        }
    }

    @objc public func signInWithBrowser(_ call: CAPPluginCall) {
        implementation.signInWithBrowser(vc: self.bridge?.viewController) { authState, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve();
            }
        }
    }

    @objc public func signOut(_ call: CAPPluginCall) {
        implementation.signOut(vc: self.bridge?.viewController) { result, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve([ "value": result ?? NSNull() ]);
            }
        }
    }

    @objc public func getUser(_ call: CAPPluginCall) {
        implementation.getUser { userData, error in
            call.resolve(userData ?? [:])
        }
    }

    @objc public func getAuthStateDetails(_ call: CAPPluginCall) {
        let state = implementation.getAuthState()
        call.resolve(OktaConverterHelper.convertAuthState(authStateManager: state))
    }

    func onOktaAuthStateChange(authState: OktaOidcStateManager?) {
        self.notifyListeners("authState", data: OktaConverterHelper.convertAuthState(authStateManager: authState), retainUntilConsumed: true)
    }

}
