import OktaOidc

protocol OktaDelegate {
    func onOktaAuthStateChange(authState: OktaOidcStateManager?)
    func onOktaError(error: String, message: String, code: String)
}
