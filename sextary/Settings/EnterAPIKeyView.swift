import SwiftUI

struct EnterAPIKeyView: View {
    @StateObject private var viewModel: APIKeyViewModel
    
    init(onSave: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: APIKeyViewModel(onSave: onSave))
    }
    
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
            
            TextField("API Key", text: $viewModel.apiKey)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                .padding(.horizontal, 40)
                .autocapitalization(.none)
                .keyboardType(.default)
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            if viewModel.showSuccess {
                Text("API key saved successfully!")
                    .foregroundColor(.green)
                    .font(.footnote)
            }
            
            Button(action: viewModel.saveAPIKey) {
                if viewModel.isSaving {
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
            .disabled(viewModel.isSaving || viewModel.apiKey.isEmpty)
        }
        .padding()
    }
}
