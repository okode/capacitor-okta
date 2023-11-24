import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(OktaPlugin)
public class OktaPlugin: CAPPlugin {

    private let implementation = Okta()

    public func configure(_ call: CAPPluginCall) {
        implementation.configureSDK(config: call.options as! [String : String])
        call.resolve()
    }

    @available(iOS 13.0.0, *)
    public func signIn(_ call: CAPPluginCall) {
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
    public func register(_ call: CAPPluginCall) {
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
    public func recoveryPassword(_ call: CAPPluginCall) {
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

    public func signOut(_ call: CAPPluginCall) {
        implementation.signOut(vc: self.bridge?.viewController) { result, error in
                if error != nil {
                    call.reject(error!.localizedDescription, nil, error)
                } else {
                    call.resolve();
                }
            }
        }

    @available(iOS 13.0.0, *)
    public func enableBiometric(_ call: CAPPluginCall) {
        implementation.enableBiometric {
            call.resolve(Helper.getBiometricStatus())
        }
    }

    public func disableBiometric(_ call: CAPPluginCall) {
        implementation.disableBiometric()
        call.resolve(Helper.getBiometricStatus())
    }

    public func resetBiometric(_ call: CAPPluginCall) {
        implementation.resetBiometric()
        call.resolve(Helper.getBiometricStatus())
    }

    public func getBiometricStatus(_ call: CAPPluginCall) {
        call.resolve(Helper.getBiometricStatus())
    }

}
