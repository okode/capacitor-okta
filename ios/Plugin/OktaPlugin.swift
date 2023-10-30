import Foundation
import OktaStorage
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
        }
    }

    @objc public func signIn(_ call: CAPPluginCall) {
        implementation.signIn(vc: self.bridge?.viewController, params: call.getAny("params") as! [AnyHashable : Any], biometric: call.getBool("biometric", false)) { authState, error in
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
                call.resolve();
            }
        }
    }

    @objc public func getUser(_ call: CAPPluginCall) {
        implementation.getUser { userData, error in
            call.resolve(userData ?? [:])
        }
    }

    func onOktaAuthStateChange(authState: OktaOidcStateManager?, secureStorage: OktaSecureStorage?) {
        self.notifyListeners("authState", data: OktaConverterHelper.convertAuthState(authStateManager: authState, secureStorage: secureStorage), retainUntilConsumed: true)
    }

}
