import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(OktaPlugin)
public class OktaPlugin: CAPPlugin {

    private let implementation = Okta()

    @objc public func configure(_ call: CAPPluginCall) {
        implementation.listener = self
        implementation.configureSDK(config: call.options as! [String : String])
        call.resolve()
    }

    @available(iOS 13.0.0, *)
    @objc public func signIn(_ call: CAPPluginCall) {
        let params = call.getAny("params") ?? ["":""]
        let urlParams = Helper.convertParams(params: params as! [AnyHashable : Any])
        implementation.signIn(vc: self.bridge!.viewController!, params: urlParams, promptLogin: call.getBool("promptLogin", false), callback: { result, error in
            if (error != nil) {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve(["token": result])
        })
    }

    @available(iOS 13.0.0, *)
    @objc public func register(_ call: CAPPluginCall) {
        let params = call.getAny("params") ?? ["":""]
        var urlParams = Helper.convertParams(params: params as! [AnyHashable : Any])
        urlParams["t"]="register"
        implementation.signIn(vc: self.bridge!.viewController!, params: urlParams, promptLogin: true, callback: { result, error in
            if (error != nil) {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve(["token": result])
        })
    }

    @available(iOS 13.0.0, *)
    @objc public func recoveryPassword(_ call: CAPPluginCall) {
        let params = call.getAny("params") ?? ["":""]
        var urlParams = Helper.convertParams(params: params as! [AnyHashable : Any])
        urlParams["t"] = "resetPassWidget";
        implementation.signIn(vc: self.bridge!.viewController!, params: urlParams, promptLogin: true, callback: { result, error in
            if (error != nil) {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve(["token": result])
        })
    }

    @objc public func signOut(_ call: CAPPluginCall) {
        implementation.signOut(vc: self.bridge?.viewController, signOutOfBrowser: call.getBool("signOutOfBrowser") ?? false, resetBiometric: call.getBool("resetBiometric") ?? false) { call.resolve() }
        }

    @available(iOS 13.0.0, *)
    @objc public func enableBiometric(_ call: CAPPluginCall) {
        implementation.enableBiometric {
            call.resolve(Helper.getBiometricStatus())
        }
    }

    @objc public func disableBiometric(_ call: CAPPluginCall) {
        implementation.disableBiometric()
        call.resolve(Helper.getBiometricStatus())
    }

    @objc public func resetBiometric(_ call: CAPPluginCall) {
        implementation.resetBiometric()
        call.resolve(Helper.getBiometricStatus())
    }

    @objc public func getBiometricStatus(_ call: CAPPluginCall) {
        call.resolve(Helper.getBiometricStatus())
    }

}
