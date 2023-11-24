import Foundation
import AuthFoundation

@objc public class Storage: NSObject {

    static let SERVICE_NAME = "com.okode.okta.keychain.storage"
    static let TOKENS_KEY = "okta_tokens_storage"
    static let BIOMETRIC_KEY = "okta_biometric_storage"

    static var clientId = ""

    public static func setClientId(clientId: String) {
        self.clientId = clientId
    }

    /* Tokens */
    public static func setTokens(token: Token?) {
        deleteToken()
        do {
            let data = try JSONEncoder().encode(token)
            Storage.save(key: Storage.TOKENS_KEY + clientId, data: data)
        } catch _ { }
    }

    public static func getTokens() -> Token? {
        do {
            let data = Storage.get(key: Storage.TOKENS_KEY + clientId)
            if (data == nil) { return nil }
            return try JSONDecoder().decode(Token.self, from: data!) as Token
        } catch _ {
            return nil
        }
    }

    public static func deleteToken() {
        delete(key: Storage.TOKENS_KEY + clientId)
    }

    /* Biometric */
    public static func setBiometric(value: Bool) {
        deleteBiometric()
        do {
            let data = try JSONEncoder().encode(value)
            Storage.save(key: Storage.BIOMETRIC_KEY + clientId, data: data)
        } catch _ { }
    }

    public static func getBiometric() -> Bool? {
        do {
            let data = Storage.get(key: Storage.BIOMETRIC_KEY + clientId)
            if (data == nil) { return nil }
            return try JSONDecoder().decode(Bool.self, from: data!) as Bool
        } catch _ {
            return nil
        }
    }

    public static func deleteBiometric() {
        delete(key: Storage.BIOMETRIC_KEY + clientId)
    }

    private static func save(key: String, data: Data) {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrService as String: Storage.SERVICE_NAME,
            kSecValueData as String: data
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func get(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrService as String: Storage.SERVICE_NAME,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
            let existingItem = item as? [String: Any]
            if (existingItem == nil) { return nil }
            return existingItem?[kSecValueData as String] as? Data
        } else {
            return nil
        }
    }

    private static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Storage.SERVICE_NAME
        ]
        SecItemDelete(query as CFDictionary)
    }

}
