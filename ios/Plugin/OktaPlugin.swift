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
        implementation.signIn(vc: self.bridge!.viewController!, params: params as! [String:String], signInInBrowser: call.getBool("signInInBrowser", false), document: call.getString("document"), callback: { result, error in
            if (error != nil) {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve(["token": result])
        })
    }

    @available(iOS 13.0.0, *)
    @objc public func register(_ call: CAPPluginCall) {
        var params = (call.getAny("params") ?? ["":""]) as! [String:String]
        params["t"]="register"
        implementation.signIn(vc: self.bridge!.viewController!, params: params , signInInBrowser: true, document: nil, callback: { result, error in
            if (error != nil) {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve(["token": result])
        })
    }

    @available(iOS 13.0.0, *)
    @objc public func recoveryPassword(_ call: CAPPluginCall) {
        var params = (call.getAny("params") ?? ["":""]) as! [String:String]
        params["t"] = "resetPassWidget";
        implementation.signIn(vc: self.bridge!.viewController!, params: params, signInInBrowser: true, document: nil, callback: { result, error in
            if (error != nil) {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve(["token": result])
        })
    }

    @objc public func signOut(_ call: CAPPluginCall) {
        implementation.signOut(vc: self.bridge?.viewController, signOutOfBrowser: call.getBool("signOutOfBrowser") ?? false, resetBiometric: call.getBool("resetBiometric") ?? false) { error in
            if error != nil {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve()
        }
    }

    @available(iOS 13.0.0, *)
    @objc public func enableBiometric(_ call: CAPPluginCall) {
        implementation.enableBiometric {
            call.resolve(self.implementation.getBiometricStatus())
        }
    }

    @objc public func disableBiometric(_ call: CAPPluginCall) {
        implementation.disableBiometric(deleteTokens: true)
        call.resolve(implementation.getBiometricStatus())
    }

    @objc public func resetBiometric(_ call: CAPPluginCall) {
        implementation.resetBiometric()
        call.resolve(implementation.getBiometricStatus())
    }

    @objc public func getBiometricStatus(_ call: CAPPluginCall) {
        call.resolve(implementation.getBiometricStatus())
    }

}
