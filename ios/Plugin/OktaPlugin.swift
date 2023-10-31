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
        implementation.signIn(vc: self.bridge?.viewController, params: call.options, biometric: true) { authState, error in
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
        implementation.signIn(vc: self.bridge?.viewController, params: call.options, biometric: false) { authState, error in
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
        implementation.signIn(vc: self.bridge?.viewController, params: call.options, biometric: false) { authState, error in
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
                call.resolve();
            }
        }
    }

    @objc public func disabledBiometric(_ call: CAPPluginCall) {
        implementation.disabledBiometric { result, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve();
            }
        }
    }

    @objc public func restartBiometric(_ call: CAPPluginCall) {
        implementation.restartBiometric { result, error in
            if error != nil {
                call.reject(error!.localizedDescription, nil, error)
            } else {
                call.resolve();
            }
        }
    }

    func onOktaAuthStateChange(authState: OktaOidcStateManager?) {
        self.notifyListeners("authState", data: OktaConverterHelper.convertAuthState(authStateManager: authState), retainUntilConsumed: true)
    }

}
