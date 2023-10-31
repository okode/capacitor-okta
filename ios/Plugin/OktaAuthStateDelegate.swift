import OktaOidc
import OktaStorage

protocol OktaAuthStateDelegate {
    func onOktaAuthStateChange(authState: OktaOidcStateManager?)
}
