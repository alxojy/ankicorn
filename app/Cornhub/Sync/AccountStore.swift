import Foundation
import Security

/// Keeps the AnkiWeb hkey in the Keychain. Only the hkey is stored, never the password; the username is
/// kept in UserDefaults for display.
struct AccountStore {
    private let service = "com.alxojy.cornhub.ankiweb"
    private let usernameKey = "ankiweb.username"

    var username: String? { UserDefaults.standard.string(forKey: usernameKey) }

    var hkey: String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(hkey: String, username: String) {
        clear()
        var item = baseQuery
        item[kSecValueData as String] = Data(hkey.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(item as CFDictionary, nil)
        UserDefaults.standard.set(username, forKey: usernameKey)
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
        UserDefaults.standard.removeObject(forKey: usernameKey)
    }

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
            kSecAttrAccount as String: "hkey"]
    }
}
