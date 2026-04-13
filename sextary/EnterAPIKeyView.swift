import SwiftUI

struct EnterAPIKeyView: View {
    @State private var apiKey: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Kimi API Key")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Please enter your Kimi API key to use the service.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            TextField("API Key", text: $apiKey)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                .padding(.horizontal, 40)
                .autocapitalization(.none)
                .keyboardType(.default)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            if showSuccess {
                Text("API key saved successfully!")
                    .foregroundColor(.green)
                    .font(.footnote)
            }
            
            Button(action: saveAPIKey) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                } else {
                    Text("Save API Key")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }
            }
            .disabled(isSaving || apiKey.isEmpty)
        }
        .padding()
        .onAppear {
            // 尝试加载已保存的API密钥
            if let savedAPIKey = KeychainManager.shared.getAPIKey() {
                apiKey = savedAPIKey
            }
        }
    }
    
    private func saveAPIKey() {
        isSaving = true
        errorMessage = ""
        showSuccess = false
        
        Task {
            do {
                try KeychainManager.shared.saveAPIKey(apiKey)
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
