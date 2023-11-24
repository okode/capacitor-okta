import Foundation
import LocalAuthentication
import WebAuthenticationUI
import Capacitor
import Security

@objc public class Okta: NSObject {

    var listener: CAPPlugin?

    var issuer: URL?
    var redirectUri: URL?
    var logoutRedirectUri: URL?
    var clientId = ""
    var scopes = ""

    @objc public func configureSDK(config: [String : String]) -> Void {
        issuer = URL.init(string: config["uri"] ?? "")
        redirectUri = URL.init(string: config["redirectUri"] ?? "")
        logoutRedirectUri = URL.init(string: config["endSessionUri"] ?? "")
        scopes = config["scopes"] ?? ""
        clientId = config["clientId"] ?? ""
        Storage.setClientId(clientId: clientId)
    }

    @available(iOS 13.0.0, *)
    @objc public func signIn(vc: UIViewController, params: [String:String], promptLogin: Bool, callback: @escaping((_ result: String?, _ error: Error?) -> Void)) {

        Task {
            let token = Storage.getTokens()
            if (!promptLogin && token != nil && isBiometricEnabled() == true) {
                do {
                    let token = try await signInWithRefresh()
                    callback(token?.accessToken, nil)
                } catch _ {
                    signIn(vc: vc, params: params, promptLogin: true, callback: callback)
                }
                return
            }

            if (!promptLogin && !isBiometricEnabled() && token?.isValid == true) {
                callback(token?.accessToken, nil)
                return
            }

            do {
                let t = try await signInWithBrowser(vc: vc, params: params, promptLogin: promptLogin)
                callback(t?.accessToken, nil)
            } catch let error {
                callback(nil, error)
            }
        }
    }

    @objc public func signOut(vc: UIViewController?, signOutOfBrowser: Bool, resetBiometric: Bool, callback: @escaping ((_ error: Error?) -> Void)) {
        Task {
            let token = Storage.getTokens()
            if (token == nil) { callback(nil) }
            Storage.deleteToken()
            if (resetBiometric) { Storage.deleteBiometric() }
            if (!signOutOfBrowser) { callback(nil); return }
            do {
                try await getWebAuth()?.signOut(from: vc?.view.window, token: token!)
            } catch let error {
                callback(error)
            }
        }
    }

    @available(iOS 13.0.0, *)
    @objc public func enableBiometric(callback: @escaping (() -> Void)) {
        if (!Biometric.isAvailable()) { callback(); return }
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

    @objc public func getBiometricStatus() -> [String:Bool]  {
        return Helper.getBiometricStatus(isBiometricAvailable: Biometric.isAvailable(), isBiometricEnabled: Storage.getBiometric() == true)
    }

    @available(iOS 13.0.0, *)
    private func signInWithBrowser(vc: UIViewController, params: [AnyHashable : Any], promptLogin: Bool) async throws -> Token? {
        var options: [WebAuthentication.Option]? = []
        if (promptLogin) { options?.append(.prompt(.login)) }
        let token = try await getWebAuth()?.signIn(from: vc.view.window, options: options)
        let isBiometricAvailable = Biometric.isAvailable()
        if (isBiometricEnabled() && !isBiometricAvailable && Biometric.errorCode != LAError.Code.biometryLockout.rawValue) {
            showBiometricWarning(vc: vc)
            disableBiometric()
        }
        if (!isBiometricConfigured() && Biometric.isAvailable()) { showBiometricDialog(vc: vc) }
        Storage.setTokens(token: token)
        return token
    }

    @available(iOS 13.0.0, *)
    private func signInWithRefresh() async throws -> Token? {
        var token = Storage.getTokens()
        if (token == nil || token?.refreshToken == nil) {
            notifyError(error: "REFRESH_ERROR", message: "refreshToken not available", code: "");
            throw NSError()
        }
        guard let client = WebAuthentication.shared?.signInFlow.client else {
            notifyError(error: "REFRESH_ERROR", message: "client not available", code: "");
            throw NSError()
        }
        let identityVerified = await Biometric.verifyIdentity()
        if (!identityVerified) {
            notifyError(error: "BIOMETRIC_ERROR", message: Biometric.error?.localizedDescription ?? "", code: String(Biometric.errorCode ?? 0))
            throw NSError()
        }
        do {
            token = try await Token.from(refreshToken: token?.refreshToken ?? "", using: client)
        } catch let error {
            notifyError(error: "REFRESH_ERROR", message: error.localizedDescription, code: "")
            throw NSError()
        }
        Storage.setTokens(token: token)
        return token
    }

    private func isBiometricEnabled() -> Bool {
        return Storage.getBiometric() == true
    }

    private func isBiometricConfigured() -> Bool {
        return Storage.getBiometric() != nil
    }

    private func notifyError(error: String, message: String, code: String) {
        listener?.notifyListeners("error", data: Helper.convertError(error: error, message: message, code: code), retainUntilConsumed: true)
    }

    private func getWebAuth() -> WebAuthentication? {
        if (issuer == nil || redirectUri == nil) { return nil }
        return WebAuthentication(issuer: issuer!, clientId: clientId , scopes: scopes, redirectUri: redirectUri!, logoutRedirectUri: logoutRedirectUri)
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
        DispatchQueue.main.async {
            vc?.present(alert, animated: true, completion: nil)
        }
    }

    private func showBiometricWarning(vc: UIViewController?) {
        let alert = UIAlertController(title: "El acceso biométrico se ha deshabilitado", message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        DispatchQueue.main.async {
            vc?.present(alert, animated: true, completion: nil)
        }
    }

}
