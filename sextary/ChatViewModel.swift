import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var apiKey: String? = nil
    private var apiService: KimiAPIService? = nil
    
    init() {
        initializeMessages()
    }
    
    func configApiKey(_ key: String) {
        self.apiKey = key
        self.apiService = KimiAPIService(with: key)
    }
    
    private func initializeMessages() {
        messages.append(ChatMessage(content: "Hello! I'm your AI assistant. How can I help you today?", isUser: false))
    }
    
    func sendMessage() {
        guard !inputText.isEmpty, let apiService = apiService else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        
        // 清空输入框
        let messageText = inputText
        inputText = ""
        
        // 显示加载状态
        isLoading = true
        errorMessage = ""
        
        // 发送消息到Kimi API
        Task {
            do {
                let messagesForAPI = [
                    Message.system("You are a helpful AI assistant that responds to user queries in a friendly and informative manner."),
                    Message.user(messageText)
                ]
                let response = try await apiService.send(messagesForAPI)
                
                if let assistantMessage = response.choices?.first?.message.content {
                    // 添加助手消息
                    let assistantChatMessage = ChatMessage(content: assistantMessage, isUser: false)
                    messages.append(assistantChatMessage)
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
