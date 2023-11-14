import Foundation
import OktaStorage
import Capacitor
import OktaOidc

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(OktaPlugin)
public class OktaPlugin: CAPPlugin, OktaDelegate {

    private let implementation = Okta()

    @objc public func configure(_ call: CAPPluginCall) {
        implementation.oktaDelegate = self
        implementation.configureSDK(config: call.options as! [String : String]) { authState, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve();
            }
        }
    }

    @objc public func signIn(_ call: CAPPluginCall) {
        let params = call.getAny("params") ?? ["":""]
        implementation.signIn(vc: self.bridge?.viewController, params: params as! [AnyHashable : Any], promptLogin: call.getBool("promptLogin", false)) { authState, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve();
            }
        }
    }

    @objc public func register(_ call: CAPPluginCall) {
        call.options["prompt"] = "login";
        call.options["t"] = "register";
        implementation.signIn(vc: self.bridge?.viewController, params: call.options, promptLogin: true) { authState, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve();
            }
        }
    }

    @objc public func recoveryPassword(_ call: CAPPluginCall) {
        call.options["prompt"] = "login";
        call.options["t"] = "resetPassWidget";
        implementation.signIn(vc: self.bridge?.viewController, params: call.options, promptLogin: true) { authState, error in
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

    @objc public func enableBiometric(_ call: CAPPluginCall) {
        implementation.enableBiometric { result, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve(result);
            }
        }
    }

    @objc public func disableBiometric(_ call: CAPPluginCall) {
        implementation.disableBiometric { result, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve(result);
            }
        }
    }

    @objc public func resetBiometric(_ call: CAPPluginCall) {
        implementation.resetBiometric { result, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve(result);
            }
        }
    }

    @objc public func getBiometricStatus(_ call: CAPPluginCall) {
        implementation.getBiometricStatus { result, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve(result);
            }
        }
    }

    func onOktaAuthStateChange(authState: OktaOidcStateManager?) {
        self.notifyListeners("authState", data: OktaConverterHelper.convertAuthState(authStateManager: authState), retainUntilConsumed: true)
    }

    func onOktaError(error: String, message: String, code: String) {
        self.notifyListeners("error", data: OktaConverterHelper.convertError(error: error, message: message, code: code), retainUntilConsumed: true)
    }

}
