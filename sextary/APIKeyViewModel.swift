import Foundation
import Combine

class APIKeyViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccess: Bool = false
    
    private let keychainManager: KeychainManager
    private let onSave: () -> Void
    
    init(keychainManager: KeychainManager = KeychainManager.shared, onSave: @escaping () -> Void) {
        self.keychainManager = keychainManager
        self.onSave = onSave
        loadSavedAPIKey()
    }
    
    func loadSavedAPIKey() {
        if let savedAPIKey = keychainManager.getAPIKey() {
            apiKey = savedAPIKey
        }
    }
    
    func saveAPIKey() {
        isSaving = true
        errorMessage = ""
        showSuccess = false
        
        Task {
            do {
                try keychainManager.saveAPIKey(apiKey)
                showSuccess = true
                // 延迟一秒后调用回调
                try await Task.sleep(nanoseconds: 1_000_000_000)
                onSave()
            } catch {
                errorMessage = "Failed to save API key: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}
