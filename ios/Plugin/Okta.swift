import Foundation
import LocalAuthentication
import WebAuthenticationUI
import Capacitor

@objc public class Okta: NSObject {

    let auth = WebAuthentication.shared

    @objc public func configureSDK(config: [String : String]) -> Void {
        let issuer = URL.init(string: config["uri"]!)
        let redirectUri = URL.init(string: config["redirectUri"]!)
        WebAuthentication(issuer: issuer!, clientId: config["clientId"]!, scopes: config["scopes"]!, redirectUri: redirectUri!)
    }

    @objc public func signIn(vc: UIViewController, params: [AnyHashable : Any], promptLogin: Bool, callback: @escaping((_ result: String?, _ error: Error?) -> Void)) {

        Task {
            let credential = getCredential()
            if (credential != nil && credential?.token.isValid ?? false) {
                callback(credential?.token.accessToken, nil)
                return
            }

            do {
                let token = try await auth?.signIn(from: vc.view.window)
                storeToken(token: token)
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
        do {
            return try Credential.find(where: { $0.tags["tag"] == "t2" }).first
        } catch let error {
            return nil
        }
    }

    private func signInWithBrowser(vc: UIViewController, params: [AnyHashable : Any], promptLogin: Bool) async throws -> Token? {
        var options: [WebAuthentication.Option]? = []
        let token = try await auth?.signIn(from: vc.view.window, options: options)
        try Credential.store(token!)
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
            let credential = try Credential.store(token!, tags: ["tag": "t2"])
        } catch let error {
            print("STORE ERROR", error)
        }
    }

}
