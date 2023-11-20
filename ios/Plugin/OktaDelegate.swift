
protocol OktaDelegate {
    func onOktaAuthStateChange(authState: Any)
    func onOktaError(error: String, message: String, code: String)
}
