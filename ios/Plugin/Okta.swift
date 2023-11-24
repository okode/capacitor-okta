import Foundation
import LocalAuthentication
import WebAuthenticationUI
import Capacitor
import Security

@objc public class Okta: NSObject {

    @objc public func configureSDK(config: [String : String]) -> Void {
        let issuer = URL.init(string: config["uri"]!)
        let redirectUri = URL.init(string: config["redirectUri"]!)
        WebAuthentication(issuer: issuer!, clientId: config["clientId"]!, scopes: config["scopes"]!, redirectUri: redirectUri!)
    }

    @available(iOS 13.0.0, *)
    @objc public func signIn(vc: UIViewController, params: [String:String], promptLogin: Bool, callback: @escaping((_ result: String?, _ error: Error?) -> Void)) {

        Task {
            let biometric = Storage.getBiometric()
            if (!promptLogin && biometric == true) {
                do {
                    let token = try await signInWithRefresh()
                    callback(token?.accessToken, nil)
                } catch _ {
                    signIn(vc: vc, params: params, promptLogin: true, callback: callback)
                }
                return
            }
            
            let token = Storage.getTokens()
            if (!promptLogin && biometric != true && token?.isValid == true) {
                callback(token?.accessToken, nil)
                return
            }

            do {
                let tokens = try await signInWithBrowser(vc: vc, params: params, promptLogin: promptLogin)
                callback(token?.accessToken, nil)
            } catch let error {
                callback(nil, error)
            }
        }
    }

    @objc public func signOut(vc: UIViewController?, callback: @escaping ((_ result: NSNumber?, _ error: Error?) -> Void)) {

        }

    @available(iOS 13.0.0, *)
    @objc public func enableBiometric(callback: @escaping (() -> Void)) {
        Task {
            let verified = await Biometric.verifyIdentity()
            if (verified) { Storage.setBiometric(value: true) }
            callback()
        }
    }

    @objc public func disableBiometric() {
        Storage.setBiometric(value: false)
    }

    @objc public func resetBiometric() {
        Storage.deleteBiometric()
    }

    private func notifyError(error: String, message: String, code: String) {
    }

    @available(iOS 13.0.0, *)
    private func showBiometricDialog(vc: UIViewController?) {
            let alert = UIAlertController(title: "Acceso biométrico", message: "¿Quieres utilizar el biométrico para futuros accesos?", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: { (action: UIAlertAction!) in
            self.enableBiometric() { }
        }))

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (action: UIAlertAction!) in
            self.disableBiometric()
        }))

        vc?.present(alert, animated: true, completion: nil)
    }

    @available(iOS 13.0.0, *)
    private func signInWithBrowser(vc: UIViewController, params: [AnyHashable : Any], promptLogin: Bool) async throws -> Token? {
        var options: [WebAuthentication.Option]? = []
        if (promptLogin) { options?.append(.prompt(.login)) }
        let token = try await WebAuthentication.shared?.signIn(from: vc.view.window, options: options)
        if (Storage.getBiometric() == nil && Biometric.isAvailable()) { showBiometricDialog(vc: vc) }
        Storage.setTokens(token: token)
        return token
    }

    @available(iOS 13.0.0, *)
    private func signInWithRefresh() async throws -> Token? {
        let identityVerified = await Biometric.verifyIdentity()
        if (!identityVerified) { throw NSError() }
        guard let client = WebAuthentication.shared?.signInFlow.client else { throw NSError() }
        var token = Storage.getTokens()
        if (token == nil || token?.refreshToken == nil) { throw NSError() }
        try token = await Token.from(refreshToken: token!.refreshToken!, using: client)
        Storage.setTokens(token: token)
        return token
    }

}
