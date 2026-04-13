import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var apiKeyStatus: String = ""
    @Published var showAPIKeyView: Bool = false
    
    private let keychainManager: KeychainManager
    
    init(keychainManager: KeychainManager = KeychainManager.shared) {
        self.keychainManager = keychainManager
        checkAPIKeyStatus()
    }
    
    func checkAPIKeyStatus() {
        if let apiKey = keychainManager.getAPIKey() {
            // 只显示API密钥的前几位，保护隐私
            let maskedKey = String(apiKey.prefix(4)) + "..."
            apiKeyStatus = "API Key: \(maskedKey)"
        } else {
            apiKeyStatus = "No API Key"
        }
    }
    
    func deleteAPIKey() {
        do {
            try keychainManager.deleteAPIKey()
            checkAPIKeyStatus()
        } catch {
            print("Error deleting API key: \(error.localizedDescription)")
        }
    }
    
    func openAPIKeyInput() {
        showAPIKeyView = true
    }
}
