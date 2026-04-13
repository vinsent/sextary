import SwiftUI

struct SettingsView: View {
    @State private var showAPIKeyView: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var isDeleting: Bool = false
    @State private var deleteSuccess: Bool = false
    
    private var apiKeyExists: Bool {
        KeychainManager.shared.getAPIKey() != nil
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("API Key")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        if apiKeyExists {
                            Text("Configured")
                                .foregroundColor(.green)
                        } else {
                            Text("Not Configured")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: { showAPIKeyView = true }) {
                        HStack {
                            Text("Enter API Key")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if apiKeyExists {
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
            .sheet(isPresented: $showAPIKeyView) {
                EnterAPIKeyView { showAPIKeyView = false }
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
        isDeleting = true
        
        Task {
            do {
                try KeychainManager.shared.deleteAPIKey()
                deleteSuccess = true
            } catch {
                print("Error deleting API key: \(error.localizedDescription)")
            }
            isDeleting = false
        }
    }
}
