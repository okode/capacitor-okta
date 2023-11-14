import OktaOidc
import OktaStorage

protocol OktaDelegate {
    func onOktaAuthStateChange(authState: OktaOidcStateManager?)
    func onOktaError(error: String, message: String, code: String)
}
