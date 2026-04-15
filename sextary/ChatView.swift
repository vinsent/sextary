//
//  ChatView.swift
//  sextary
//
//  Created by z z on 2026/4/13
//

import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content && lhs.isUser == rhs.isUser
    }
}

struct ChatView: View {
    @State private var showAPIKeyView: Bool = false
    @State private var showSettingsView: Bool = false
    @StateObject private var viewModel: ChatViewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.hasAPIKey {
                    // 消息列表
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    messageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages) { _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // 错误消息
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    
                    // 输入区域
                    HStack {
                        TextField("Type a message...", text: $viewModel.inputText)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 1))
                            .disabled(viewModel.isLoading)
                        
                        Button(action: {
                            print("Send button tapped")
                            print("Input text: \(viewModel.inputText)")
                            viewModel.sendMessage()
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .cornerRadius(22)
                            } else {
                                Image(systemName: "paperplane")
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(viewModel.inputText.isEmpty ? Color(red: 0.7, green: 0.7, blue: 0.7) : Color.blue)
                                    .cornerRadius(22)
                            }
                        }
                        .disabled(viewModel.isLoading || viewModel.inputText.isEmpty)
                    }
                    .padding()
                } else {
                    Text("Loading...")
                }
            }
            .navigationTitle("Sextary")
            .navigationBarItems(trailing: Button(action: { showSettingsView = true }) {
                Image(systemName: "gear")
            })
        }
        .sheet(isPresented: $showAPIKeyView) {
            EnterAPIKeyView { 
                showAPIKeyView = false
                viewModel.checkAPIKeyStatus()
            }
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .onAppear {
            viewModel.checkAPIKeyStatus()
            if !viewModel.hasAPIKey {
                showAPIKeyView = true
            }
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
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                MarkdownText(content: message.content)
                    .padding()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
    }
}

#Preview {
    ChatView()
}
