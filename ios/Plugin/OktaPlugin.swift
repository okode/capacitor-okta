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
        implementation.configureSDK(config: call.options as! [String : String])
        call.resolve()
    }

    @objc public func signIn(_ call: CAPPluginCall) {
        let params = call.getAny("params") ?? ["":""]
        implementation.signIn(vc: self.bridge!.viewController!, params: params as! [AnyHashable : Any], promptLogin: call.getBool("promptLogin", false), callback: { result, error in
            if (error != nil) {
                call.reject(error?.localizedDescription ?? "")
            }
            call.resolve(["token": result])

        })
    }



}
