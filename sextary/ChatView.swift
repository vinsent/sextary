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
    @GestureState private var isDragging: Bool = false
    @State private var dragOffset: CGSize = .zero
    @StateObject private var viewModel: ChatViewModel = ChatViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    if viewModel.hasAPIKey {
                        // Message list
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
                            .onChange(of: viewModel.messages) { _, _ in
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        
                        // Error message
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        }
                        
                        // Input area
                        HStack {
                            TextField("Type a message...", text: $viewModel.inputText)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 1))
                                .disabled(viewModel.isLoading)
                            
                            if (viewModel.inputText.isEmpty || viewModel.isRecording) && !viewModel.isLoading {
                                // Voice input button
                                ZStack {
                                    Image(systemName: "mic")
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.blue)
                                        .cornerRadius(22)
                                }
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                        .onChanged { value in
                                            if !viewModel.isRecording {
                                                print("Long press started")
                                                viewModel.startRecording()
                                            } else {
                                                dragOffset = value.translation
                                                if dragOffset.height < -50 {
                                                    viewModel.recordingCancelled = true
                                                } else {
                                                    viewModel.recordingCancelled = false
                                                }
                                            }
                                        }
                                        .onEnded { value in
                                            print("Long press ended, dragOffset: \(dragOffset.height)")
                                            if dragOffset.height < -50 {
                                                viewModel.cancelRecording()
                                            } else {
                                                viewModel.stopRecording()
                                            }
                                            dragOffset = .zero
                                        }
                                )
                            } else {
                                // Send button
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
            
            // Recording background
            if viewModel.isRecording {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .allowsHitTesting(false)
                    
                    VStack {
                        // Recognized text display
                        if !viewModel.recognizedText.isEmpty {
                            Text(viewModel.recognizedText)
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                                .padding(.bottom, 20)
                        }
                        
                        // Recording animation
                        HStack(spacing: 8) {
                            ForEach(0..<5) {
                                BarView(value: viewModel.recordingLevel, index: $0)
                            }
                        }
                        .frame(height: 100)
                        
                        // Recording prompt text
                        Text(viewModel.recordingCancelled ? "Release to cancel" : "Release to send, move up to cancel")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.top, 20)
                    }
                }
                .allowsHitTesting(false)
            }
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



// Recording waveform animation component
struct BarView: View {
    let value: Float
    let index: Int
    
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 10, height: CGFloat(value * 80) + 10)
            .animation(.easeInOut(duration: 0.1), value: value)
            .cornerRadius(5)
    }
}

#Preview {
    ChatView()
}
