//
//  ContentView.swift
//  sextary
//
//  Created by z z on 2026/4/13.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var showAPIKeyView: Bool = false
    @State private var showSettingsView: Bool = false
    @State private var errorMessage: String = ""
    
    private var apiKey: String? {
        KeychainManager.shared.getAPIKey()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 消息列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            messageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                // 错误消息
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // 输入区域
                HStack {
                    TextField("Type a message...", text: $inputText)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 1))
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue)
                                .cornerRadius(20)
                        } else {
                            Image(systemName: "paperplane")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                    }
                    .disabled(isLoading || inputText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Sextary")
            .navigationBarItems(trailing: Button(action: { showSettingsView = true }) {
                Image(systemName: "gear")
            })
        }
        .sheet(isPresented: $showAPIKeyView) {
            EnterAPIKeyView { showAPIKeyView = false }
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .onAppear {
            // 检查是否有API密钥
            if apiKey == nil {
                showAPIKeyView = true
            }
            // 添加欢迎消息
            messages.append(ChatMessage(content: "Hello! I'm your AI assistant. How can I help you today?", isUser: false))
        }
    }
    
    private func messageBubble(message: ChatMessage) -> some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.leading, 40)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .padding(.trailing, 40)
                Spacer()
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty, let apiKey = apiKey else {
            if apiKey == nil {
                showAPIKeyView = true
            }
            return
        }
        
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
                let service = KimiAPIService(with: apiKey)
                let messagesForAPI = [
                    Message.system("You are a helpful AI assistant that responds to user queries in a friendly and informative manner."),
                    Message.user(messageText)
                ]
                let response = try await service.send(messagesForAPI)
                
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

#Preview {
    ContentView()
}
