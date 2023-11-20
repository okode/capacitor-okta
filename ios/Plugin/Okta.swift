import Foundation
import LocalAuthentication
import WebAuthenticationUI
import Capacitor

@objc public class Okta: NSObject {

    var webAuthentication: WebAuthentication?

    @objc public func configureSDK(config: [String : String]) -> Void {
        let issuer = URL.init(string: config["uri"]!)
        let redirectUri = URL.init(string: config["redirectUri"]!)
        webAuthentication = WebAuthentication(issuer: issuer!, clientId: config["clientId"]!, scopes: config["scopes"]!, redirectUri: redirectUri!)
        }

    @objc public func signIn(vc: UIViewController, params: [AnyHashable : Any], promptLogin: Bool, callback: @escaping((_ result: String?, _ error: Error?) -> Void)) {

        let credential = getCredential()
        if (!promptLogin && credential != nil && credential!.token.isValid) {
            Task {
                do {
                    try await refreshToken()
                    callback(getCredential()?.token.accessToken, nil)
                } catch _ {
                    signIn(vc: vc, params: params, promptLogin: true, callback: callback)
                }
            }
            return
        }

        Task {
            do {
                let token = try await signInWithBrowser(vc: vc, params: params, promptLogin: promptLogin)
                callback(token?.accessToken, nil)
            } catch let error {
                callback(nil, error)
            }
        }
    }

    @objc public func signOut(vc: UIViewController?, callback: @escaping ((_ result: NSNumber?, _ error: Error?) -> Void)) {

        }

    @objc public func enableBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {


    }

    @objc public func disableBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {

    }

    @objc public func resetBiometric(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {

    }

    @objc public func getBiometricStatus(callback: @escaping (([String:Bool], _ error: Error?) -> Void)) {
    }

    private func notifyError(error: String, message: String, code: String) {
    }

    private func showBiometricDialog(vc: UIViewController?) {
            let alert = UIAlertController(title: "Acceso biométrico", message: "¿Quieres utilizar el biométrico para futuros accesos?", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: { (action: UIAlertAction!) in
                self.enableBiometric { success, error in }
        }))

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (action: UIAlertAction!) in
                self.disableBiometric { success, error in }
        }))

        vc?.present(alert, animated: true, completion: nil)
    }

    private func getCredential() -> Credential? {
        if let credential = Credential.default {
            return credential
        }
        return nil
    }

    private func signInWithBrowser(vc: UIViewController, params: [AnyHashable : Any], promptLogin: Bool) async throws -> Token? {
        var options: [WebAuthentication.Option]? = []
        if (promptLogin) { options?.append(.prompt(.login)) }

        /*
        params.compactMap { (key: AnyHashable, value: Any) in
            options?.append(.custom(key: key as! String, value: value as! String))
        }
        */

        let token = try await webAuthentication?.signIn(from: vc.view.window, options: options)
        storeToken(token: token)
        return token
    }

    private func refreshToken() async throws {
        let identityVerified = await verifyIdentity()
        if (!identityVerified) { throw NSError(); }
        let credential = getCredential()
        if (credential != nil) {
            try await credential?.refreshIfNeeded()
        }
    }

    private func verifyIdentity() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                           localizedReason: "Acceso biométrico") { success, authenticationError in
                    continuation.resume(returning: success)
                }
            }
        }
    }

    private func storeToken(token: Token?) {
        if (token == nil) { return }
        do {
            try Credential.store(token!)
        } catch let error {
            print(error)
        }
    }

}
