import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteSuccess: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("API Key")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(viewModel.apiKeyStatus)
                            .foregroundColor(viewModel.apiKeyStatus.contains("No") ? .red : .green)
                    }
                    
                    Button(action: viewModel.openAPIKeyInput) {
                        HStack {
                            Text("Enter API Key")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if !viewModel.apiKeyStatus.contains("No") {
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Text("Delete API Key")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showAPIKeyView) {
                EnterAPIKeyView { 
                    viewModel.showAPIKeyView = false
                    viewModel.checkAPIKeyStatus()
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete API Key"),
                    message: Text("Are you sure you want to delete your API key? You will need to re-enter it to use the service."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteAPIKey()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $deleteSuccess) {
                Alert(
                    title: Text("Success"),
                    message: Text("API key deleted successfully."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func deleteAPIKey() {
        viewModel.deleteAPIKey()
        deleteSuccess = true
    }
}
