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
            // Only show the first few digits of the API key to protect privacy
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
